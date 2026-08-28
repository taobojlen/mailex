Code.require_file("support/bench_helper.exs", __DIR__)

alias Mailex.BenchHelper

# A single large (~85 kB) fragmented message: throughput on big bodies.
message = BenchHelper.fixture!("testmsgs/frag.msg")

50
|> BenchHelper.repeat(fn -> Mailex.parse!(message) end)
|> BenchHelper.report()
