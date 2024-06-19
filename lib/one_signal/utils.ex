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

  def map_keys_to_atoms(m) do
    Enum.into(m, %{}, fn
      {k, v} when is_binary(k) ->
        a = String.to_atom(k)
        {a, v}

      entry ->
        entry
    end)
  end
end
