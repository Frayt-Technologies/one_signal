defmodule OneSignal.Error do
  defexception [:source, :code, :message, :extra, :request_id, :reason, :title, :meta]

  @type error_source :: :internal | :network | :onesignal

  @type error_status ::
          :bad_request
          | :unauthorized
          | :request_failed
          | :not_found
          | :conflict
          | :too_many_requests
          | :server_error
          | :unknown_error

  @type t :: %__MODULE__{
          code: error_status | :network_error,
          source: error_source,
          reason: String.t() | nil,
          code: String.t(),
          title: String.t() | nil,
          meta: String.t() | nil
        }

  @doc false
  @spec new(Keyword.t()) :: t
  def new(fields) do
    struct!(__MODULE__, fields)
  end

  @doc false
  @spec from_hackney_error(any) :: t
  def from_hackney_error(reason) do
    %__MODULE__{
      source: :network,
      code: :network_error,
      message:
        "An error occurred while making the network request. The HTTP client returned the following reason: #{inspect(reason)}",
      extra: %{
        hackney_reason: reason
      }
    }
  end

  @doc false
  @spec from_onesignal_error(400..599, nil, String.t() | nil) :: t
  def from_onesignal_error(status, nil, request_id) do
    %__MODULE__{
      source: :onesignal,
      code: code_from_status(status),
      request_id: request_id,
      extra: %{http_status: status},
      message: status |> message_from_status()
    }
  end

  @spec from_onesignal_error(400..599, map, String.t()) :: t
  def from_onesignal_error(status, error_data, request_id) when is_binary(error_data) do
    %__MODULE__{
      source: :onesignal,
      code: code_from_status(status),
      request_id: request_id,
      message: error_data
    }
  end

  def from_onesignal_error(status, error_data, request_id) do
    IO.inspect(status, label: "*** status")
    IO.inspect(error_data, label: "*** error_data")
    IO.inspect(request_id, label: "*** request_id")

    case error_data |> Map.get("type") |> maybe_to_atom() do
      nil ->
        from_onesignal_error(status, nil, request_id)

      type ->
        message = Map.get(error_data, "message") || "An unknown error occurred."

        %__MODULE__{
          source: :onesignal,
          code: type,
          request_id: request_id,
          message: message
        }
    end
  end

  defp code_from_status(400), do: :bad_request
  defp code_from_status(401), do: :unauthorized
  defp code_from_status(402), do: :request_failed
  defp code_from_status(404), do: :not_found
  defp code_from_status(409), do: :conflict
  defp code_from_status(429), do: :too_many_requests
  defp code_from_status(s) when s in [500, 502, 503, 504], do: :server_error
  defp code_from_status(_), do: :unknown_error

  defp message_from_status(400),
    do: "The request was unacceptable, often due to missing a required parameter."

  defp message_from_status(401), do: "No valid API key provided."
  defp message_from_status(402), do: "The parameters were valid but the request failed."
  defp message_from_status(404), do: "The requested resource doesn't exist."

  defp message_from_status(409),
    do:
      "The request conflicts with another request (perhaps due to using the same idempotent key)."

  defp message_from_status(429),
    do:
      "Too many requests hit the API too quickly. We recommend an exponential backoff of your requests."

  defp message_from_status(s) when s in [500, 502, 503, 504],
    do: "Something went wrong on OneSignal's end."

  defp message_from_status(s), do: "An unknown HTTP code of #{s} was received."

  def exception(reason),
    do: %__MODULE__{reason: reason}

  def message(%__MODULE__{reason: reason}),
    do: format_error(reason)

  defp format_error({:httpoison, value}),
    do: "HTTPoison error: #{inspect(value)}"

  defp format_error({:invalid, value}), do: "Invalid body in request: #{inspect(value)}"

  defp format_error(%{reason: value}),
    do: "Invalid request: #{inspect(value)}"

  defp format_error({:unknown, value}), do: value

  defp format_error({:not_implemented, value}), do: value

  defp maybe_to_atom(nil), do: nil
  defp maybe_to_atom(string) when is_binary(string), do: string |> String.to_atom()
end
