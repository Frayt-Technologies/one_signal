defmodule OneSignal.Converter do
  @doc """
  Takes a result map or list of maps from a OneSignal response and returns a
  struct (e.g. `%OneSignal.Card{}`) or list of structs.

  If the result is not a supported OneSignal object, it just returns a plain map
  with atomized keys.
  """

  @spec convert_result(%{String.t() => any}, String.t()) :: struct
  def convert_result(result, endpoint), do: convert_value(result, endpoint)

  @supported_objects ~w(
    onesignal.user
    onesignal.subscription
    onesignal.identity
  )

  @doc """
  Returns a list of structs to be used for providing JSON-encoders.

  ## Examples

  Say you are using Jason to encode your JSON, you can provide the following protocol,
  to directly encode all structs of this library into JSON.

  ```
  for struct <- OneSignal.Converter.structs() do
    defimpl Jason.Encoder, for: struct do
      def encode(value, opts) do
        Jason.Encode.map(Map.delete(value, :__struct__), opts)
      end
    end
  end
  ```
  """
  def structs() do
    @supported_objects
    |> Enum.map(&OneSignal.Utils.object_name_to_module/1)
  end

  @spec convert_value(any, String) :: any
  defp convert_value(%{"object" => object_name} = value, _endpoint) when is_binary(object_name) do
    case Enum.member?(@supported_objects, object_name) do
      true ->
        convert_onesignal_object(object_name, value)

      false ->
        warn_unknown_object(value)
        convert_map(value)
    end
  end

  defp convert_value(_, "/subscriptions" <> _) do
    %{}
  end

  defp convert_value(value, "/users/by" <> _) do
    convert_onesignal_object("onesignal.user", value)
  end

  defp convert_value(value, "/users" <> _) do
    convert_onesignal_object("onesignal.user", value)
  end

  defp convert_value(value) when is_map(value), do: convert_map(value)
  defp convert_value(value) when is_list(value), do: convert_list(value)
  defp convert_value(value), do: value

  @spec convert_map(map) :: map
  defp convert_map(value) do
    Enum.reduce(value, %{}, fn {key, value}, acc ->
      Map.put(acc, String.to_atom(key), convert_value(value))
    end)
  end

  @spec convert_onesignal_object(String.t(), %{String.t() => any}) :: struct
  defp convert_onesignal_object(object_name, value) do
    module = OneSignal.Utils.object_name_to_module(object_name)
    struct_keys = Map.keys(module.__struct__) |> List.delete(:__struct__)
    check_for_extra_keys(struct_keys, value)

    processed_map =
      struct_keys
      |> Enum.reduce(%{}, fn key, acc ->
        string_key = to_string(key)

        converted_value = Map.get(value, string_key) |> convert_value()

        Map.put(acc, key, converted_value)
      end)
      |> module.__from_json__()

    struct(module, processed_map)
  end

  @spec convert_list(list) :: list
  defp convert_list(list), do: list |> Enum.map(&convert_value/1)

  if Mix.env() == :prod do
    defp warn_unknown_object(_), do: :ok
  else
    defp warn_unknown_object(%{"object" => object_name}) do
      require Logger

      Logger.warn("Unknown object received: #{object_name}")
    end
  end

  if Mix.env() == :prod do
    defp check_for_extra_keys(_, _), do: :ok
  else
    defp check_for_extra_keys(struct_keys, map) do
      require Logger

      map_keys =
        map
        |> Map.keys()
        |> Enum.map(&String.to_atom/1)
        |> MapSet.new()

      struct_keys =
        struct_keys
        |> MapSet.new()

      extra_keys =
        map_keys
        |> MapSet.difference(struct_keys)
        |> Enum.to_list()

      unless Enum.empty?(extra_keys) do
        object = Map.get(map, "object")

        module_name =
          object
          |> OneSignal.Utils.object_name_to_module()
          |> OneSignal.Utils.module_to_string()

        details = "#{module_name}: #{inspect(extra_keys)}"
        message = "Extra keys were received but ignored when converting #{details}"
        Logger.warn(message)
      end

      :ok
    end
  end
end
