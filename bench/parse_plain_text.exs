Code.require_file("support/bench_helper.exs", __DIR__)

alias Mailex.BenchHelper

# Simple, single-part messages: the most common shape of email a parser sees.
messages = [
  BenchHelper.fixture!("testmsgs/simple.msg"),
  BenchHelper.fixture!("conformance/gen_smtp/eml/Plain-text-only.eml"),
  BenchHelper.fixture!("conformance/gen_smtp/eml/Plain-text-only-no-MIME.eml"),
  BenchHelper.fixture!("conformance/ruby_mail/eml/content_transfer_encoding_7-bit.eml")
]

500
|> BenchHelper.repeat(fn -> Enum.map(messages, &Mailex.parse!/1) end)
|> BenchHelper.report()
