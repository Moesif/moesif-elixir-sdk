# Moesif API Elixir Plug

## Overview

The Moesif API Elixir Plug is a sophisticated API monitoring and analytics tool tailored for Elixir and Phoenix applications. It provides deep insights into API usage, enabling you to understand customer interactions, monitor for issues, enforce API usage policies, and implement usage-based billing solutions. This integration facilitates seamless logging and analysis of high-volume API traffic without significant latency.

## Features

Moesif API Elixir Plug enables your application to:

- Analyze customer API usage patterns.
- Receive alerts on issues detected in your API.
- Implement usage-based billing models.
- Enforce quotas and API contract terms.
- Guide users based on their behavior.

## Installation

1. Add Moesif API Elixir Plug to your list of dependencies in `mix.exs`:

   ```elixir
   def deps do
     [
       {:moesif_api, "~> 0.2.0"}
     ]
   end
   ```

2. Fetch the dependency by running `mix deps.get`.

## Usage

Check out the example application at https://github.com/Moesif/moesif-elixir-phoenix-quickstart

1. Add the Plug to your Phoenix endpoint or router in `endpoint.ex`:

   ```elixir
   plug MoesifApi.Plug.EventLogger, [
     get_user_id: &ExampleApp.get_user_id/1,
     get_company_id: &ExampleApp.get_company_id/1
   ]
   ```

2. Configure the Plug in as the example below. Replace `Your Moesif Application Id` with your Moesif application ID.  The others are optional with production defaults.

   ```elixir
   config :moesif_api, :config,
      application_id: "Your Moesif Application Id",
      event_queue_size: 100_000,
      max_batch_size: 100,
      max_batch_wait_time_ms: 2_000,
      raw_request_body_key: :raw_body,
   ```

3. Add `MoesifApi.EventBatcher` in `application.ex` to handle event batching and sending to Moesif.

  ```elixir
  def start(...) do
    children = [
      ...,
      MoesifApi.EventBatcher,
      ...
    ]
    Supervisor.start_link(children, opts)
  end
  ```

4. If you are using Parsers, you need to use `MoesifApi.CacheBodyReader` to cache the request body. Add the following to your `endpoint.ex`:

   ```elixir
   plug Plug.Parsers,
     parsers: [:urlencoded, :json],
     pass: ["text/*"],
     body_reader: {MoesifApi.CacheBodyReader, :read_body, []},
     json_decoder: Jason
   ```

### Using CacheBodyReader for Request Body Caching

When using parsers that read the request body, such as for JSON or URL-encoded data, it's crucial to ensure the Moesif API Elixir Plug can also access the request body for logging. This is where MoesifApi.CacheBodyReader, a custom reader for Plug.Parsers, comes into play.

#### Accessing Cached Body

After setting up CacheBodyReader, you can access the cached body with the configured key (default :raw_body) in your controllers or other plugs, as required:

```elixir
def your_function(conn, _params) do
  cached_body = conn.assigns[:raw_body]  # Use the configured key if different
end
```

### Capture Outgoing Requests with Tesla

To log outgoing HTTP requests made with Tesla, you can use the `MoesifApi.Middlewares.TeslaLogger` middleware. This will capture and log outgoing requests and responses to Moesif.

#### 1. Add the Middleware to Your Tesla Client

Add `MoesifApi.Middlewares.TeslaLogger` to your Tesla middleware stack. For example:

```elixir
Tesla.client(
  [
    ...
    {MoesifApi.Middlewares.TeslaLogger, Application.get_env(:moesif_api, :config)},
    ...
  ],
  ...
)
```

## Configuration

- `application_id`: Moesif application ID for authentication. **Required**.
- `event_queue_size`: Size of the event queue for batching requests. Default is 100,000.
- `max_batch_size`: Maximum number of events per batch. Default is 100.
- `max_batch_wait_time_ms`: Maximum wait time in milliseconds before sending a batch. Default is 2,000.
- `raw_request_body_key`: Key to access the cached request body in the connection. Default is `:raw_body`.
- `get_user_id`: Function to extract user ID from the request.
- `get_company_id`: Function to extract company ID from the request.
- `get_session_token`: Function to extract session token from the request.
- `get_metadata`: Function to extract metadata from the request.
- `capture_outgoing_requests`: Boolean or Function to capture outgoing requests if returns true.
- `skip`: Boolean or Function to skip logging if returns true.
- `skip_outgoing`: Boolean or Function to skip logging outgoing requests if returns true.
- `debug`: Boolean to indicate should log debug messages. Default is `false`.

## Identifying Users and Companies

- The Plug can identify users and companies for API requests, enhancing tracking and analytics.
- Configure user and company identification methods in the Plug setup in your `endpoint.ex`.

## Troubleshooting

- Ensure environment variables are correctly set.
- Verify proper Plug configuration in your Phoenix application.
- Check for any duplicate instances of the Plug.
- Ensure the Moesif service is reachable and the API key is valid.

## Support

For support and contributions, please raise issues or submit pull requests on our GitHub repository. For more comprehensive documentation, visit [Moesif Documentation](https://www.moesif.com/docs/).
