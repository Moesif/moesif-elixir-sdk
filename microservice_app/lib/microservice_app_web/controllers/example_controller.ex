defmodule MicroserviceAppWeb.ExampleController do
  use MicroserviceAppWeb, :controller

  def index(conn, _params) do
    json(conn, %{message: "Welcome to our example service!"})
  end
end
