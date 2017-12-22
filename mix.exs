defmodule AuthToken.Mixfile do
  use Mix.Project

  def project do
    [
      name: "AuthToken",
      app: :authtoken,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env),
      docs: docs(),
      maintainers: ["Daniel Khalil"],
      source_url: "https://github.com/Brainsware/authtoken",
      homepage_url: "https://sealas.at",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jose, "~> 1.8"},
      {:plug, "~> 1.4"},
      {:phoenix, "~> 1.3"},

      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18", only: :dev}
    ]
  end

  defp docs do
    [
      extras: ["README.md"]
    ]
  end
end
