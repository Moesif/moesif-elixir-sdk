defmodule MoesifApi.Logger do
  @moduledoc """
  Custom logger for Moesif API that respects the debug configuration option.
  """

  require Logger

  @doc """
  Logs an info message if debug is enabled in the configuration.

  ## Parameters
  - message: The message to log
  - metadata: Optional metadata to include with the log (default: [])
  """
  def info(message, metadata \\ []) do
    if debug_enabled?() do
      Logger.info("[Moesif] #{message}", metadata)
    end
  end

  @doc """
  Logs a debug message

  ## Parameters
  - message: The message to log
  - metadata: Optional metadata to include with the log (default: [])
  """
  def debug(message, metadata \\ []) do
    Logger.debug("[Moesif] #{message}", metadata)
  end

  @doc """
  Logs a warning message

  ## Parameters
  - message: The message to log
  - metadata: Optional metadata to include with the log (default: [])
  """
  def warning(message, metadata \\ []) do
    Logger.warning("[Moesif] #{message}", metadata)
  end

  @doc """
  Logs an error message

  ## Parameters
  - message: The message to log
  - metadata: Optional metadata to include with the log (default: [])
  """
  def error(message, metadata \\ []) do
    Logger.error("[Moesif] #{message}", metadata)
  end

  # Checks if debug logging is enabled in the configuration.
  # Returns true if debug is enabled, false otherwise.
  defp debug_enabled?() do
    config = MoesifApi.Config.fetch_config()
    config[:debug]
  end
end
