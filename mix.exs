defmodule MoesifApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :moesif_api,
      version: "0.2.0",
      elixir: "~> 1.14",
      deps: deps(),
      description: "The Moesif API Elixir Plug is a sophisticated API monitoring and analytics tool tailored for Elixir and Phoenix applications.",
      package: package(),
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:elixir_uuid, "~> 1.2"},
      {:httpoison, "~> 1.0"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
    ]
  end

  defp package do
    [
      maintainers: ["Brian Kennedy"],
      files: ["lib", "mix.exs", "README.md"],
      licenses: ["Apache-2.0"],  # must match the license in project
      links: %{"GitHub" => "https://github.com/Moesif/moesif-elixir-sdk"}
    ]
  end
end
