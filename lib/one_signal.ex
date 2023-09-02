defmodule OneSignal do
  use Application
  alias OneSignal.Utils

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    System.get_all_env() |> IO.inspect(label: "ALL_ENV")

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
    Utils.config()[:legacy_api_key] || Application.get_env(:one_signal, :legacy_api_key)
  end

  defp fetch_api_key(:current) do
    Utils.config()[:api_key] || Application.get_env(:one_signal, :api_key)
  end

  def fetch_app_id(:legacy) do
    Utils.config()[:legacy_app_id] || Application.get_env(:one_signal, :legacy_app_id)
  end

  def fetch_app_id(:current) do
    Utils.config()[:app_id] || Application.get_env(:one_signal, :app_id)
  end

  def fetch_from_number() do
    Utils.config()[:sms_from_number] || Application.get_env(:one_signal, :sms_from_number)
  end
end
