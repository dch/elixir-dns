defmodule DNS.Mixfile do
  use Mix.Project

  @source_url "https://github.com/tungd/elixir-dns"
  @version "2.4.0"

  def project do
    [
      app: :dns,
      version: @version,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.35", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      description: "DNS library for Elixir using `inet_dns` module.",
      maintainers: ["Tung Dao", "João Veiga"],
      licenses: ["BSD-3-Clause"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp aliases do
    [
      lint: ["format --check-formatted", "dialyzer --format dialyxir"]
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
