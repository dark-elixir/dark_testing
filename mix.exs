defmodule DarkTesting.MixProject do
  @moduledoc """
  Mix Project for `DarkTesting`
  """

  use Mix.Project

  @version "1.0.0"
  @name "DarkTesting"
  @hexpm_url "http://hexdocs.pm/dark_testing"
  @github_url "https://github.com/dark-elixir/dark_testing"
  @description "Libraries and utils for general elixir development."

  def project do
    [
      app: :dark_testing,
      version: @version,
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      dialyzer: [plt_add_apps: [:ex_unit]],

      # Hex
      description: @description,
      package: package(),
      source_url: @github_url,

      # Docs
      name: @name,
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:dark_dev, ">= 1.0.3", only: [:dev, :test], runtime: false},
      {:dark_matter, ">= 1.0.3"},
      # {:dark_ecto, ">= 1.0.0"},
      {:dark_ecto, path: "../dark_ecto"},
      {:ecto, ">= 3.0.0", optional: true},
      {:jason, ">= 1.0.0"},
      {:struct_assert, ">= 0.0.0"}
    ]
  end

  defp package() do
    [
      maintainers: ["Michael Sitchenko"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_url}
    ]
  end

  defp docs do
    [
      main: @name,
      source_ref: "v#{@version}",
      canonical: @hexpm_url,
      logo: "guides/images/dark-elixir.png",
      extra_section: "GUIDES",
      source_url: @github_url,
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: []
    ]
  end

  def extras() do
    [
      # "guides/introduction/Getting Started.md",
      "README.md"
    ]
  end

  defp groups_for_extras do
    [
      # Introduction: ~r/guides\/introduction\/.?/,
    ]
  end
end
