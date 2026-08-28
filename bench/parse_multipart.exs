Code.require_file("support/bench_helper.exs", __DIR__)

alias Mailex.BenchHelper

# Nested multipart messages exercise the recursive part splitting and the
# per-part header parsing.
messages = [
  BenchHelper.fixture!("testmsgs/multi-nested2.msg"),
  BenchHelper.fixture!("testmsgs/multi-digest.msg"),
  BenchHelper.fixture!("conformance/gen_smtp/eml/the-gamut.eml"),
  BenchHelper.fixture!("conformance/gen_smtp/eml/message-text-html-attachment.eml")
]

250
|> BenchHelper.repeat(fn -> Enum.map(messages, &Mailex.parse!/1) end)
|> BenchHelper.report()
