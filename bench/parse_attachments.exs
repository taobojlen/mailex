Code.require_file("support/bench_helper.exs", __DIR__)

alias Mailex.BenchHelper

# Messages dominated by encoded attachments: base64 and quoted-printable
# body decoding plus Content-Disposition filename extraction.
messages = [
  BenchHelper.fixture!("testmsgs/multi-2gifs.msg"),
  BenchHelper.fixture!("conformance/gen_smtp/eml/image-and-text-attachments.eml"),
  BenchHelper.fixture!("conformance/gen_smtp/eml/utf-attachment-name.eml"),
  BenchHelper.fixture!("testmsgs/german-qp.msg")
]

400
|> BenchHelper.repeat(fn -> Enum.map(messages, &Mailex.parse!/1) end)
|> BenchHelper.report()
