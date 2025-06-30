defmodule MoesifApi.CacheBodyReader do
  def read_body(conn, opts) do
    config = MoesifApi.Config.fetch_config()

    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    # Cache the body under the specified key in MoesisApi's config :raw_request_body_key, default is :raw_body
    conn = put_in(conn.assigns[config[:raw_request_body_key]], body)

    {:ok, body, conn}
  end
end
