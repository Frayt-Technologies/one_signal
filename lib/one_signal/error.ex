defmodule OneSignal.Error do
  defexception [:source, :code, :title, :meta]

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
          source: error_source,
          code: error_status | :network_error,
          title: String.t(),
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
      title:
        "An error occurred while making the network request. The HTTP client returned the following reason: #{inspect(reason)}",
      meta: %{
        hackney_reason: reason
      }
    }
  end

  @doc false
  @spec from_onesignal_error(400..599, nil) :: t
  def from_onesignal_error(status, nil) do
    %__MODULE__{
      source: :onesignal,
      code: code_from_status(status),
      title: status |> message_from_status(),
      meta: %{http_status: status}
    }
  end

  @spec from_onesignal_error(400..599, map) :: t
  def from_onesignal_error(status, error_data) when is_binary(error_data) do
    %__MODULE__{
      source: :onesignal,
      code: code_from_status(status),
      title: error_data,
      meta: %{}
    }
  end

  @spec from_onesignal_error(400..599, list()) :: t
  def from_onesignal_error(status, error_data) when is_list(error_data) do
    %__MODULE__{
      source: :onesignal,
      code: code_from_status(status),
      title: error_data,
      meta: %{}
    }
  end

  def from_onesignal_error(status, error_data) do
    case error_data |> Map.get("type") |> maybe_to_atom() do
      nil ->
        from_onesignal_error(status, nil)

      type ->
        message = Map.get(error_data, "message") || "An unknown error occurred."

        %__MODULE__{
          source: :onesignal,
          code: type,
          title: message,
          meta: %{}
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
  defp message_from_status(405), do: "Method Not Allowed."

  defp message_from_status(409),
    do:
      "The request conflicts with another request (perhaps due to using the same idempotent key)."

  defp message_from_status(429),
    do:
      "Too many requests hit the API too quickly. We recommend an exponential backoff of your requests."

  defp message_from_status(s) when s in [500, 502, 503, 504],
    do: "Something went wrong on OneSignal's end."

  defp message_from_status(s), do: "An unknown HTTP code of #{s} was received."

  def exception(reason), do: %__MODULE__{title: reason}

  def message(%__MODULE__{title: title}), do: "Invalid request: #{title}"

  defp maybe_to_atom(nil), do: nil
  defp maybe_to_atom(string) when is_binary(string), do: string |> String.to_atom()
end
