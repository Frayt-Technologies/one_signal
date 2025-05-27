defmodule OneSignal.API do
  alias OneSignal.{Error, Config, Utils}

  @idempotency_key_header "Idempotency-Key"
  @type method :: :get | :post | :put | :delete | :patch
  @type body :: iodata() | {:multipart, list()}
  @type headers :: %{String.t() => String.t()} | %{}
  @typep http_success :: {:ok, integer, [{String.t(), String.t()}], String.t()}
  @typep http_failure :: {:error, term}

  @pool_name __MODULE__
  @default_max_attempts 3
  @default_base_backoff 500
  @default_max_backoff 2_000

  @doc """
  A low level utility function to make a direct request to the OneSignal API
  """
  @spec request(body, method, String.t(), headers, list) ::
          {:ok, map} | {:error, OneSignal.Error.t()}
  def request(body, :get, endpoint, headers, opts) do
    req_url =
      body
      |> OneSignal.Utils.map_keys_to_atoms()
      |> OneSignal.Utils.remove_nil_values()
      |> OneSignal.URI.encode_query()
      |> prepend_url("#{get_base_url()}/apps/#{get_app_id()}#{endpoint}")

    perform_request(req_url, :get, "", headers, opts)
  end

  def request(body, method, endpoint, headers, opts) do
    {idempotency_key, opts} = Keyword.pop(opts, :idempotency_key)

    req_url =
      if Map.has_key?(body, :app_id) do
        "#{get_base_url()}#{endpoint}"
      else
        "#{get_base_url()}/apps/#{get_app_id()}#{endpoint}"
      end

    headers = add_idempotency_header(idempotency_key, headers, method)

    req_body =
      body
      |> OneSignal.Utils.map_keys_to_atoms()
      |> OneSignal.Utils.remove_nil_values()
      |> Jason.encode!()

    perform_request(req_url, method, req_body, headers, opts)
  end

  @spec get_base_url() :: String.t()
  defp get_base_url() do
    Utils.config()[:api_base_url] || System.get_env("ONE_SIGNAL_API_BASE_URL")
  end

  @spec get_app_id() :: String.t()
  defp get_app_id() do
    Utils.config()[:app_id] || System.get_env("ONE_SIGNAL_APP_ID")
  end

  defp prepend_url("", url), do: url
  defp prepend_url(query, url), do: "#{url}?#{query}"

  defp add_idempotency_header(nil, headers, _), do: headers

  defp add_idempotency_header(idempotency_key, headers, :post) do
    Map.put(headers, "idempotency-key", idempotency_key)
  end

  @doc """
  A low level utility function to generate a new idempotency key for
  `#{@idempotency_key_header}` request header value.
  """
  @spec generate_idempotency_key() :: binary
  def generate_idempotency_key do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      System.unique_integer([:positive])::32
    >>

    Base.hex_encode32(binary, case: :lower, padding: false)
  end

  @spec perform_request(String.t(), method, body, headers, list) ::
          {:ok, map} | {:error, OneSignal.Error.t()}
  defp perform_request(req_url, method, body, headers, opts) do
    {api_key, opts} = Keyword.pop(opts, :api_key)

    req_headers =
      headers
      |> add_default_headers()
      |> add_auth_header(api_key)
      |> Map.to_list()

    req_opts =
      opts
      |> add_default_options()
      |> add_pool_option()
      |> add_options_from_config()

    do_perform_request(method, req_url, req_headers, body, req_opts)
  end

  @spec add_default_headers(headers) :: headers
  defp add_default_headers(existing_headers) do
    existing_headers = add_common_headers(existing_headers)

    case Map.has_key?(existing_headers, "content-type") do
      false -> existing_headers |> Map.put("content-type", "application/json")
      true -> existing_headers
    end
  end

  @spec add_common_headers(headers) :: headers
  defp add_common_headers(existing_headers) do
    Map.merge(existing_headers, %{
      "accept" => "application/json; charset=utf8",
      "accept-encoding" => "gzip",
      "connection" => "keep-alive"
    })
  end

  @spec add_auth_header(headers, String.t() | nil) :: headers
  defp add_auth_header(existing_headers, api_key) do
    api_key = fetch_api_key(api_key)
    Map.put(existing_headers, "Authorization", "Key #{api_key}")
  end

  @spec fetch_api_key(String.t() | nil) :: String.t()
  defp fetch_api_key(api_key) do
    case api_key do
      key when is_binary(key) -> key
      _ -> get_default_api_key()
    end
  end

  @spec get_default_api_key() :: String.t()
  defp get_default_api_key() do
    Utils.config()[:api_key] || System.get_env("ONE_SIGNAL_API_KEY")
  end

  @spec add_default_options(list) :: list
  defp add_default_options(opts) do
    [:with_body | opts]
  end

  @spec add_pool_option(list) :: list
  defp add_pool_option(opts) do
    if use_pool?() do
      [{:pool, @pool_name} | opts]
    else
      opts
    end
  end

  @spec use_pool?() :: boolean
  defp use_pool?() do
    Config.resolve(:use_connection_pool)
  end

  @spec add_options_from_config(list) :: list
  defp add_options_from_config(opts) do
    if is_list(OneSignal.Config.resolve(:hackney_opts)) do
      opts ++ OneSignal.Config.resolve(:hackney_opts)
    else
      opts
    end
  end

  @spec do_perform_request(method, String.t(), [headers], body, list) ::
          {:ok, map} | {:error, OneSignal.Error.t()}
  defp do_perform_request(method, url, headers, body, opts) do
    do_perform_request_and_retry(method, url, headers, body, opts, {:attempts, 0})
  end

  @spec do_perform_request_and_retry(
          method,
          String.t(),
          [headers],
          body,
          list,
          {:attempts, non_neg_integer} | {:response, http_success | http_failure}
        ) :: {:ok, map} | {:error, OneSignal.Error.t()}
  defp do_perform_request_and_retry(_method, _url, _headers, _body, _opts, {:response, response}) do
    handle_response(response)
  end

  defp do_perform_request_and_retry(method, url, headers, body, opts, {:attempts, attempts}) do
    response = http_module().request(method, url, headers, body, opts)

    do_perform_request_and_retry(
      method,
      url,
      headers,
      body,
      opts,
      add_attempts(response, attempts, retry_config())
    )
  end

  @spec handle_response(http_success | http_failure) :: {:ok, map} | {:error, OneSignal.Error.t()}
  defp handle_response({:ok, status, headers, body}) when status >= 200 and status <= 299 do
    decoded_body =
      body
      |> decompress_body(headers)
      |> json_library().decode!()
      |> case do
        %{"errors" => api_error} ->
          Error.from_onesignal_error(status, api_error)

        decoded_body ->
          decoded_body
      end

    {:ok, decoded_body}
  end

  defp handle_response({:ok, status, headers, body}) when status >= 300 and status <= 599 do
    body =
      decompress_body(body, headers)
      |> String.trim()
      |> String.replace("\\n", "")

    error =
      case Jason.decode(body) do
        {:ok, %{"errors" => api_error}} ->
          Error.from_onesignal_error(status, api_error)

        {:ok, %{"error" => api_error}} ->
          Error.from_onesignal_error(status, api_error)

        {:error, _} ->
          Error.from_onesignal_error(status, nil)
      end

    {:error, error}
  end

  defp handle_response({:error, reason}) do
    error = Error.from_hackney_error(reason)
    {:error, error}
  end

  @spec http_module() :: module
  defp http_module() do
    Config.resolve(:http_module, :hackney)
  end

  @spec retry_config() :: Keyword.t()
  defp retry_config() do
    Config.resolve(:retries, [])
  end

  @spec add_attempts(http_success | http_failure, non_neg_integer, Keyword.t()) ::
          {:attempts, non_neg_integer} | {:response, http_success | http_failure}
  defp add_attempts(response, attempts, retry_config) do
    if should_retry?(response, attempts, retry_config) do
      attempts
      |> backoff(retry_config)
      |> :timer.sleep()

      {:attempts, attempts + 1}
    else
      {:response, response}
    end
  end

  @doc """
  Checks if an error is a problem that we should retry on. This includes both
  socket errors that may represent an intermittent problem and some special
  HTTP statuses.
  """
  @spec should_retry?(
          http_success | http_failure,
          attempts :: non_neg_integer,
          config :: Keyword.t()
        ) :: boolean
  def should_retry?(response, attempts \\ 0, config \\ []) do
    max_attempts = Keyword.get(config, :max_attempts) || @default_max_attempts

    if attempts >= max_attempts do
      false
    else
      retry_response?(response)
    end
  end

  @spec json_library() :: module
  def json_library() do
    Config.resolve(:json_library, Jason)
  end

  defp decompress_body(body, headers) do
    headers_dict = :hackney_headers.new(headers)

    case :hackney_headers.get_value("content-encoding", headers_dict) do
      "gzip" -> :zlib.gunzip(body)
      "deflate" -> :zlib.unzip(body)
      _ -> body
    end
  end

  @doc """
  Returns backoff in milliseconds.
  """
  @spec backoff(attempts :: non_neg_integer, config :: Keyword.t()) :: non_neg_integer
  def backoff(attempts, config) do
    base_backoff = Keyword.get(config, :base_backoff) || @default_base_backoff
    max_backoff = Keyword.get(config, :max_backoff) || @default_max_backoff

    (base_backoff * :math.pow(2, attempts))
    |> min(max_backoff)
    |> backoff_jitter()
    |> max(base_backoff)
    |> trunc()
  end

  @spec backoff_jitter(float) :: float
  defp backoff_jitter(n) do
    # Apply some jitter by randomizing the value in the range of (n / 2) to n
    n * (0.5 * (1 + :rand.uniform()))
  end

  @spec retry_response?(http_success | http_failure) :: boolean
  # 409 conflict
  defp retry_response?({:ok, 409, _headers, _body}), do: true
  # Destination refused the connection, the connection was reset, or a
  # variety of other connection failures. This could occur from a single
  # saturated server, so retry in case it's intermittent.
  defp retry_response?({:error, :econnrefused}), do: true
  # Retry on timeout-related problems (either on open or read).
  defp retry_response?({:error, :connect_timeout}), do: true
  defp retry_response?({:error, :timeout}), do: true
  defp retry_response?(_response), do: false
end
