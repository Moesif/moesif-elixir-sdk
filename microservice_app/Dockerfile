# Use an official Elixir runtime as a parent image
FROM elixir:latest AS builder

# Set the environment to prod
ENV MIX_ENV=prod

# Create and set the working directory
WORKDIR /app

# Install Hex package manager and rebar
RUN mix do local.hex --force, local.rebar --force

# Install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# Compile the project
COPY . .
RUN mix do compile, release

# Start a new stage for the runtime environment
FROM elixir:latest

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/microservice_app ./

# Expose the port on which your app will be running
EXPOSE 4000

# Set the secret key base, this is used to encrypt the session cookie
# You can generate a real one by running: mix phx.gen.secret 
# to overwrite this example placeholder in your builds
ENV SECRET_KEY_BASE=your_generated_secret_key
ENV PHX_SERVER=true

# Use a non-root user
RUN useradd -m myuser
USER myuser

# Set the default command to run when starting the container
CMD ["./bin/microservice_app", "start"]
