Code.require_file("support/bench_helper.exs", __DIR__)

alias Mailex.BenchHelper

# Broad, real-world corpus: every gen_smtp and ruby_mail conformance fixture,
# including the malformed ones that hit the parser's recovery paths.
messages =
  BenchHelper.fixtures!("conformance/gen_smtp/eml", ".eml") ++
    BenchHelper.fixtures!("conformance/ruby_mail/eml", ".eml")

45
|> BenchHelper.repeat(fn -> Enum.map(messages, &Mailex.parse/1) end)
|> BenchHelper.report()
