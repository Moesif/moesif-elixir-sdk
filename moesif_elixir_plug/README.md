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
       {:moesif_api_plug, "~> 0.1.0"}
     ]
   end
   ```

2. Fetch the dependency by running `mix deps.get`.

## Usage

1. Add the Plug to your Phoenix endpoint or router in `endpoint.ex`:

   ```elixir
   plug MoesifApi.Plug.EventLogger, [
     get_user_id: &ExampleApp.get_user_id/1,
     get_company_id: &ExampleApp.get_company_id/1
   ]
   ```

2. Configure the Plug in `config/runtime.exs`:

   ```elixir
   config :microservice_app, MoesifApi.Plug.EventLogger,
     application_id: System.get_env("MOESIF_APPLICATION_ID") || "Your Moesif Application ID",
     event_queue_size: String.to_integer(System.get_env("MOESIF_EVENT_QUEUE_SIZE") || "100000"),
     max_batch_size: String.to_integer(System.get_env("MOESIF_MAX_BATCH_SIZE") || "10"),
     max_batch_wait_time_ms: String.to_integer(System.get_env("MOESIF_MAX_BATCH_WAIT_TIME_MS") || "2000")
   ```

## Configuration

- `application_id`: Moesif application ID for authentication.
- `event_queue_size`: Size of the event queue for batching requests.
- `max_batch_size`: Maximum number of events per batch.
- `max_batch_wait_time_ms`: Maximum wait time in milliseconds before sending a batch.

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
