defmodule MoesifApi.Config do
  def fetch_config(opts \\ []) do
    env_config = Application.get_env(:moesif_api, :config, [])
    with_defaults = Keyword.merge(default_config(), env_config)
    Keyword.merge(with_defaults, opts)
  end

  defp default_config do
    [
      api_url: "https://api.moesif.net/v1/events/batch",
      application_id: "Your Moesif Application Id",
      event_queue_size: 100_000,
      max_batch_size: 100,
      max_batch_wait_time_ms: 2_000,
      raw_request_body_key: :raw_body,
      debug: false,
    ]
  end
end
