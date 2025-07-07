defmodule MoesifApi.Plug.EventLogger do
  import Plug.Conn  # Import Plug.Conn to use its functions like `assign`

  alias MoesifApi.Logger

  # we do not use compile time config, so no need to do anything here
  def init(opts) do
    opts
  end

  def call(conn, opts) do
    config = MoesifApi.Config.fetch_config(opts)
    should_skip = safely_invoke_getter(config, :skip, conn)

    # Skip the event if the `skip` configuration option is set before the request is logged
    if should_skip do
      Logger.info("Skipped event using `skip` configuration option.")
      conn
    else
      conn
      |> ensure_body_cached(config)
      |> log_request(config)
      |> register_before_send(fn conn -> log_response(conn) end)
    end
  end

  defp log_request(conn, config) do
    full_uri = URI.to_string(%URI{
      scheme: Atom.to_string(conn.scheme),
      host: conn.host,
      port: conn.port,
      path: conn.request_path,
      query: conn.query_string
    })
    # Safely fetch and call getter functions or default to nil
    user_id = safely_invoke_getter(config, :get_user_id, conn)
    company_id = safely_invoke_getter(config, :get_company_id, conn)
    session_token = safely_invoke_getter(config, :get_session_token, conn)
    metadata = safely_invoke_getter(config, :get_metadata, conn)
    {body, transfer_encoding} = process_body(conn.assigns[:raw_body])

    event = %{
      request: %{
        time: DateTime.utc_now() |> DateTime.to_iso8601(),
        uri: full_uri,
        verb: conn.method,
        headers: conn.req_headers |> Enum.into(%{}),
        body: body,
        transfer_encoding: transfer_encoding
      },
      user_id: user_id,
      company_id: company_id,
      session_token: session_token,
      metadata: metadata,
      transaction_id: UUID.uuid4(),
      direction: "Incoming",
      response: nil, # will be filled in if received in log_response
    }
    assign(conn, :moesif_event, event)
  end

  defp log_response(conn) do
    {body, transfer_encoding} = process_body(conn.resp_body)
    response_data = %{
      time: DateTime.utc_now() |> DateTime.to_iso8601(),
      status: conn.status,
      headers: conn.resp_headers |> Enum.into(%{}),
      body: body,
      transfer_encoding: transfer_encoding
    }
    event = conn.assigns[:moesif_event]
    event = Map.put(event, :response, response_data)
    Logger.info(inspect(event))
    MoesifApi.EventBatcher.enqueue(event)
    conn
  end

  defp ensure_body_cached(conn, config) do
    if !Map.has_key?(conn.assigns, config[:raw_request_body_key]) do
        {_, _, conn} = MoesifApi.CacheBodyReader.read_body(conn, [])
        conn
    end
    conn
  end

  # If the body is empty or nil, we can omit it's info from the event
  defp process_body(body) when body == "" or body == nil, do: {nil, nil}

  defp process_body(body) do
    body
    |> IO.chardata_to_string()
    |> try_decode_json()
  end

  defp try_decode_json(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> {decoded, "json"}
      {:error, _} -> {Base.encode64(body), "base64"}
    end
  end

  defp safely_invoke_getter(config, getter_key, conn) do
    case config[getter_key] do
      nil -> nil
      getter_fun when is_function(getter_fun, 1) -> getter_fun.(conn)
      _ -> nil
    end
  end

end
