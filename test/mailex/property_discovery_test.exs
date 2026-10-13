defmodule Mailex.PropertyDiscoveryTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Mailex.{AddressParser, DateTimeParser, Parser}

  @moduletag :discovery
  @runs String.to_integer(System.get_env("PROPERTY_RUNS", "200"))
  @months ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

  property "date conversion agrees with timestamp arithmetic across midnight" do
    check all(
            date <- calendar_date(),
            hour <- integer(0..23),
            minute <- integer(0..59),
            second <- integer(0..59),
            offset <- one_of([integer(-1439..1439), member_of([1, 60, 330, 840, -720])]),
            separator <- member_of([" ", "\t", " (outer(inner)) ", "\r\n "]),
            max_runs: @runs
          ) do
      time = Time.new!(hour, minute, second)
      raw = date_wire(date, time, offset, separator)
      assert {:ok, parsed} = DateTimeParser.parse(raw)
      local_as_utc = DateTime.new!(date, time)
      expected = DateTime.add(local_as_utc, -offset * 60, :second)
      assert {:ok, actual} = DateTimeParser.to_utc_datetime(parsed)
      assert DateTime.compare(actual, expected) == :eq
      assert {:ok, local} = DateTimeParser.to_datetime(parsed)
      assert DateTime.to_unix(local) == DateTime.to_unix(expected)
      assert {local.hour, local.minute, local.utc_offset} == {hour, minute, offset * 60}
    end
  end

  property "quoted local-parts retain separators as data, not structure" do
    check all(
            local <- text(["a", "@", "b", " ", "\"", "\\", ";", "="], 1),
            domain <- member_of(["example.org", "[a@b]", "[IPv6:2001:db8::1]"]),
            max_runs: @runs
          ) do
      wire = quote_string(local) <> "@" <> domain
      assert {:ok, parsed} = AddressParser.parse_addr_spec(wire)
      assert parsed == %{local_part: local, domain: domain}
      assert {:ok, mailbox} = AddressParser.parse_mailbox(wire)
      assert mailbox.address == local <> "@" <> domain
    end
  end

  property "address lists round trip structured groups and internationalized atoms" do
    check all(
            addresses <- list_of(address(), min_length: 1, max_length: 8),
            separator <- member_of([", ", ",\r\n ", ", (note) "]),
            max_runs: @runs
          ) do
      wire = Enum.map_join(addresses, separator, &address_wire/1)
      assert {:ok, parsed} = AddressParser.parse_address_list(wire)
      assert parsed == addresses

      assert AddressParser.parse_address_list(Enum.map_join(parsed, ", ", &address_wire/1)) ==
               {:ok, addresses}
    end
  end

  property "MIME quoted parameters preserve escapes, punctuation, and Unicode" do
    check all(
            value <- text(["a", "é", "界", "é", ";", "=", "\"", "\\", "(", ")", "\t"]),
            max_runs: @runs
          ) do
      raw =
        "Content-Type: application/octet-stream; name=" <>
          quote_string(value) <>
          "\nContent-Disposition: attachment (note); filename=" <>
          quote_string(value) <>
          "; size=17\n\n"

      assert {:ok, parsed} = Mailex.parse(raw)
      assert parsed.content_type.params["name"] == value
      assert parsed.disposition_params == %{"filename" => value, "size" => "17"}
      assert parsed.filename == value
    end
  end

  property "RFC 2231 continuations decode the whole value in the first segment's charset" do
    check all(
            bytes <- binary(min_length: 1, max_length: 30),
            cut <- integer(0..30),
            reverse? <- boolean(),
            target <- member_of([:disposition, :content_type]),
            max_runs: @runs
          ) do
      cut = rem(cut, byte_size(bytes) + 1)
      <<first::binary-size(cut), last::binary>> = bytes
      # A direct Latin-1 codepoint model, independent of codepagex and URI decoding.
      expected = for <<byte <- bytes>>, into: "", do: <<byte::utf8>>
      params = ["filename*0*=ISO-8859-1''" <> percent(first), "filename*1*=" <> percent(last)]
      params = if reverse?, do: Enum.reverse(params), else: params
      raw = parameter_message(target, params ++ ["filename=wrong", "filename*=UTF-8''also-wrong"])
      assert {:ok, parsed} = Mailex.parse(raw)

      params =
        if target == :disposition, do: parsed.disposition_params, else: parsed.content_type.params

      assert params["filename"] == expected
    end
  end

  property "UTF-8 continuation segments can split a multibyte character" do
    check all(
            value <- text(["é", "界", "🙂", "a", "'", "%"], 1),
            cut <- integer(0..50),
            max_runs: @runs
          ) do
      cut = rem(cut, byte_size(value) + 1)
      <<first::binary-size(cut), last::binary>> = value
      params = ["filename*1*=" <> percent(last), "filename*0*=UTF-8''" <> percent(first)]
      assert {:ok, parsed} = Mailex.parse(parameter_message(:disposition, params))
      assert parsed.filename == value
    end
  end

  property "RFC 2047 mixed B/Q words round trip bytes and ignore only inter-word whitespace" do
    check all(
            values <-
              list_of(text(["é", "界", "🙂", "a", " ", "_", "=", "?", "\\"], 1, 4),
                min_length: 1,
                max_length: 6
              ),
            encodings <- list_of(member_of([:b, :q]), length: length(values)),
            separator <- member_of([" ", "\t", "\r\n "]),
            max_runs: @runs
          ) do
      wire = Enum.zip(values, encodings) |> Enum.map_join(separator, fn {v, e} -> word(v, e) end)
      expected = "prefix " <> Enum.join(values) <> " suffix"
      assert Parser.decode_rfc2047("prefix " <> wire <> " suffix") == expected
      assert {:ok, parsed} = Mailex.parse("Subject: prefix " <> wire <> " suffix\n\n")
      assert parsed.headers["subject"] == expected
    end
  end

  property "plain lookalikes do not lose whitespace during encoded-word decoding" do
    check all(
            separator <- member_of([" ", "\t", "  "]),
            tail <- text(["a", "b", "界"], 1),
            max_runs: @runs
          ) do
      value = "plain?=" <> separator <> "=?plain-" <> tail
      assert Parser.decode_rfc2047(value) == value
    end
  end

  property "binary transfer encodings round trip arbitrary octets and soft line breaks" do
    check all(
            bytes <- binary(max_length: 128),
            width <- member_of([1, 2, 3, 4, 7, 76]),
            eol <- member_of(["\n", "\r\n"]),
            max_runs: @runs
          ) do
      for encoding <- [:base64, :qp] do
        {name, encoded} = transfer(bytes, encoding, width, eol)

        raw =
          "Content-Type: application/octet-stream" <>
            eol <>
            "Content-Transfer-Encoding: " <> name <> eol <> eol <> encoded

        assert {:ok, parsed} = Mailex.parse(raw)
        assert parsed.body == bytes
      end
    end
  end

  property "header histories preserve duplicate order, folding, and derived references" do
    check all(
            history <-
              list_of(tuple({member_of(["X-A", "x-a", "X-B", "References"]), integer(0..3)}),
                min_length: 1,
                max_length: 30
              ),
            max_runs: @runs
          ) do
      # The small key/value pools force interleaved duplicates. Observe every prefix.
      Enum.reduce(history, [], fn operation, prefix ->
        prefix = prefix ++ [operation]

        pairs =
          Enum.map(prefix, fn {k, v} ->
            {k, if(k == "References", do: "<#{v}@example.org>", else: "v#{v}")}
          end)

        expected =
          Enum.group_by(pairs, fn {k, _} -> String.downcase(k) end, &elem(&1, 1))
          |> Map.new(fn {k, vs} -> {k, if(length(vs) == 1, do: hd(vs), else: vs)} end)

        raw = Enum.map_join(pairs, "\r\n", fn {k, v} -> k <> ":\r\n " <> v end) <> "\r\n\r\nbody"
        assert {:ok, parsed} = Mailex.parse(raw)
        assert parsed.headers == expected
        ids = for {"References", v} <- prefix, do: "#{v}@example.org"
        assert parsed.references == if(ids == [], do: nil, else: ids)
        prefix
      end)
    end
  end

  property "multipart delimiter histories agree with an event-state reference model" do
    check all(
            boundary <- member_of(["a", "a.b+c", "outer", "outer-inner"]),
            padding <- member_of(["", " ", "\t "]),
            eol <- member_of(["\n", "\r\n"]),
            prefix <- list_of(event(), max_length: 10),
            suffix <- list_of(event(), max_length: 20),
            max_runs: @runs
          ) do
      # Force near-misses, repeated opens, and content/boundaries after close.
      events =
        prefix ++ [:open, {:data, "one"}, :near, :open, {:data, "two"}, :close, :open] ++ suffix

      raw =
        "Content-Type: multipart/mixed; boundary=" <>
          quote_string(boundary) <>
          eol <>
          eol <>
          Enum.map_join(events, eol, &event_wire(&1, boundary, padding, eol))

      expected = multipart_model(events, boundary)
      assert {:ok, parsed} = Mailex.parse(raw)
      assert Enum.map(parsed.parts, & &1.body) == expected
    end
  end

  property "recursive MIME trees preserve payloads, digest defaults, and related roots" do
    check all(
            tree <- tree(2),
            eol <- member_of(["\n", "\r\n"]),
            max_runs: @runs
          ) do
      assert {:ok, parsed} = Mailex.parse(tree_wire(tree, "b", eol))
      assert tree_view(parsed) == tree_model(tree)
    end
  end

  property "UTF-8 quoted addresses and names preserve codepoints and escapes" do
    check all(
            local <- text(["é", "界", "🙂", "a", "@", "\"", "\\"], 1),
            name <- text(["é", "界", "🙂", "a", "\"", "\\"], 1),
            max_runs: @runs
          ) do
      addr = quote_string(local) <> "@example.org"

      assert AddressParser.parse_addr_spec(addr) ==
               {:ok, %{local_part: local, domain: "example.org"}}

      assert AddressParser.parse_mailbox(quote_string(name) <> " <" <> addr <> ">") ==
               {:ok, %{type: :mailbox, name: name, address: local <> "@example.org"}}
    end
  end

  property "nested Unicode comments reconstruct and strip according to their syntax tree" do
    check all(
            comment <- comment(3),
            quoted <- text(["a", "é", "界", "(", ")", "\"", "\\"]),
            max_runs: @runs
          ) do
      wire = comment_wire(comment)
      assert {:ok, [decoded], "", _, _, _} = Parser.parse_comment(wire)
      assert decoded == comment_model(comment)
      literal = quote_string(quoted)
      assert Parser.strip_comments("a" <> wire <> literal <> wire <> "b") == "a" <> literal <> "b"
      # Comments also flow through the public message-ID extraction path.
      assert {:ok, parsed} = Mailex.parse("Message-ID: " <> wire <> " <a@example.org>\n\n")
      assert parsed.message_id == "a@example.org"
    end
  end

  property "mixed continuation representations preserve raw percent signs and charset" do
    check all(
            prefix <- text(["a", "é", "ø", "ß"], 1),
            suffix <- text(["a", "'", "%", "\"", "\\"]),
            mode <- member_of([:all_encoded, :mixed, :unencoded]),
            reverse? <- boolean(),
            max_runs: @runs
          ) do
      latin1 = for <<cp::utf8 <- prefix>>, into: "", do: <<cp>>

      params =
        case mode do
          :all_encoded ->
            ["filename*0*=ISO-8859-1''" <> percent(latin1), "filename*1*=" <> percent(suffix)]

          :mixed ->
            ["filename*0*=ISO-8859-1''" <> percent(latin1), "filename*1=" <> quote_string(suffix)]

          :unencoded ->
            ["filename*0=" <> quote_string("plain%20"), "filename*1*=" <> percent(suffix)]
        end

      params = if reverse?, do: Enum.reverse(params), else: params
      assert {:ok, parsed} = Mailex.parse(parameter_message(:disposition, params))
      expected = if mode == :unencoded, do: "plain%20" <> suffix, else: prefix <> suffix
      assert parsed.filename == expected
    end
  end

  property "near-valid extended parameters return a result instead of raising" do
    check all(
            bad_escape <- member_of(["%", "%0", "%GG", "%0Z", "%Z0"]),
            surrounding <- text(["a", "b", "%20"]),
            target <- member_of([:disposition, :content_type]),
            max_runs: @runs
          ) do
      raw = parameter_message(target, ["filename*=UTF-8''" <> surrounding <> bad_escape])
      result = Mailex.parse(raw)
      assert match?({:ok, %Mailex.Message{}}, result) or match?({:error, _}, result)
    end
  end

  property "date conversions report unrepresentable dates and leap seconds as errors" do
    check all(
            month <- integer(1..12),
            day <- integer(1..31),
            second <- one_of([integer(0..59), constant(60)]),
            max_runs: @runs
          ) do
      raw = "#{day} #{Enum.at(@months, month - 1)} 2024 12:00:#{pad(second)} +0100"
      assert {:ok, parsed} = DateTimeParser.parse(raw)

      error =
        case {Date.new(2024, month, day), Time.new(12, 0, second)} do
          {{:error, reason}, _} -> {:error, reason}
          {_, {:error, reason}} -> {:error, reason}
          _ -> nil
        end

      if error do
        assert DateTimeParser.to_datetime(parsed) == error
        assert DateTimeParser.to_utc_datetime(parsed) == error
      end
    end
  end

  defp text(alphabet, min_length \\ 0, max_length \\ 12) do
    map(
      list_of(member_of(alphabet), min_length: min_length, max_length: max_length),
      &Enum.join/1
    )
  end

  defp calendar_date do
    map(integer(0..36_524), &Date.add(~D[1950-01-01], &1))
  end

  defp date_wire(date, time, offset, separator) do
    sign = if offset < 0, do: "-", else: "+"
    zone = sign <> pad(div(abs(offset), 60)) <> pad(rem(abs(offset), 60))

    Enum.join(
      [
        Integer.to_string(date.day),
        Enum.at(@months, date.month - 1),
        Integer.to_string(date.year),
        Time.to_string(time),
        zone
      ],
      separator
    )
  end

  defp pad(value), do: value |> Integer.to_string() |> String.pad_leading(2, "0")

  defp quote_string(value) do
    "\"" <> (value |> String.replace("\\", "\\\\") |> String.replace("\"", "\\\"")) <> "\""
  end

  defp mailbox do
    gen all(
          local <- text(["a", "b", "é", "界", "🙂"], 1),
          domain <- member_of(["example.org", "例え.jp"]),
          name <- member_of([nil, "Alice", "A; B", "a\"b", "a\\b"])
        ) do
      %{type: :mailbox, name: name, address: local <> "@" <> domain}
    end
  end

  defp address do
    one_of([
      mailbox(),
      map(list_of(mailbox(), max_length: 4), fn members ->
        %{type: :group, name: "Team", members: members}
      end)
    ])
  end

  defp address_wire(%{type: :mailbox, name: nil, address: addr}), do: addr

  defp address_wire(%{type: :mailbox, name: name, address: addr}),
    do: quote_string(name) <> " <" <> addr <> ">"

  defp address_wire(%{type: :group, name: name, members: members}),
    do: name <> ": " <> Enum.map_join(members, ", ", &address_wire/1) <> ";"

  defp percent(bytes), do: for(<<byte <- bytes>>, into: "", do: "%" <> hex(byte))
  defp hex(byte), do: byte |> Integer.to_string(16) |> String.pad_leading(2, "0")

  defp parameter_message(:disposition, params),
    do: "Content-Disposition: attachment; " <> Enum.join(params, "; ") <> "\n\n"

  defp parameter_message(:content_type, params),
    do: "Content-Type: application/octet-stream; " <> Enum.join(params, "; ") <> "\n\n"

  defp word(value, :b), do: "=?UTF-8?B?" <> Base.encode64(value) <> "?="
  defp word(value, :q), do: "=?UTF-8?Q?" <> qp(value) <> "?="
  defp qp(bytes), do: for(<<byte <- bytes>>, into: "", do: "=" <> hex(byte))

  defp transfer(bytes, :base64, width, eol) do
    encoded =
      Base.encode64(bytes)
      |> String.codepoints()
      |> Enum.chunk_every(width)
      |> Enum.map_join(eol, &Enum.join/1)

    {"base64", encoded}
  end

  defp transfer(bytes, :qp, width, eol) do
    encoded =
      :binary.bin_to_list(bytes)
      |> Enum.chunk_every(width)
      |> Enum.map_join("=" <> eol, fn chunk -> qp(:binary.list_to_bin(chunk)) end)

    {"quoted-printable", encoded}
  end

  defp event,
    do:
      one_of([
        member_of([:open, :close, :near]),
        map(member_of(["x", "y", "", "--other", "x--a"]), &{:data, &1})
      ])

  defp event_wire(:open, boundary, padding, eol),
    do: "--" <> boundary <> padding <> eol <> "Content-Type: text/plain" <> eol

  defp event_wire(:close, boundary, padding, _), do: "--" <> boundary <> "--" <> padding
  defp event_wire(:near, boundary, _, _), do: "--" <> boundary <> "--X"
  defp event_wire({:data, line}, _, _, _), do: line

  defp multipart_model(events, boundary) do
    {state, current, parts} =
      Enum.reduce(events, {:preamble, [], []}, fn
        _, {:closed, current, parts} ->
          {:closed, current, parts}

        :open, {:preamble, _, parts} ->
          {:part, [], parts}

        :open, {:part, current, parts} ->
          {:part, [], parts ++ [Enum.join(current, "\n") |> String.trim_trailing()]}

        :close, {:preamble, _, parts} ->
          {:closed, [], parts}

        :close, {:part, current, parts} ->
          {:closed, [], parts ++ [Enum.join(current, "\n") |> String.trim_trailing()]}

        _, {:preamble, current, parts} ->
          {:preamble, current, parts}

        :near, {:part, current, parts} ->
          {:part, current ++ ["--" <> boundary <> "--X"], parts}

        {:data, line}, {:part, current, parts} ->
          {:part, current ++ [line], parts}
      end)

    if state == :part,
      do: parts ++ [Enum.join(current, "\n") |> String.trim_trailing()],
      else: parts
  end

  defp tree(0), do: map(binary(max_length: 20), &{:leaf, &1})

  defp tree(depth) do
    one_of([
      tree(0),
      map(tree(depth - 1), &{:embedded, &1}),
      map(list_of(tree(depth - 1), min_length: 1, max_length: 3), &{:mixed, &1}),
      map(tree(depth - 1), &{:digest, &1}),
      map(list_of(tree(depth - 1), min_length: 2, max_length: 3), &{:related, &1})
    ])
  end

  defp tree_wire({:leaf, bytes}, _, eol),
    do:
      "Content-Type: application/octet-stream" <>
        eol <> "Content-Transfer-Encoding: base64" <> eol <> eol <> Base.encode64(bytes)

  defp tree_wire({:embedded, child}, path, eol),
    do: "Content-Type: message/rfc822" <> eol <> eol <> tree_wire(child, path <> "m", eol)

  defp tree_wire({:digest, child}, path, eol),
    do:
      "Content-Type: multipart/digest; boundary=" <>
        path <>
        eol <>
        eol <>
        "--" <>
        path <> eol <> eol <> tree_wire(child, path <> "d", eol) <> eol <> "--" <> path <> "--"

  defp tree_wire({kind, children}, path, eol) when kind in [:mixed, :related] do
    start = if kind == :related, do: "; start=\"<1@root>\"", else: ""

    parts =
      children
      |> Enum.with_index()
      |> Enum.map_join(eol, fn {child, i} ->
        "--" <>
          path <>
          eol <> "Content-ID: <#{i}@root>" <> eol <> tree_wire(child, path <> "-#{i}", eol)
      end)

    "Content-Type: multipart/" <>
      Atom.to_string(kind) <>
      "; boundary=" <>
      path <>
      start <>
      eol <>
      eol <>
      parts <> eol <> "--" <> path <> "--"
  end

  defp tree_model({:leaf, bytes}), do: {"application", "octet-stream", bytes}
  defp tree_model({:embedded, child}), do: {"message", "rfc822", [tree_model(child)]}

  defp tree_model({:digest, child}),
    do: {"multipart", "digest", [{"message", "rfc822", [tree_model(child)]}], nil}

  defp tree_model({kind, children}),
    do:
      {"multipart", Atom.to_string(kind), Enum.map(children, &tree_model/1),
       if(kind == :related, do: 1, else: nil)}

  defp tree_view(message) do
    type = message.content_type
    content = if message.parts, do: Enum.map(message.parts, &tree_view/1), else: message.body

    if type.type == "multipart",
      do: {type.type, type.subtype, content, message.related_root_index},
      else: {type.type, type.subtype, content}
  end

  defp comment(0),
    do: list_of(member_of(["a", "é", "界", "🙂", "\\(", "\\)", "\\\\"]), max_length: 6)

  defp comment(depth),
    do:
      list_of(one_of([member_of(["a", "é", "界", "🙂", "\\(", "\\)", "\\\\"]), comment(depth - 1)]),
        max_length: 4
      )

  defp comment_wire(nodes), do: "(" <> Enum.map_join(nodes, &comment_node_wire/1) <> ")"
  defp comment_node_wire(node) when is_list(node), do: comment_wire(node)
  defp comment_node_wire(node), do: node

  defp comment_model(nodes),
    do:
      Enum.map_join(nodes, fn
        node when is_list(node) -> "(" <> comment_model(node) <> ")"
        "\\" <> char -> char
        node -> node
      end)
end
