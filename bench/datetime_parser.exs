Code.require_file("support/bench_helper.exs", __DIR__)

alias Mailex.BenchHelper
alias Mailex.DateTimeParser

# Date header values, including obsolete zone names, two digit years and
# malformed input that fails to parse.
dates = [
  "Mon, 15 Jan 2024 09:30:00 -0500",
  "Tue, 1 Jul 2003 10:52:37 +0200",
  "15 Jan 2024 14:30:00 GMT",
  "Thu, 13 Feb 69 23:32:54 -0330",
  "Fri, 21 Nov 1997 09:55:06 -0600 (CST)",
  "Sat, 24 Dec 2022 00:00:00 UT",
  "not a date at all"
]

4000
|> BenchHelper.repeat(fn ->
  Enum.map(dates, fn date ->
    case DateTimeParser.parse(date) do
      {:ok, parsed} -> DateTimeParser.to_utc_datetime(parsed)
      error -> error
    end
  end)
end)
|> BenchHelper.report()
