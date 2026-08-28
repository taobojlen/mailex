# The benchmarks run as plain `elixir` scripts, so the compiled application has
# to be put on the code path by hand. `MIX_ENV` wins, otherwise fall back to
# whichever build is available.
build_envs =
  [System.get_env("MIX_ENV"), "prod", "dev"]
  |> Enum.reject(&is_nil/1)
  |> Enum.uniq()

ebin_dirs =
  Enum.find_value(build_envs, [], fn env ->
    case Path.wildcard(Path.expand("../../_build/#{env}/lib/*/ebin", __DIR__)) do
      [] -> nil
      dirs -> dirs
    end
  end)

if ebin_dirs == [] do
  IO.puts(:stderr, "No compiled artifacts found in _build. Run `mix compile` first.")
  System.halt(1)
end

Enum.each(ebin_dirs, &Code.prepend_path/1)
{:ok, _apps} = Application.ensure_all_started(:mailex)

defmodule Mailex.BenchHelper do
  @moduledoc """
  Shared helpers for the benchmark scripts in `bench/`.

  The benchmarks are driven by the CodSpeed exec harness (see `codspeed.yml`):
  every script is a standalone program whose whole execution is measured, so the
  scripts only have to do a fixed, deterministic amount of work. The scripts are
  started with plain `elixir` (rather than `mix run`) to keep the fixed startup
  cost, which is included in every measurement, as small as possible.
  """

  @fixtures_dir Path.expand("../../test/fixtures", __DIR__)

  @doc "Reads a fixture from `test/fixtures`."
  def fixture!(relative_path) do
    @fixtures_dir |> Path.join(relative_path) |> File.read!()
  end

  @doc """
  Reads every fixture with the given extension from a directory under
  `test/fixtures`, sorted by filename so the workload stays deterministic.
  """
  def fixtures!(relative_dir, extension) do
    dir = Path.join(@fixtures_dir, relative_dir)

    dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, extension))
    |> Enum.sort()
    |> Enum.map(&File.read!(Path.join(dir, &1)))
  end

  @doc """
  Runs `fun` `count` times and returns a checksum of the results so the work
  cannot be discarded.
  """
  def repeat(count, fun) when is_integer(count) and count > 0 do
    Enum.reduce(1..count, 0, fn _i, acc -> acc + consume(fun.()) end)
  end

  @doc """
  Prints a checksum of the benchmark's output. Keeping a data-dependent side
  effect at the very end of the script guarantees the runtime actually performed
  the work that was measured.
  """
  def report(checksum) do
    IO.puts("checksum=#{checksum}")
  end

  defp consume(term), do: :erlang.phash2(term)
end
