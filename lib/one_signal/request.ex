defmodule OneSignal.Request do
  @moduledoc """
  A module for working with requests to the OneSignal API.

  Requests are composed in a functional manner. The request does not happen
  until it is configured and passed to `make_request/1`.

  Currently encompasses only requests to the normal OneSignal API. The OAuth
  endpoint is not yet supported.

  Generally intended to be used internally, but can also be used by end-users
  to work around missing endpoints (if any).

  At a minimum, a request must have the endpoint and method specified to be
  valid.
  """
  alias OneSignal.{API, Converter, Request, Utils}

  @type t :: %__MODULE__{
          cast_to_id: MapSet.t() | nil,
          endpoint: String.t() | nil,
          headers: map | nil,
          method: OneSignal.API.method() | nil,
          opts: Keyword.t() | nil,
          params: map
        }

  defstruct opts: [],
            endpoint: nil,
            headers: nil,
            method: nil,
            params: %{},
            cast_to_id: MapSet.new()

  @doc """
  Creates a new request.

  Optionally accepts options for the request, such as using a specific API key.
  See `t:OneSignal.options` for details.
  """
  @spec new_request(OneSignal.options(), map) :: t
  def new_request(opts \\ [], headers \\ %{}) do
    %Request{opts: opts, headers: headers}
  end

  @doc """
  Specifies an endpoint for the request.

  The endpoint should not include the `v1` prefix or an initial slash, for
  example `put_endpoint(request, "charges")`.

  The endpoint can be a binary or a function which takes the parameters of the
  query and returns an endpoint. The function is not evaluated until just
  before the request is made so the actual parameters can be specified after
  the endpoint.
  """
  @spec put_endpoint(t, String.t()) :: t
  def put_endpoint(%Request{} = request, endpoint) do
    %{request | endpoint: endpoint}
  end

  @doc """
  Specifies a method to use for the request.

  Accepts any of the standard HTTP methods as atoms, that is `:get`, `:post`,
  `:put`, `:patch` or `:delete`.
  """
  @spec put_method(t, OneSignal.API.method()) :: t
  def put_method(%Request{} = request, method)
      when method in [:get, :post, :put, :patch, :delete] do
    %{request | method: method}
  end

  @spec put_app_id(t) :: t
  def put_app_id(request) do
    app_id = Utils.config()[:app_id] || System.get_env("ONE_SIGNAL_APP_ID")
    put_param(request, :app_id, app_id)
  end

  @spec put_sms_from_number(t, map) :: t
  def put_sms_from_number(request, %{target_channel: "sms"}) do
    sms_from = Utils.config()[:sms_from] || System.get_env("ONE_SIGNAL_SMS_FROM_NUMBER")
    put_param(request, :sms_from, sms_from)
  end

  def put_sms_from_number(request, _params), do: request

  @doc """
  Specifies the parameters to be used for the request.

  If the request is a POST request, these are encoded in the request body.
  Otherwise, they are encoded in the URL.

  Calling this function multiple times will merge, not replace, the params
  currently specified.
  """
  @spec put_params(t, map) :: t
  def put_params(%Request{params: params} = request, new_params) do
    %{request | params: Map.merge(params, new_params)}
  end

  @doc """
  Specify a single param to be included in the request.
  """
  @spec put_param(t, atom, any) :: t
  def put_param(%Request{params: params} = request, key, value) do
    %{request | params: Map.put(params, key, value)}
  end

  @doc """
  Executes the request and returns the response.
  """
  @spec make_request(t) :: {:ok, struct} | {:error, OneSignal.Error.t()}
  def make_request(
        %Request{params: params, endpoint: endpoint, method: method, headers: headers, opts: opts} =
          request
      ) do
    with {:ok, params} <- do_cast_to_id(params, request.cast_to_id),
         {:ok, endpoint} <- consolidate_endpoint(endpoint, params),
         {:ok, result} <- API.request(params, method, endpoint, headers, opts) do
      {:ok, Converter.convert_result(result, endpoint)}
    end
  end

  defp do_cast_to_id(params, cast_to_id) do
    to_cast = MapSet.to_list(cast_to_id)

    params =
      Enum.reduce(to_cast, params, fn key, params ->
        case params[key] do
          %{__struct__: _, id: id} -> put_in(params[key], id)
          _ -> params
        end
      end)

    {:ok, params}
  end

  defp consolidate_endpoint(endpoint, _) when is_binary(endpoint), do: {:ok, endpoint}

  defp consolidate_endpoint(endpoint_fun, params) when is_function(endpoint_fun, 1) do
    case endpoint_fun.(params) do
      result when is_binary(result) ->
        {:ok, result}

      invalid ->
        {
          :error,
          OneSignal.Error.new(
            source: :internal,
            code: :endpoint_fun_invalid_result,
            message:
              "calling the endpoint function produced an invalid result of #{inspect(invalid)} "
          )
        }
    end
  end

  defp consolidate_endpoint(_, _) do
    {
      :error,
      OneSignal.Error.new(
        source: :internal,
        code: :invalid_endpoint,
        message: "endpoint must be a string or a function from params to a string"
      )
    }
  end

  @doc ~S"""
  Normalise the argument to a simple OneSignal ID.

  Actively extracts the ID, given a struct with an `:id` field, or returns the
  binary if one is passed in.

  Useful for eagerly getting the ID of an object passed in, for example when
  computing the endpoint to use:

  ```
  def retrieve(id, params, opts) do
    new_request(opts)
    |> put_endpoint(@plural_endpoint <> "/#{get_id!(id)}/users")
    ...
  ```
  """
  @spec get_id!(OneSignal.id() | struct) :: OneSignal.id()
  def get_id!(id) when is_binary(id), do: id

  def get_id!(%{id: id}) when is_binary(id), do: id

  def get_id!(_), do: raise("You must provide an ID or a struct with an ID to this operation.")
end
