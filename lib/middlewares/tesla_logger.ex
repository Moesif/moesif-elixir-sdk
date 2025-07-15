defmodule MoesifApi.Middlewares.TeslaLogger do
  @moduledoc """
  Tesla middleware for logging requests to Moesif API.
  """

  @behaviour Tesla.Middleware

  alias MoesifApi.Logger

  @impl true
  def call(env, next, opts) do
    config = MoesifApi.Config.fetch_config(opts)
    should_capture_outgoing = MoesifApi.safely_invoke_getter(config, :capture_outgoing_requests, env)

    if should_capture_outgoing do
      should_skip_outgoing = MoesifApi.safely_invoke_getter(config, :skip_outgoing, env)

      if should_skip_outgoing do
        Logger.info("Skipped event using `skip_outgoing` configuration option.")
        Tesla.run(env, next)
      else
        user_id = Keyword.get(opts, :user_id)
        company_id = Keyword.get(opts, :company_id)
        session_token = Keyword.get(opts, :session_token)
        metadata = Keyword.get(opts, :metadata)
        {body, transfer_encoding} = process_body(env.body)

        event = %{
          request: %{
            time: DateTime.utc_now() |> DateTime.to_iso8601(),
            uri: env.url,
            verb: env.method |> to_string |> String.upcase(),
            headers: env.headers |> Enum.into(%{}),
            body: body,
            transfer_encoding: transfer_encoding
          },
          user_id: user_id,
          company_id: company_id,
          session_token: session_token,
          metadata: metadata,
          transaction_id: UUID.uuid4(),
          direction: "outgoing"
        }

        Tesla.run(env, next)
        |> log_response(event)
      end
    else
      Logger.info("Skipped event using `capture_outgoing_requests` configuration option.")
      Tesla.run(env, next)
    end
  end

  defp log_response({:ok, env} = result, event) do
    {body, transfer_encoding} = process_body(env.body)

    response = %{
      time: DateTime.utc_now() |> DateTime.to_iso8601(),
      status: env.status,
      headers: env.headers |> Enum.into(%{}),
      body: body,
      transfer_encoding: transfer_encoding
    }

    log_event_to_moesif(event, response)
    result
  end

  defp log_response({:error, reason} = result, event) do
    response = %{
      time: DateTime.utc_now() |> DateTime.to_iso8601(),
      status: get_status_from_error(reason),
      headers: %{},
      body: nil,
      transfer_encoding: nil
    }

    log_event_to_moesif(event, response)
    result
  end

  defp log_response(result, _), do: result

  defp log_event_to_moesif(event, response) do
    event = Map.put(event, :response, response)
    Logger.info(inspect(event))
    MoesifApi.EventBatcher.enqueue(event)
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

  defp get_status_from_error(reason) do
    case reason do
      :timeout -> 504
      :nxdomain -> 503
      :econnrefused -> 503
      :econnreset -> 503
      :closed -> 503
      _ -> 502
    end
  end
end
