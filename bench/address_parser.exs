Code.require_file("support/bench_helper.exs", __DIR__)

alias Mailex.AddressParser
alias Mailex.BenchHelper

# Address header values: plain mailboxes, display names, quoted strings,
# comments, groups, domain literals and internationalized (RFC 6532) addresses.
address_lists = [
  "user@example.com",
  "John Doe <john.doe@example.com>",
  "\"Doe, John\" <john.doe@example.com>, Jane <jane@example.org>",
  "Alice <alice@example.com>, Bob <bob@example.net>, carol@example.org, \"D. D\" <dave@example.co.uk>",
  "Team: alice@example.com, bob@example.com;, Marketing: carol@example.org;",
  "user(a comment)@example.com, other@[192.168.0.1]",
  "Pelé <pele@example.com>, θσερ <θσερ@example.gr>",
  "very.common@example.com, disposable.style.email.with+symbol@example.com, other.email-with-hyphen@example.com"
]

single_addresses = [
  "user@example.com",
  "\"quoted.user\"@example.com",
  "first.last@sub.domain.example.com"
]

1400
|> BenchHelper.repeat(fn ->
  {Enum.map(address_lists, &AddressParser.parse_address_list/1),
   Enum.map(single_addresses, &AddressParser.parse_addr_spec/1)}
end)
|> BenchHelper.report()
