defmodule Framer.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :framer,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Framer",
      source_url: "https://github.com/bolek/framer",
      description: "Helper functions to resize iodata streams and lists",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package() do
    [
      maintainers: ["Bolek Kurowski"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bolek/framer"},
      files: ~w(lib LICENSE.md mix.exs README.md .formatter.exs)
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ex_doc, "~> 0.20", only: :dev}
    ]
  end
end
