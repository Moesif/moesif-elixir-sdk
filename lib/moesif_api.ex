defmodule MoesifApi do
  @moduledoc """
  Moesif API Elixir Library.
  """

  def safely_invoke_getter(config, getter_key, opts \\ nil) do
    case config[getter_key] do
      nil -> nil
      getter_fun when is_function(getter_fun, 0) -> getter_fun.()
      getter_fun when is_function(getter_fun, 1) -> getter_fun.(opts)
      value when is_boolean(value) -> value
      _ -> nil
    end
  end
end
