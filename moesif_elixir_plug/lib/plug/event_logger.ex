defmodule MoesifApi.Plug.EventLogger do
  alias ElixirSense.Log
  import Plug.Conn  # Import Plug.Conn to use its functions like `assign`
  require Logger

  # we do not use compile time config, so no need to do anything here
  def init(opts) do
    opts
  end

  def call(conn, opts) do
    # Fetch runtime configuration and merge with compile time config
    config = MoesifApi.Config.fetch_config(opts)
    Logger.info("Calling EventLogger Plug with config #{inspect(config)}")

    conn
    |> log_request(config)
    |> register_before_send(fn conn -> log_response(conn, config) end)
  end

  defp log_request(conn, config) do
    full_uri = URI.to_string(%URI{
      scheme: Atom.to_string(conn.scheme),
      host: conn.host,
      port: conn.port,
      path: conn.request_path,
      query: conn.query_string
    })
    Logger.debug("request.body_params #{inspect(conn.body_params)}")
    # if the body_params has the :all_nested special key "_json", then read that value; otherwise, use top-level body_params
    body = Map.get(conn.body_params, "_json", conn.body_params)


    # Safely fetch and call getter functions or default to nil
    user_id = safely_invoke_getter(config, :get_user_id, conn)
    company_id = safely_invoke_getter(config, :get_company_id, conn)
    session_token = safely_invoke_getter(config, :get_session_token, conn)
    metadata = safely_invoke_getter(config, :get_metadata, conn)

    event = %{
      request: %{
        time: DateTime.utc_now() |> DateTime.to_iso8601(),
        uri: full_uri,
        verb: conn.method,
        headers: conn.req_headers |> Enum.into(%{}),
        body: body
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

  defp log_response(conn, _config) do
    Logger.info("log_response")
    response_data = %{
      time: DateTime.utc_now() |> DateTime.to_iso8601(),
      status: conn.status,
      headers: conn.resp_headers |> Enum.into(%{}),
      body: conn.resp_body |> IO.chardata_to_string |> Jason.decode!()
    }
    event = conn.assigns[:moesif_event]
    event = Map.put(event, :response, response_data)
    Logger.info inspect(event, pretty: true)

    MoesifApi.EventBatcher.enqueue(event)
    conn
  end

  defp safely_invoke_getter(config, getter_key, conn) do
    case config[getter_key] do
      nil -> nil
      getter_fun when is_function(getter_fun, 1) -> getter_fun.(conn)
      _ -> nil
    end
  end

end
