defmodule Mix.Tasks.Docs.Show do
  @moduledoc """
  Show documentation in web browser.
  """

  use Mix.Task

  @doc false
  @shortdoc "Show documentation in web browser"
  def run(_) do
    System.cmd("google-chrome", ["doc/index.html"])
  end
end
