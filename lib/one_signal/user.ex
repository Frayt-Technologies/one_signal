defmodule OneSignal.User do
  import OneSignal.Request

  @plural_endpoint "/users/by/onesignal_id"

  @type tags :: %{
          key: String.t()
        }

  @type t :: %__MODULE__{
          properties: %{
            tags: list(tags) | nil,
            country: String.t() | nil,
            first_active: OneSignal.timestamp() | nil,
            last_active: OneSignal.timestamp() | nil
          },
          identity: %{
            onesignal_id: OneSignal.id(),
            external_id: String.t() | nil
          },
          subscriptions: list(OneSignal.Subscription)
        }

  defstruct [
    :identity,
    :subscriptions,
    :properties
  ]

  @doc """
  Retrieve a user.
  """
  @spec retrieve(OneSignal.id() | t, OneSignal.options()) ::
          {:ok, t} | {:error, OneSignal.Error.t()}
  def retrieve(id, opts \\ []) do
    new_request(opts)
    |> put_endpoint(@plural_endpoint <> "/#{get_id!(id)}")
    |> put_method(:get)
    |> make_request()
  end
end
