defmodule UAInspector.Downloader do
  @moduledoc """
  File download utility module.
  """

  alias UAInspector.Config
  alias UAInspector.Database
  alias UAInspector.Downloader.ShortCodeMapConverter
  alias UAInspector.Downloader.README
  alias UAInspector.ShortCodeMap

  @databases [
    Database.Bots,
    Database.BrowserEngines,
    Database.Clients,
    Database.Devices,
    Database.OSs,
    Database.VendorFragments
  ]

  @short_code_maps [
    ShortCodeMap.ClientBrowsers,
    ShortCodeMap.DeviceBrands,
    ShortCodeMap.MobileBrowsers,
    ShortCodeMap.OSs
  ]

  @doc """
  Performs download of all files.
  """
  @spec download() :: :ok
  def download() do
    :ok = download(:databases)
    :ok = download(:short_code_maps)
    :ok
  end

  @doc """
  Performs download of configured database files and short code maps.
  """
  @spec download(:databases | :short_code_maps) :: :ok
  def download(:databases) do
    :ok = prepare_database_path()

    Enum.each(@databases, fn database ->
      Enum.each(database.sources, fn {_type, local, remote} ->
        target = Path.join([Config.database_path(), local])

        :ok = download_file(remote, target)
      end)
    end)
  end

  def download(:short_code_maps) do
    :ok = prepare_database_path()

    Enum.each(@short_code_maps, fn short_code_map ->
      yaml = Path.join([Config.database_path(), short_code_map.file_local])
      temp = "#{yaml}.tmp"

      :ok = download_file(short_code_map.file_remote, temp)

      :ok =
        short_code_map.var_name
        |> ShortCodeMapConverter.extract(short_code_map.var_type, temp)
        |> ShortCodeMapConverter.write_yaml(short_code_map.var_type, yaml)

      :ok = File.rm!(temp)
    end)
  end

  @doc """
  Prepares the local database path for downloads.
  """
  @spec prepare_database_path() :: :ok
  def prepare_database_path() do
    unless File.dir?(Config.database_path()) do
      File.mkdir_p!(Config.database_path())
    end

    README.write()
  end

  @doc """
  Reads a remote file and returns it's contents.
  """
  @spec read_remote(String.t()) :: term
  def read_remote(path) do
    http_opts = Config.get(:http_opts, [])
    {:ok, _, _, client} = :hackney.get(path, [], [], http_opts)

    :hackney.body(client)
  end

  defp download_file(remote, local) do
    {:ok, content} = read_remote(remote)

    File.write!(local, content)
  end
end
