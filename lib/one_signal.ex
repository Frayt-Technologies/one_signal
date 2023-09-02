defmodule OneSignal do
  use Application
  alias OneSignal.Utils

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = []

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OneSignal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def endpoint, do: "https://onesignal.com/api/v1"

  def new do
    %OneSignal.Param{}
  end

  def auth_header(:legacy), do: auth_header(fetch_api_key(:legacy))

  def auth_header(:current), do: auth_header(fetch_api_key(:current))

  def auth_header(nil) do
    {:error, "Missing API key, please refer to the README on how to configure it."}
  end

  def auth_header(api_key) do
    {:ok, %{"Authorization" => "Basic " <> api_key, "Content-type" => "application/json"}}
  end

  defp fetch_api_key(:legacy) do
    Utils.config()[:legacy_api_key] || Application.get_env("ONE_SIGNAL_LEGACY_API_KEY")
  end

  defp fetch_api_key(:current) do
    Utils.config()[:api_key] || Application.get_env("ONE_SIGNAL_API_KEY")
  end

  def fetch_app_id(:legacy) do
    Utils.config()[:legacy_app_id] || Application.get_env("ONE_SIGNAL_LEGACY_APP_ID")
  end

  def fetch_app_id(:current) do
    Utils.config()[:app_id] || Application.get_env("ONE_SIGNAL_APP_ID")
  end

  def fetch_from_number() do
    Utils.config()[:sms_from_number] || Application.get_env("ONE_SIGNAL_SMS_FROM_NUMBER")
  end
end
