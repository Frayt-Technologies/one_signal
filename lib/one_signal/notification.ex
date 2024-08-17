defmodule OneSignal.Notification do
  use OneSignal.Entity
  import OneSignal.Request

  @plural_endpoint "/notifications"

  @type target_channel :: :email | :sms | :push

  @type t :: %__MODULE__{
          included_segments: list(string) | nil,
          excluded_segments: list(string) | nil,
          include_email_tokens: list(string) | nil,
          include_phone_numbers: list(string) | nil,
          # filters: list(OneSignal.Filter) | nil,
          include_aliases:
            %{
              external_id: list(string) | nil,
              onesignal_id: list(string) | nil,
              some_custom_alias: list(string) | nil
            }
            | nil,
          include_subscription_ids: list(string) | nil,
          target_channel: target_channel,
          custom_data: map() | nil,
          template_id: String.t() | nil,
          contents: %{
            en: String.t()
          },
          headings: %{
            en: String.t()
          },
          url: String.t() | nil
        }

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
    :contents,
    :headings,
    :url
  ]

  @spec create(t, OneSignal.options()) :: {:ok, nil} | {:error, OneSignal.Error.t()}
  def create(params, opt \\ []) do
    new_request(opt)
    |> put_endpoint(@plural_endpoint)
    |> put_method(:post)
    |> put_params(params)
    |> make_request()
  end
end
