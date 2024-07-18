defmodule OneSignal.User do
  use OneSignal.Entity
  import OneSignal.Request

  @plural_endpoint "/users/by"
  @type retrieve_by :: :onesignal_id | :external_id
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
  @spec retrieve(OneSignal.id() | t, retrieve_by, OneSignal.options()) ::
          {:ok, t} | {:error, OneSignal.Error.t()}
  def retrieve(id, retrieve_by, opts \\ []) do
    new_request(opts)
    |> put_endpoint(@plural_endpoint <> "/#{retrieve_by}" <> "/#{get_id!(id)}")
    |> put_method(:get)
    |> make_request()
  end
end
