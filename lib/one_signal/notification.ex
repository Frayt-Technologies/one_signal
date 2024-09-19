defmodule OneSignal.Notification do
  use OneSignal.Entity
  import OneSignal.Request
  alias OneSignal.Utils

  @plural_endpoint "/notifications"

  @type target_channel :: :email | :sms | :push

  @type response :: %{
          external_id: String.t() | nil,
          id: String.t() | nil,
          errors: list(map()) | nil
        }

  @type t :: %__MODULE__{
          included_segments: list(String.t()) | nil,
          excluded_segments: list(String.t()) | nil,
          include_email_tokens: list(String.t()) | nil,
          include_phone_numbers: list(String.t()) | nil,
          # filters: list(OneSignal.Filter) | nil,
          include_aliases:
            %{
              external_id: list(String.t()) | nil,
              onesignal_id: list(String.t()) | nil,
              some_custom_alias: list(String.t()) | nil
            }
            | nil,
          include_subscription_ids: list(String.t()) | nil,
          target_channel: target_channel,
          custom_data: map() | nil,
          template_id: String.t() | nil,
          name: String.t() | nil,
          contents: %{
            en: String.t()
          },
          headings: %{
            en: String.t()
          },
          url: String.t() | nil
        }

  @enforce_keys [:include_aliases, :target_channel, :contents]
  defstruct [
    :included_segments,
    :excluded_segments,
    :include_email_tokens,
    :include_phone_numbers,
    # :filters,
    :include_aliases,
    :include_subscription_ids,
    :target_channel,
    :custom_data,
    :template_id,
    :name,
    :contents,
    :headings,
    :url
  ]

  def new(params) do
    %__MODULE__{
      included_segments: params[:included_segments],
      excluded_segments: params[:excluded_segments],
      include_email_tokens: params[:include_email_tokens],
      include_phone_numbers: params[:include_phone_numbers],
      include_aliases: params[:include_aliases],
      include_subscription_ids: params[:include_subscription_ids],
      target_channel: params[:target_channel],
      custom_data: params[:custom_data],
      template_id: params[:template_id],
      name: params[:name],
      contents: params[:contents],
      headings: params[:headings],
      url: params[:url]
    }
  end

  @spec create(t, OneSignal.options()) :: {:ok, response} | {:error, OneSignal.Error.t()}
  def create(params, opt \\ []) do
    new_request(opt)
    |> put_endpoint(@plural_endpoint)
    |> put_method(:post)
    |> put_sms_from_number(params)
    |> put_params(params)
    |> put_app_id()
    |> make_request()
  end

  defp put_sms_from_number(request, %{target_channel: "sms"}) do
    put_param(request, "sms_from", fetch_from_number())
  end

  defp put_sms_from_number(request, _params), do: request

  defp put_app_id(request) do
    app_id = Utils.config()[:app_id] || System.get_env("ONE_SIGNAL_APP_ID")
    put_param(request, :app_id, app_id)
  end

  def fetch_from_number() do
    Utils.config()[:sms_from] || System.get_env("ONE_SIGNAL_SMS_FROM_NUMBER")
  end
end
