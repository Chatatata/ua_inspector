defmodule UAInspector.App do
  @moduledoc false

  use Application

  def start(_type, _args), do: UAInspector.Supervisor.start_link()
end
