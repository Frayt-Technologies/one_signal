defmodule OneSignal.Notification do
  use OneSignal.Entity
  import OneSignal.Request

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
          data: map() | nil,
          template_id: String.t() | nil,
          name: String.t() | nil,
          contents: %{
            en: String.t()
          },
          headings: %{
            en: String.t()
          },
          url: String.t() | nil,
          email_to: list(String.t()) | nil,
          email_subject: String.t() | nil,
          email_body: String.t() | nil,
          email_preheader: String.t() | nil,
          email_from_name: String.t() | nil,
          email_from_address: String.t() | nil,
          email_sender_domain: String.t() | nil,
          email_reply_to_address: String.t() | nil,
          include_unsubscribed: boolean() | nil,
          disable_email_click_tracking: boolean() | nil
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
    :data,
    :template_id,
    :name,
    :contents,
    :headings,
    :url,
    :email_to,
    :email_subject,
    :email_body,
    :email_preheader,
    :email_from_name,
    :email_from_address,
    :email_sender_domain,
    :email_reply_to_address,
    :include_unsubscribed,
    :disable_email_click_tracking
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
      data: params[:data],
      template_id: params[:template_id],
      name: params[:name],
      contents: params[:contents],
      headings: params[:headings],
      url: params[:url],
      email_to: params[:email_to],
      email_subject: params[:email_subject],
      email_body: params[:email_body],
      email_preheader: params[:email_preheader],
      email_from_name: params[:email_from_name],
      email_from_address: params[:email_from_address],
      email_sender_domain: params[:email_sender_domain],
      email_reply_to_address: params[:email_reply_to_address],
      include_unsubscribed: params[:include_unsubscribed],
      disable_email_click_tracking: params[:disable_email_click_tracking]
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
end
