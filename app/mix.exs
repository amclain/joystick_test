defmodule JoystickTest.MixProject do
  use Mix.Project

  @app         :joystick_test
  @version     "0.1.0"
  @all_targets [:bbb]

  def project do
    [
      app:                  @app,
      version:              @version,
      elixir:               "~> 1.10",
      archives:             [nerves_bootstrap: "~> 1.7"],
      start_permanent:      Mix.env() == :prod,
      build_embedded:       true,
      aliases:              [loadconfig: [&bootstrap/1]],
      deps:                 deps(),
      docs:                 docs(),
      source_url:           "https://github.com/amclain/joystick_test",
      releases:             [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host],
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {JoystickTest.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
      ],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves,      "~> 1.5.0", runtime: false},
      {:shoehorn,    "~> 0.6"},
      {:ring_logger, "~> 0.6"},
      {:toolshed,    "~> 0.2"},

      {:circuits_gpio, "~> 0.1"},
      {:afk,           "~> 0.2"},

      # Host dependencies
      {:ex_doc, "~> 0.21.3", targets: :host, only: :dev, runtime: false},

      # Dependencies for all targets except :host
      {:nerves_runtime,     "~> 0.6", targets: @all_targets},
      {:usb_gadget, github: "nerves-project/usb_gadget", targets: @all_targets},

      # Dependencies for specific targets
      # {:nerves_system_bbb, "~> 2.5", runtime: false, targets: :bbb},
      {
        :nerves_system_bbb_configfs,
        github:  "doughsay/nerves_system_bbb_configfs",
        ref:     "v2.5.0+configfs",
        runtime: false,
        targets: :bbb
      },
    ]
  end

  defp docs do
    [
      extras: [
        "README.md",
      ]
    ]
  end

  def release do
    [
      overwrite:    true,
      cookie:       "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps:        [&Nerves.Release.init/1, :assemble],
      strip_beams:  Mix.env() == :prod
    ]
  end
end
