defmodule OneSignal.Subscription do
  use OneSignal.Entity
  import OneSignal.Request

  defp plural_endpoint(id) do
    "/subscriptions" <> "/#{get_id!(id)}"
  end

  @type retrieve_by :: :onesignal_id | :external_id

  @type type ::
          :iOSPush
          | :AndroidPush
          | :FireOSPush
          | :ChromeExtensionPush
          | :ChromePush
          | :WindowsPush
          | :SafariLegacyPush
          | :FirefoxPush
          | :macOSPush
          | :HuaweiPush
          | :SafariPush
          | :Email
          | :SMS

  @type properties :: %{
          id: OneSignal.id(),
          app_id: OneSignal.id(),
          type: type,
          token: String.t() | nil,
          enabled: boolean,
          notification_types: integer | nil,
          session_time: integer | nil,
          session_count: integer | nil,
          app_version: String.t() | nil,
          device_model: String.t() | nil,
          device_os: String.t() | nil,
          test_type: integer | nil,
          sdk: String.t() | nil,
          rooted: boolean | nil,
          web_auth: String.t() | nil,
          web_p256: String.t() | nil,
          net_type: integer | nil,
          carrier: String.t() | nil
        }

  @type t :: %__MODULE__{
    identity: OneSignal.Identity,
    subscription: properties | nil
  }

  defstruct [
    :identity,
    :subscription,
    :properties
  ]

  @doc """
  Updates a Subscription object.
   See the [OneSignal docs](https://documentation.onesignal.com/reference/update-subscription).
  """
  @spec update(OneSignal.id() | t, params, OneSignal.options()) ::
          {:ok, t} | {:error, OneSignal.Error.t()}
        when params:
               %{
                 optional(:type) => type,
                 optional(:token) => String.t() | nil,
                 optional(:enabled) => boolean,
                 optional(:notification_types) => integer | nil,
                 optional(:session_time) => integer | nil,
                 optional(:session_count) => integer | nil,
                 optional(:app_version) => String.t() | nil,
                 optional(:device_model) => String.t() | nil,
                 optional(:device_os) => String.t() | nil,
                 optional(:test_type) => integer | nil,
                 optional(:sdk) => String.t() | nil,
                 optional(:rooted) => boolean | nil,
                 optional(:web_auth) => String.t() | nil,
                 optional(:web_p256) => String.t() | nil,
                 optional(:net_type) => integer | nil,
                 optional(:carrier) => String.t() | nil
               }
               | %{}
  def update(id, params, opts \\ []) do
    new_request(opts)
    |> put_endpoint(plural_endpoint(id))
    |> put_method(:patch)
    |> put_params(params)
    |> make_request()
  end

  @spec create(OneSignal.id() | t, retrieve_by, params, OneSignal.options()) ::
          {:ok, t} | {:error, OneSignal.Error.t()}
        when params:
               %{
                 optional(:type) => type,
                 optional(:token) => String.t() | nil,
                 optional(:enabled) => boolean,
                 optional(:notification_types) => integer | nil,
                 optional(:session_time) => integer | nil,
                 optional(:session_count) => integer | nil,
                 optional(:app_version) => String.t() | nil,
                 optional(:device_model) => String.t() | nil,
                 optional(:device_os) => String.t() | nil,
                 optional(:test_type) => integer | nil,
                 optional(:sdk) => String.t() | nil,
                 optional(:rooted) => boolean | nil,
                 optional(:web_auth) => String.t() | nil,
                 optional(:web_p256) => String.t() | nil,
                 optional(:net_type) => integer | nil,
                 optional(:carrier) => String.t() | nil
               }
               | %{}
  def create(id, retrieve_by, params, opts \\ []) do
    new_request(opts)
    |> put_endpoint("/users/by/#{retrieve_by}" <> "/#{get_id!(id)}" <> "/subscriptions")
    |> put_method(:post)
    |> put_params(params)
    |> make_request()
  end

  def delete(subscription_id, opts \\ []) do
    new_request(opts)
    |> put_endpoint("/subscriptions" <> "/#{subscription_id}")
    |> put_method(:delete)
    |> make_request()
  end
end
