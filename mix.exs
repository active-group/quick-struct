defmodule QuickStruct.MixProject do
  use Mix.Project

  def project do
    [
      app: :quick_struct,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/active-group/quick-struct",
      homepage_url: "https://github.com/active-group/quick-struct",
      docs: [
        main: "QuickStruct",
        extras: ["README.md"]
      ]
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
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev], runtime: false}
    ]
  end

  defp description do
    "A macro to create datastructures as structs."
  end

  defp package do
    [
      name: "QuickStruct",
      licenses: ["MIT"],
      links: [source_url: "https://github.com/active-group/quick-struct"]
    ]
  end
end
