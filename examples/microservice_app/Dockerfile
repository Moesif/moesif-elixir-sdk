#syntax=docker/dockerfile:1
FROM elixir:latest AS builder       

# Set the environment to prod
ENV MIX_ENV=prod

# Create and set the working directory
WORKDIR /app

# Install Hex package manager and rebar
RUN mix do local.hex --force, local.rebar --force

# Install dependencies with cache
COPY mix.exs mix.lock ./
RUN --mount=type=cache,target=/root/.mix \
    --mount=type=cache,target=/app/_build \
    mix deps.get --only prod

# Compile the project, reusing the cached _build directory
COPY . .
RUN --mount=type=cache,target=/app/_build mix do compile, release --path /app/release_output

RUN ls -l /app/release_output

#------------------------------------------------------------------------------
# Runtime image
FROM elixir:latest

WORKDIR /app
COPY --from=builder /app/release_output ./

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
