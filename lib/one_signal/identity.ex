defmodule OneSignal.Identity do
  use OneSignal.Entity

  @type t :: %__MODULE__{
          onesignal_id: OneSignal.id(),
          external_id: String.t() | nil
        }

  defstruct [
    :onesignal_id,
    :external_id
  ]
end
