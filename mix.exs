defmodule Mailex.MixProject do
  use Mix.Project

  @version "0.1.2"

  def project do
    [
      app: :mailex,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Mailex",
      source_url: "https://github.com/taobojlen/mailex",
      homepage_url: "https://github.com/taobojlen/mailex",
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.4"},
      {:codepagex, "~> 0.1.13"},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false},
      {:jason, "~> 1.4", only: :test}
    ]
  end

  defp description do
    "An experimental email parser."
  end

  defp package do
    [
      name: "mailex",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/taobojlen/mailex"}
    ]
  end

  defp docs do
    [
      main: "Mailex",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        Parsing: [
          Mailex.Parser,
          Mailex.AddressParser,
          Mailex.DateTimeParser
        ],
        Structs: [
          Mailex.Message,
          Mailex.DateTimeParser
        ]
      ]
    ]
  end
end
