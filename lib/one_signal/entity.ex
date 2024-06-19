defmodule OneSignal.Entity do
  @moduledoc """
  A behaviour implemented by modules which represent OneSignal objects.

  Intended for internal use within the library.

  A OneSignal Entity is just a struct, optionally containing some logic for
  transforming a raw result from the OneSignal API into a final struct. This is
  achieved through the use of the `from_json/2` macro.

  The list of objects which are recognised by the library upon receipt are
  currently static and contained in `OneSignal.Converter`.

  When a map containing the `"object"` key is received from the API (even when
  nested inside another map), and the value of that field (for example,
  `"foo_widget"`) is in the list of supported objects, the converter will
  expect `OneSignal.FooWidget` to be present and to implement this behaviour.

  To implement this behaviour, simply add `use OneSignal.Entity` to the top of
  the entity module and make sure it defines a struct. This will also enable
  the use of the `from_json/2` macro, which allows for changes to the data
  received from OneSignal before it is converted to a struct.
  """

  @doc false
  # Not to be directly implemented, use the `from_json/2` macro instead
  @callback __from_json__(data :: map) :: map

  @doc false
  defmacro __using__(_opts) do
    quote do
      require OneSignal.Entity
      import OneSignal.Entity, only: [from_json: 2]
      @behaviour OneSignal.Entity
      def __from_json__(data), do: data
      defoverridable __from_json__: 1
    end
  end

  @doc """
  Specifies logic that transforms data from OneSignal to our OneSignal object.

  To this end, sometimes it is desirable to make changes to the raw data
  received from the OneSignal API, to aid its conversion into an appropriate
  Elixir data struct.

  This macro is used in modules implementing the `OneSignal.Entity` behaviour in
  order to specify this extra logic.

  Its use is optional, and the default is no transformation; i.e. the received
  JSON keys are merely converted to atoms and cast to the struct defined by
  the module.

  The macro is used like this:

  ```
  from_json data do
    data
    |> cast_to_atom([:type, :status])
    |> cast_each(:fee_details, &cast_to_atom(&1, :type))
  end
  ```

  It takes a parameter name to which the data received from OneSignal is bound,
  and a `do` block which should return the transformed data. The
  transformation receives the JSON response from OneSignal, with all keys
  converted to atoms (apart from keys inside a metadata map, which remain
  binaries) and should return a map which is ready to be cast to the struct
  the module defines.

  The helper `cast_*` functions defined in this module are automatically
  imported into the scope of this macro.

  The helper functions are all `nil`/missing key-safe, meaning that they will
  not magically add fields or error on fields which are missing or unset. You
  should therefore write your transformation assuming all possible data is
  actually present.
  """
  defmacro from_json(param, do: block) do
    quote do
      def __from_json__(unquote(param)) do
        import OneSignal.Entity, except: [from_json: 2]
        unquote(block)
      end
    end
  end

  @doc """
  Cast the value of the given key or keys to an atom.

  Provide either a single atom key or a list of atom keys whose values should
  be converted from binaries to atoms. Used commonly to convert `"enum"` values
  (values which belong to a predefined set) in OneSignal responses, for example a
  `:status` field.

  If a key is not set or the value is `nil`, no transformation occurs.
  """
  @spec cast_to_atom(map, atom | [atom]) :: map
  def cast_to_atom(%{} = data, keys) when is_list(keys) do
    Enum.reduce(keys, data, fn key, data -> cast_to_atom(data, key) end)
  end

  def cast_to_atom(%{} = data, key) do
    key = List.wrap(key)
    maybe_update_in(data, key, maybe(&String.to_atom/1))
  end

  @doc """
  Applies the given function over a list present in the data.

  Provide either a single atom key or a list of atom keys whose values are
  lists. Each element of such a list will be mapped using the function passed.

  For example, if there is a field `:fee_details` which is a list of maps,
  each containing a `:type` key whose value we want to cast to an atom, then
  we write:

  ```
  data
  |> cast_each(:fee_details, &cast_to_atom(&1, :type))
  ```

  If a key is not set or the value is `nil`, no transformation occurs.
  """
  @spec cast_each(map, atom | [atom], (any -> any)) :: map
  def cast_each(%{} = data, keys, fun) when is_list(keys) and is_function(fun) do
    Enum.reduce(keys, data, fn key, data -> cast_each(data, key, fun) end)
  end

  def cast_each(%{} = data, key, fun) when is_function(fun) do
    key = List.wrap(key)
    maybe_update_in(data, key, maybe(&Enum.map(&1, fun)))
  end

  defp maybe(fun) do
    fn
      nil -> nil
      arg -> fun.(arg)
    end
  end

  defp maybe_update_in(data, path, fun) do
    case get_in(data, path) do
      nil -> data
      val -> put_in(data, path, fun.(val))
    end
  end
end
