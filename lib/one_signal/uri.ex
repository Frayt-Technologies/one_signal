defmodule OneSignal.URI do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      defp build_url(ext \\ "") do
        if ext != "", do: ext = "/" <> ext

        @base <> ext
      end
    end
  end

  @doc """
  Takes a map and turns it into proper query values.
  """
  @spec encode_query(map) :: String.t()
  def encode_query(map) do
    map |> UriQuery.params() |> URI.encode_query()
  end
end
