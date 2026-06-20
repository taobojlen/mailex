defmodule Mailex.AddressParserTest do
  use ExUnit.Case, async: true

  alias Mailex.AddressParser

  describe "addr-spec parsing" do
    test "parses simple address" do
      assert {:ok, result} = AddressParser.parse_addr_spec("john@example.com")
      assert result.local_part == "john"
      assert result.domain == "example.com"
    end

    test "parses address with dot-atom local-part" do
      assert {:ok, result} = AddressParser.parse_addr_spec("john.doe@example.com")
      assert result.local_part == "john.doe"
      assert result.domain == "example.com"
    end

    test "parses address with subdomain" do
      assert {:ok, result} = AddressParser.parse_addr_spec("user@mail.example.com")
      assert result.local_part == "user"
      assert result.domain == "mail.example.com"
    end

    test "parses quoted local-part" do
      assert {:ok, result} = AddressParser.parse_addr_spec(~s("weird local"@example.com))
      assert result.local_part == "weird local"
      assert result.domain == "example.com"
    end

    test "parses quoted local-part with escaped quote" do
      assert {:ok, result} = AddressParser.parse_addr_spec(~s("hello\\"world"@example.com))
      assert result.local_part == ~s(hello"world)
      assert result.domain == "example.com"
    end

    test "parses domain-literal" do
      assert {:ok, result} = AddressParser.parse_addr_spec("user@[127.0.0.1]")
      assert result.local_part == "user"
      assert result.domain == "[127.0.0.1]"
    end

    test "parses domain-literal with IPv6" do
      assert {:ok, result} = AddressParser.parse_addr_spec("user@[IPv6:2001:db8::1]")
      assert result.local_part == "user"
      assert result.domain == "[IPv6:2001:db8::1]"
    end
  end

  describe "mailbox parsing" do
    test "parses bare addr-spec as mailbox" do
      assert {:ok, result} = AddressParser.parse_mailbox("john@example.com")
      assert result.type == :mailbox
      assert result.address == "john@example.com"
      assert result.name == nil
    end

    test "parses angle-addr without display-name" do
      assert {:ok, result} = AddressParser.parse_mailbox("<john@example.com>")
      assert result.type == :mailbox
      assert result.address == "john@example.com"
      assert result.name == nil
    end

    test "parses name-addr with simple display-name" do
      assert {:ok, result} = AddressParser.parse_mailbox("John Doe <john@example.com>")
      assert result.type == :mailbox
      assert result.address == "john@example.com"
      assert result.name == "John Doe"
    end

    test "parses name-addr with quoted display-name" do
      assert {:ok, result} = AddressParser.parse_mailbox(~s("Last, First" <user@example.com>))
      assert result.type == :mailbox
      assert result.address == "user@example.com"
      assert result.name == "Last, First"
    end

    test "parses name-addr with display-name containing period (obs-phrase)" do
      assert {:ok, result} = AddressParser.parse_mailbox("J. R. Smith <jrs@example.com>")
      assert result.type == :mailbox
      assert result.address == "jrs@example.com"
      assert result.name == "J. R. Smith"
    end

    test "parses mailbox with comment after addr-spec" do
      assert {:ok, result} = AddressParser.parse_mailbox("john@example.com (John Doe)")
      assert result.type == :mailbox
      assert result.address == "john@example.com"
      # Per RFC 5322, comments are stripped (not converted to display-name)
      # The address must be extracted cleanly without the comment text
      assert result.name == nil
      # Verify the comment text doesn't leak into the address
      refute String.contains?(result.address, "John")
      refute String.contains?(result.address, "(")
    end

    test "parses mailbox with comment in display-name" do
      assert {:ok, result} = AddressParser.parse_mailbox("John (CEO) <john@example.com>")
      assert result.type == :mailbox
      assert result.address == "john@example.com"
      assert result.name == "John"
    end

    test "handles CFWS around angle brackets" do
      assert {:ok, result} = AddressParser.parse_mailbox("John Doe  <  john@example.com  >")
      assert result.type == :mailbox
      assert result.address == "john@example.com"
      assert result.name == "John Doe"
    end
  end

  describe "group parsing" do
    test "parses group with single mailbox" do
      assert {:ok, result} = AddressParser.parse_group("Team: alice@example.com;")
      assert result.type == :group
      assert result.name == "Team"
      assert length(result.members) == 1
      assert hd(result.members).address == "alice@example.com"
    end

    test "parses group with multiple mailboxes" do
      assert {:ok, result} =
               AddressParser.parse_group("Team: alice@a.com, bob@b.com, carol@c.com;")

      assert result.type == :group
      assert result.name == "Team"
      assert length(result.members) == 3
    end

    test "parses empty group (RFC 6854 no-reply)" do
      assert {:ok, result} = AddressParser.parse_group("Automated System:;")
      assert result.type == :group
      assert result.name == "Automated System"
      assert result.members == []
    end

    test "parses group with display-names in mailboxes" do
      assert {:ok, result} =
               AddressParser.parse_group("Team: Alice <alice@a.com>, Bob <bob@b.com>;")

      assert result.type == :group
      assert result.name == "Team"
      assert length(result.members) == 2
      assert Enum.any?(result.members, &(&1.name == "Alice"))
    end

    test "parses group with quoted display-name" do
      assert {:ok, result} = AddressParser.parse_group(~s("Team, Awesome": member@test.com;))
      assert result.type == :group
      assert result.name == "Team, Awesome"
    end
  end

  describe "address parsing" do
    test "parses address as mailbox" do
      assert {:ok, result} = AddressParser.parse_address("John <john@example.com>")
      assert result.type == :mailbox
    end

    test "parses address as group" do
      assert {:ok, result} = AddressParser.parse_address("Team: member@test.com;")
      assert result.type == :group
    end
  end

  describe "address-list parsing" do
    test "parses single address" do
      assert {:ok, [addr]} = AddressParser.parse_address_list("john@example.com")
      assert addr.type == :mailbox
    end

    test "parses multiple mailboxes" do
      assert {:ok, addrs} =
               AddressParser.parse_address_list("alice@a.com, bob@b.com, carol@c.com")

      assert length(addrs) == 3
    end

    test "parses mixed mailboxes and groups" do
      input = "alice@a.com, Team: bob@b.com;, carol@c.com"
      assert {:ok, addrs} = AddressParser.parse_address_list(input)
      assert length(addrs) == 3
      assert Enum.at(addrs, 0).type == :mailbox
      assert Enum.at(addrs, 1).type == :group
      assert Enum.at(addrs, 2).type == :mailbox
    end

    test "handles whitespace around commas" do
      assert {:ok, addrs} = AddressParser.parse_address_list("alice@a.com ,  bob@b.com")
      assert length(addrs) == 2
    end

    test "handles obs-addr-list with empty elements" do
      assert {:ok, addrs} = AddressParser.parse_address_list(",alice@a.com,,bob@b.com,")
      assert length(addrs) == 2
    end
  end

  describe "CFWS and comment handling" do
    test "skips leading/trailing whitespace" do
      assert {:ok, result} = AddressParser.parse_mailbox("   john@example.com   ")
      assert result.address == "john@example.com"
    end

    test "handles nested comments" do
      assert {:ok, result} = AddressParser.parse_mailbox("john@example.com (A (nested) comment)")
      assert result.address == "john@example.com"
    end

    test "handles escaped characters in comments" do
      assert {:ok, result} =
               AddressParser.parse_mailbox("john@example.com (Comment \\) with paren)")

      assert result.address == "john@example.com"
    end
  end

  describe "edge cases and robustness" do
    test "rejects invalid address" do
      assert {:error, _} = AddressParser.parse_addr_spec("not-an-email")
    end

    test "rejects address with multiple @" do
      assert {:error, _} = AddressParser.parse_addr_spec("bad@@example.com")
    end

    test "handles very long local-part" do
      local = String.duplicate("a", 64)
      assert {:ok, result} = AddressParser.parse_addr_spec("#{local}@example.com")
      assert result.local_part == local
    end
  end

  describe "RFC 6532 internationalized addresses (EAI)" do
    test "parses UTF-8 in local-part" do
      # Japanese characters in local-part
      assert {:ok, result} = AddressParser.parse_addr_spec("用户@example.com")
      assert result.local_part == "用户"
      assert result.domain == "example.com"
    end

    test "parses UTF-8 in domain" do
      # Chinese domain name
      assert {:ok, result} = AddressParser.parse_addr_spec("user@例え.jp")
      assert result.local_part == "user"
      assert result.domain == "例え.jp"
    end

    test "parses UTF-8 in both local-part and domain" do
      assert {:ok, result} = AddressParser.parse_addr_spec("用户@例え.jp")
      assert result.local_part == "用户"
      assert result.domain == "例え.jp"
    end

    test "parses mailbox with UTF-8 address" do
      assert {:ok, result} = AddressParser.parse_mailbox("日本語@example.com")
      assert result.type == :mailbox
      assert result.address == "日本語@example.com"
    end

    test "parses mailbox with UTF-8 display-name and address" do
      assert {:ok, result} = AddressParser.parse_mailbox("田中太郎 <tanaka@例え.jp>")
      assert result.type == :mailbox
      assert result.name == "田中太郎"
      assert result.address == "tanaka@例え.jp"
    end

    test "parses address list with mixed UTF-8 and ASCII" do
      input = "alice@example.com, 田中 <tanaka@例え.jp>, bob@test.com"
      assert {:ok, addrs} = AddressParser.parse_address_list(input)
      assert length(addrs) == 3
      assert Enum.at(addrs, 1).name == "田中"
    end

    test "parses German umlauts in local-part" do
      assert {:ok, result} = AddressParser.parse_addr_spec("müller@example.com")
      assert result.local_part == "müller"
    end

    test "parses Cyrillic characters in local-part" do
      assert {:ok, result} = AddressParser.parse_addr_spec("пользователь@example.com")
      assert result.local_part == "пользователь"
    end

    test "parses Arabic characters in local-part" do
      assert {:ok, result} = AddressParser.parse_addr_spec("مستخدم@example.com")
      assert result.local_part == "مستخدم"
    end

    test "parses emoji in local-part" do
      # Some systems allow emoji in email addresses
      assert {:ok, result} = AddressParser.parse_addr_spec("test😀@example.com")
      assert result.local_part == "test😀"
    end

    test "parses group with UTF-8 display-names" do
      assert {:ok, result} = AddressParser.parse_group("チーム: member@example.com;")
      assert result.type == :group
      assert result.name == "チーム"
    end
  end
end
