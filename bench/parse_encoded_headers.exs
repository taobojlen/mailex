Code.require_file("support/bench_helper.exs", __DIR__)

alias Mailex.BenchHelper

# RFC 2047 encoded words and legacy charset transcoding (codepagex).
messages = [
  BenchHelper.fixture!("testmsgs/russian.msg"),
  BenchHelper.fixture!("testmsgs/german.msg"),
  BenchHelper.fixture!("charsets/windows-1251-cyrillic.eml"),
  BenchHelper.fixture!("charsets/windows-1252-subject.eml"),
  BenchHelper.fixture!("charsets/windows-1252-body-8bit.eml")
]

550
|> BenchHelper.repeat(fn -> Enum.map(messages, &Mailex.parse!/1) end)
|> BenchHelper.report()
