defmodule Mix.Tasks.UAInspector.ShortCodeMaps.Download do
  @moduledoc """
  Fetches short code map listings from the
  [piwik/device-detector](https://github.com/piwik/device-detector)
  project.

  The listings are extracted from the original PHP source files and stored
  as YAML files in the configured download path.

  `mix ua_inspector.short_code_maps.download`
  """

  use Mix.Task

  alias Mix.UAInspector.Download

  alias UAInspector.Config
  alias UAInspector.ShortCodeMap


  def run(args) do
    Mix.shell.info "UAInspector Short Code Map Download"

    case Config.database_path do
      nil -> Download.exit_unconfigured()
      _   -> Download.request_confirmation(args) |> run_confirmed()
    end
  end



  defp run_confirmed(false) do
    Mix.shell.info "Download aborted!"

    :ok
  end

  defp run_confirmed(true) do
    :ok = Download.prepare_database_path()
    :ok =
         [ ShortCodeMap.DeviceBrands, ShortCodeMap.OSs ]
      |> download()

    Mix.shell.info "Download complete!"

    :ok
  end

  defp download([]),            do: :ok
  defp download([ map | maps ]) do
    target = Path.join([ Config.database_path, map.local ])

    Mix.shell.info ".. downloading: #{ map.local }"
    File.write! target, Mix.Utils.read_path!(map.remote)

    download(maps)
  end
end

if Version.match?(System.version, ">= 1.0.3") do
  #
  # Elixir 1.0.3 and up requires mixed case module namings.
  # The "double uppercase letter" of "UAInspector" violates
  # this rule. This fake task acts as a workaround.
  #
  defmodule Mix.Tasks.UaInspector.ShortCodeMaps.Download do
    @moduledoc false
    @shortdoc  "Downloads parser short code maps"

    use Mix.Task

    defdelegate run(args), to: Mix.Tasks.UAInspector.ShortCodeMaps.Download
  end
else
  #
  # Elixir 1.0.2 requires the underscore module naming.
  #
  defmodule Mix.Tasks.Ua_inspector.Short_code_maps.Download do
    @moduledoc false
    @shortdoc  "Downloads parser short code maps"

    use Mix.Task

    defdelegate run(args), to: Mix.Tasks.UAInspector.ShortCodeMaps.Download
  end
end
