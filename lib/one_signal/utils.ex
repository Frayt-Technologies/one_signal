defmodule OneSignal.Utils do
  @doc """
  Encode request body
  """

  def format_url(url, query) do
    query =
      Enum.map_join(query, "&", fn x ->
        pair(x)
      end)

    url =
      unless String.length(query) == 0 do
        "#{url}?#{query}"
      end

    url
  end

  def config do
    Application.get_env(:one_signal, OneSignal)
  end

  defp pair({key, value}) do
    if Enumerable.impl_for(value) do
      pair(to_string(key), [], value)
    else
      param_name = key |> to_string |> URI.encode()
      param_value = value |> to_string |> URI.encode()

      "#{param_name}=#{param_value}"
    end
  end

  defp pair(root, parents, values) do
    Enum.map_join(values, "&", fn {key, value} ->
      if Enumerable.impl_for(value) do
        pair(root, parents ++ [key], value)
      else
        build_key(root, parents ++ [key]) <> to_string(value)
      end
    end)
  end

  defp build_key(root, parents) do
    path =
      Enum.map_join(parents, "", fn x ->
        param = x |> to_string |> URI.encode()
        "[#{param}]"
      end)

    "#{root}#{path}="
  end

  @spec object_name_to_module(String.t()) :: module
  def object_name_to_module("onesignal.user"), do: OneSignal.User
  def object_name_to_module("onesignal.subscription"), do: OneSignal.Subscription

  @spec module_to_string(module) :: String.t()
  def module_to_string(module) do
    module |> Atom.to_string() |> String.trim_leading("Elixir.")
  end

  @doc """
  Performs a root-level conversion of map keys from strings to atoms.

  This function performs the transformation safely using `String.to_existing_atom/1`, but this has a possibility to raise if
  there is not a corresponding atom.

  It is recommended that you pre-filter maps for known values before
  calling this function.

  ## Examples

  iex> map = %{
  ...>   "a"=> %{
  ...>     "b" => %{
  ...>       "c" => 1
  ...>     }
  ...>   }
  ...> }
  iex> OneSignal.Util.map_keys_to_atoms(map)
  %{
    a: %{
      "b" => %{
        "c" => 1
      }
    }
  }
  """
  def map_keys_to_atoms(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()  # Convert the struct to a map
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      atom_value = if is_map(value), do: map_keys_to_atoms(value), else: value
      Map.put(acc, key, atom_value)
    end)
  end

  def map_keys_to_atoms(map) when is_map(map) do
    map
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      atom_key = if is_binary(key), do: String.to_atom(key), else: key
      atom_value = if is_map(value), do: map_keys_to_atoms(value), else: value
      Map.put(acc, atom_key, atom_value)
    end)
  end

  def remove_nil_values(map) when is_map(map) do
    map
    |> Enum.reduce(%{}, fn
      {key, value}, acc when is_map(value) ->
        cleaned_value = remove_nil_values(value)
        if map_size(cleaned_value) > 0 do
          Map.put(acc, key, cleaned_value)
        else
          acc
        end

      {key, value}, acc when value != nil ->
        Map.put(acc, key, value)

      _, acc -> acc
    end)
  end
end
