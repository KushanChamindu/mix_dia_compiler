defmodule Mix.Tasks.Compile.Dia do
  use Mix.Task
  alias Mix.Compilers.Erlang
  alias :filelib, as: Filelib
  alias :diameter_dict_util, as: DiaDictUtil
  alias :diameter_codegen, as: DiaCodegen

  @recursive true
  @manifest ".compile.dia"

  @moduledoc """
  Compiles Diameter source files.

  ## Command line options

  There are no command line options.

  ## Configuration

    * `:erlc_paths` - directories to find source files. Defaults to `["src"]`.

    * `:dia_options` - compilation options that apply
      to Diameter's compiler.

      For a list of the many more available options,
      see [`:diameter_make`](http://erlang.org/doc/man/diameter_make.html).
      Note that the `:outdir` option is overridden by this compiler.

    * `:dia_erl_compile_opts` list of options that will be passed to
      Mix.Compilers.Erlang.compile/6

      Following options are supported:

        * :force        - boolean
        * :verbose      - boolean
        * :all_warnings - boolean
  """

  @doc """
  Runs this task.
  """
  @spec run(OptionParser.argv) :: :ok | :noop
  def run(order) do
    reorder(order, :forward)
    project      = Mix.Project.config
    erlang_compile_opts = project[:dia_erl_compile_opts] || []
    source_paths = project[:erlc_paths]
    mappings     = Enum.zip(["dia"], source_paths)
    options      = project[:dia_options] || []
    # IO.inspect(manifest())
    # IO.inspect(mappings)
    # IO.inspect(project)

    Erlang.compile(manifest(), mappings, :dia, :erl, erlang_compile_opts, fn
      input, output ->
        IO.inspect("Input-- #{input}")
        IO.inspect("Output-- #{output}")
        :ok = Filelib.ensure_dir(output)
        app_path = Mix.Project.app_path(project)
        include_path = to_charlist Path.join(app_path, project[:erlc_include_path])
        # IO.inspect(app_path)
        :ok = Path.join(include_path, "dummy.hrl") |> Filelib.ensure_dir
        # IO.inspect(DiaDictUtil.parse({:path, input}, []))
        case DiaDictUtil.parse({:path, input}, []) do
          {:ok, spec} ->
            filename = dia_filename(input, spec)
            _ = DiaCodegen.from_dict(filename, spec, [{:outdir, 'src'} | options], :erl)
            _ = DiaCodegen.from_dict(filename, spec, [{:outdir, include_path} | options], :hrl)
            file = to_charlist(Path.join("src", filename))
            compile_path = to_charlist Mix.Project.compile_path(project)
            erlc_options = project[:erlc_options] || []
            erlc_options = erlc_options ++ [{:outdir, compile_path}, {:i, include_path}, :report]
            case :compile.file(file, erlc_options) do
              {:ok, module} ->
                {:ok, module, []}
              {:ok, module, warnings} ->
                {:ok, module, warnings}
              {:ok, module, _binary, warnings} ->
                {:ok, module, warnings}
              {:error, errors, warnings} ->
                {:error, errors, warnings}
              :error ->
                {:error, [], []}
            end
          error -> Mix.raise "Diameter compiler error: #{inspect error}"
        end
    end)
    reorder(order, :backward)
  end

  @doc """
  Returns Dia manifests.
  """
  def manifests, do: [manifest()]
  defp manifest, do: Path.join(Mix.Project.manifest_path, @manifest)

  @doc """
  Cleans up compilation artifacts.
  """
  def clean do
    Erlang.clean(manifest())
  end

  defp dia_filename(file, spec) do
    case spec[:name] do
      nil -> Path.basename(file) |> Path.rootname |> to_charlist
      :undefined -> Path.basename(file) |> Path.rootname |> to_charlist
      name -> name
    end
  end

  #################################################
  #                 My codes                      #
  #################################################
  defp check_order_arg(order) do
    case length(order) do
      0 -> {:ok, :compile_with_alphabetical_order}
       _ -> {:ok, :order_length_ok}
   end
  end

  defp rename_files_as_order(order, :forward) do
    [head | tail]= order
    case head do
       %{compile_order: compile_order, file_name: file_name}->
        File.rename("dia/#{file_name}","dia/#{compile_order}.dia")
        case check_order_arg(tail) do
          {:ok, :compile_with_alphabetical_order}-> nil
          {:ok, :order_length_ok} -> rename_files_as_order(tail,:forward)
        end
        _ -> nil
    end
  end
  defp rename_files_as_order(order, :backward)  do
    [head | tail]= order
    case head do
      %{compile_order: compile_order, file_name: file_name}->
       File.rename("dia/#{compile_order}.dia","dia/#{file_name}")
       File.rm("src/#{compile_order}.erl")
       case check_order_arg(tail) do
         {:ok, :compile_with_alphabetical_order}-> nil
         {:ok, :order_length_ok} -> rename_files_as_order(tail,:backward)
       end
       _ -> nil
   end
  end
  @doc """
  re-order files for compile
  """
  def reorder(order, :forward) do
    case check_order_arg(order) do
      {:ok, :compile_with_alphabetical_order} -> IO.inspect('order not specified'); :ok
      {:ok, :order_length_ok} -> IO.inspect(:order_length_ok); rename_files_as_order(order, :forward)
    end
  end
  @doc """
  re-roder files as the past
  """
  def reorder(order, :backward)  do
    case check_order_arg(order) do
      {:ok, :compile_with_alphabetical_order} -> IO.inspect('order not specified'); :ok
      {:ok, :order_length_ok} -> IO.inspect(:order_length_ok); rename_files_as_order(order, :backward)
    end
  end
end
