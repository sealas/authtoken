defmodule AuthToken.Mixfile do
  use Mix.Project

  @version "0.4.0"

  @maintainers ["Daniel Khalil"]
  @description """
  Simplified encrypted authentication tokens using JWE.
  """

  @github "https://github.com/sealas/authtoken"

  def project do
    [
      name: "AuthToken",
      app: :authtoken,
      version: @version,
      description: @description,
      maintainers: @maintainers,
      source_url: @github,
      homepage_url: "https://sealas.at",
      elixir: "~> 1.16",
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps(),
      docs: docs(),
      package: package(),
    ]
  end

  def application do
    [env: [
      timeout: 86400,
      refresh: 1800
    ]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jose, "~> 1.11"},
      {:ojson, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.7.0"},

      {:poison, "~> 4.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev}
    ]
  end

  defp docs do
    [
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      maintainers: @maintainers,
      links: %{github: @github},
      licenses: ["Apache 2.0"],
    ]
  end
end
