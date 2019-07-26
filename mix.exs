defmodule Nadia.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nadia,
      version: "0.5.0",
      elixir: "~> 1.6",
      description: "Telegram Bot API Wrapper written in Elixir",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:httpoison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:httpoison, "~> 1.5.1"},
      {:jason, "~> 1.1"},
      {:exvcr, "~> 0.10.1", only: [:dev, :test]},
      {:earmark, "~> 1.2", only: :docs},
      {:ex_doc, "~> 0.21.1", only: :docs},
      {:inch_ex, "~> 2.0.0", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["zhyu"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/zhyu/nadia"}
    ]
  end
end
