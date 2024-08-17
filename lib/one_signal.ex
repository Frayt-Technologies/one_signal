defmodule OneSignal do
  use Application
  alias OneSignal.Utils

  @type id :: String.t()
  @type options :: Keyword.t()

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

  def auth_header(), do: auth_header(fetch_api_key())

  def auth_header(nil) do
    {:error, "Missing API key, please refer to the README on how to configure it."}
  end

  def auth_header(api_key) do
    {:ok, %{"Authorization" => "Basic " <> api_key, "Content-type" => "application/json"}}
  end

  defp fetch_api_key() do
    Utils.config()[:api_key] || System.get_env("ONE_SIGNAL_API_KEY")
  end

  def fetch_app_id() do
    Utils.config()[:app_id] || System.get_env("ONE_SIGNAL_APP_ID")
  end

  def fetch_from_number() do
    Utils.config()[:sms_from_number] || System.get_env("ONE_SIGNAL_SMS_FROM_NUMBER")
  end
end
