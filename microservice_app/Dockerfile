# Use an official Elixir runtime as a parent image
FROM elixir:latest

# Create and set the working directory
WORKDIR /app

# Install Hex package manager
RUN mix local.hex --force

# Install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get

# Compile the project
COPY . .
RUN mix do compile

# Expose the port on which your app will be running
EXPOSE 4000

# Set the default command to run when starting the container
CMD ["mix", "phx.server"]
