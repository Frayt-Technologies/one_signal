defmodule OneSignal.Subscription do
  @type t :: %__MODULE__{
          id: OneSignal.id(),
          app_id: OneSignal.id(),
          type: String.t() | nil,
          token: String.t() | nil,
          enabled: boolean,
          notification_types: integer | nil,
          session_time: integer | nil,
          session_count: integer | nil,
          sdk: String.t() | nil,
          device_model: String.t() | nil,
          device_os: String.t() | nil,
          rooted: boolean | nil,
          test_type: integer | nil,
          app_version: String.t() | nil,
          net_type: integer | nil,
          carrier: String.t() | nil,
          web_auth: String.t() | nil,
          web_p256: String.t() | nil
        }

  defstruct [
    :id,
    :app_id,
    :type,
    :token,
    :enabled,
    :notification_types,
    :session_time,
    :session_count,
    :sdk,
    :device_model,
    :device_os,
    :rooted,
    :test_type,
    :app_version,
    :net_type,
    :carrier,
    :web_auth,
    :web_p256
  ]
end
