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
          identity: OneSignal.Identity,
          subscriptions: list(OneSignal.Subscription) | nil
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

  @spec create(t, OneSignal.options()) ::
          {:ok, t} | {:error, OneSignal.Error.t()}
        when t:
               %{
                 optional(:identity) => OneSignal.Identity,
                 optional(:subscriptions) => list(OneSignal.Subscription)
               }
               | %{}
  def create(params, opts \\ []) do
    new_request(opts)
    |> put_endpoint("/users")
    |> put_method(:post)
    |> put_params(params)
    |> make_request()
  end

  @spec create_alias_by_subscription(String.t(), t, OneSignal.options()) ::
          {:ok, t} | {:error, OneSignal.Error.t()}
  def create_alias_by_subscription(subsctiption_id, params, opts \\ []) do
    new_request(opts)
    |> put_endpoint("/subscriptions/#{subsctiption_id}/user/identity")
    |> put_method(:patch)
    |> put_params(params)
    |> make_request()
  end
end
