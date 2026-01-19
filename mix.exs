defmodule Mailex.MixProject do
  use Mix.Project

  def project do
    [
      app: :mailex,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Mailex",
      source_url: "https://github.com/taobojlen/mailex",
      description: description(),
      package: package()
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
      {:codepagex, "~> 0.1.6"},
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
end
