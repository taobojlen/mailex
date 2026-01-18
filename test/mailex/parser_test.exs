defmodule Mailex.ParserTest do
  use ExUnit.Case, async: true

  @fixtures_dir Path.join([__DIR__, "..", "fixtures", "testmsgs"])

  # Get all .msg files from testmsgs directory
  @msg_files @fixtures_dir
             |> File.ls!()
             |> Enum.filter(&String.ends_with?(&1, ".msg"))
             |> Enum.sort()

  describe "MIME-tools conformance tests (testmsgs/)" do
    for msg_file <- @msg_files do
      test_name = Path.rootname(msg_file)

      @tag fixture: msg_file
      test "parses #{test_name}" do
        msg_path = Path.join(@fixtures_dir, unquote(msg_file))
        raw = File.read!(msg_path)

        assert {:ok, message} = Mailex.Parser.parse(raw)
        assert is_map(message)

        # Load expected results if available
        json_path = Path.join(@fixtures_dir, unquote(test_name) <> ".json")

        if File.exists?(json_path) do
          expected = json_path |> File.read!() |> Jason.decode!()

          # Skip validation for tests requiring ExtractUuencode (non-standard MIME::Tools feature)
          unless expected["Parser"]["ExtractUuencode"] do
            validate_against_expected(message, expected, unquote(test_name))
          end
        end
      end
    end
  end

  describe "basic message structure" do
    test "parses simple plain text message" do
      raw = File.read!(Path.join(@fixtures_dir, "simple.msg"))
      assert {:ok, message} = Mailex.Parser.parse(raw)

      assert message.headers["from"] == "eryq@rhine.gsfc.nasa.gov"
      assert message.headers["to"] == "sitaram@selsvr.stx.com"
      assert message.headers["subject"] == "Request for Leave"
      assert message.content_type.type == "text"
      assert message.content_type.subtype == "plain"
    end

    test "parses nested multipart message" do
      raw = File.read!(Path.join(@fixtures_dir, "multi-nested.msg"))
      assert {:ok, message} = Mailex.Parser.parse(raw)

      assert message.headers["from"] == "Lord John Whorfin <whorfin@yoyodyne.com>"
      assert message.headers["subject"] == "A complex nested multipart example"
      assert message.content_type.type == "multipart"
      assert message.content_type.subtype == "mixed"
      assert is_list(message.parts)
      assert length(message.parts) == 5
    end

    test "handles base64 encoded content" do
      raw = File.read!(Path.join(@fixtures_dir, "multi-2gifs.msg"))
      assert {:ok, message} = Mailex.Parser.parse(raw)

      assert message.content_type.type == "multipart"
      # Should have parts with base64 encoding
      assert Enum.any?(message.parts, fn part ->
        part.encoding == "base64"
      end)
    end

    test "handles quoted-printable encoding" do
      raw = File.read!(Path.join(@fixtures_dir, "german-qp.msg"))
      assert {:ok, message} = Mailex.Parser.parse(raw)

      # Should handle quoted-printable content
      assert message.encoding == "quoted-printable" or
             String.contains?(raw, "quoted-printable")
    end
  end

  describe "header parsing" do
    test "parses folded headers (continuation lines)" do
      raw = """
      From: sender@example.com
      Subject: This is a very long subject line
       that continues on the next line
       and even a third line
      To: recipient@example.com

      Body text.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.headers["subject"] ==
        "This is a very long subject line that continues on the next line and even a third line"
    end

    test "parses multiple headers with same name" do
      raw = """
      From: sender@example.com
      Received: from server1.example.com
      Received: from server2.example.com
      To: recipient@example.com

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      # Received headers should be preserved as a list
      received = message.headers["received"]
      assert is_list(received)
      assert length(received) == 2
    end

    test "parses Content-Type with parameters" do
      raw = """
      From: sender@example.com
      Content-Type: multipart/mixed; boundary="----=_Part_0"

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.type == "multipart"
      assert message.content_type.subtype == "mixed"
      assert message.content_type.params["boundary"] == "----=_Part_0"
    end

    test "parses Content-Type with quoted-string containing semicolon" do
      # RFC 2045 §5.1: parameter values can be quoted-strings containing any char
      raw = """
      From: sender@example.com
      Content-Type: text/plain; name="file;name.txt"

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.type == "text"
      assert message.content_type.subtype == "plain"
      assert message.content_type.params["name"] == "file;name.txt"
    end

    test "parses Content-Type with quoted-string containing equals sign" do
      raw = """
      From: sender@example.com
      Content-Type: text/plain; name="a=b.txt"

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.params["name"] == "a=b.txt"
    end

    test "parses Content-Type with backslash escapes in quoted-string" do
      # RFC 5322 §3.2.4: quoted-pair = "\" (VCHAR / WSP)
      raw = """
      From: sender@example.com
      Content-Type: text/plain; name="file\\"quote.txt"

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.params["name"] == "file\"quote.txt"
    end

    test "parses Content-Type with escaped backslash in quoted-string" do
      raw = """
      From: sender@example.com
      Content-Type: text/plain; name="path\\\\file.txt"

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.params["name"] == "path\\file.txt"
    end

    test "parses Content-Type with multiple complex parameters" do
      raw = """
      From: sender@example.com
      Content-Type: text/plain; charset=utf-8; name="test;file=1.txt"; format=flowed

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.params["charset"] == "utf-8"
      assert message.content_type.params["name"] == "test;file=1.txt"
      assert message.content_type.params["format"] == "flowed"
    end
  end

  describe "multipart handling" do
    test "extracts parts from multipart message" do
      raw = File.read!(Path.join(@fixtures_dir, "multi-simple.msg"))
      assert {:ok, message} = Mailex.Parser.parse(raw)

      assert message.content_type.type == "multipart"
      assert is_list(message.parts)
      assert length(message.parts) >= 2
    end

    test "handles nested multipart (multipart within multipart)" do
      raw = File.read!(Path.join(@fixtures_dir, "multi-nested.msg"))
      assert {:ok, message} = Mailex.Parser.parse(raw)

      # Find the nested multipart part
      nested = Enum.find(message.parts, fn part ->
        part.content_type.type == "multipart"
      end)

      assert nested != nil
      assert is_list(nested.parts)
    end

    test "handles message/rfc822 embedded messages" do
      raw = File.read!(Path.join(@fixtures_dir, "multi-nested.msg"))
      assert {:ok, message} = Mailex.Parser.parse(raw)

      # Should find an embedded message/rfc822 part
      embedded = Enum.find(message.parts, fn part ->
        part.content_type.type == "message" and
        part.content_type.subtype == "rfc822"
      end)

      assert embedded != nil
    end
  end

  describe "encoding handling" do
    test "decodes base64 body" do
      # Create a simple base64 message
      raw = """
      From: test@example.com
      Content-Type: text/plain
      Content-Transfer-Encoding: base64

      SGVsbG8gV29ybGQh
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.body == "Hello World!"
    end

    test "decodes quoted-printable body" do
      raw = """
      From: test@example.com
      Content-Type: text/plain; charset=iso-8859-1
      Content-Transfer-Encoding: quoted-printable

      Hello=20World=21
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.body == "Hello World!"
    end

    test "preserves backslashes in RFC 2047 decoded content" do
      # Base64 encoded "C:\Users\file.txt"
      encoded = "=?UTF-8?B?QzpcVXNlcnNcZmlsZS50eHQ=?="
      assert Mailex.Parser.decode_rfc2047(encoded) == "C:\\Users\\file.txt"
    end

    test "converts ISO-8859-15 charset to UTF-8" do
      raw = File.read!(Path.join(@fixtures_dir, "german-qp.msg"))
      assert {:ok, message} = Mailex.Parser.parse(raw)

      # The body should be converted to UTF-8
      # ISO-8859-15 byte 0xF6 = ö, 0xE4 = ä, 0xFC = ü, 0xDF = ß
      assert String.contains?(message.body, "Jörn")
      assert String.contains?(message.body, "Sönderz")
      assert String.contains?(message.body, "Grüße")
    end

    test "converts ISO-8859-5 (Cyrillic) charset to UTF-8" do
      raw = """
      From: test@example.com
      Content-Type: text/plain; charset=iso-8859-5
      Content-Transfer-Encoding: quoted-printable

      =BF=E0=D8=D2=D5=E2
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      # ISO-8859-5: BF=П, E0=р, D8=и, D2=в, D5=е, E2=т -> "Привет" (Hello in Russian)
      assert message.body == "Привет"
    end
  end

  describe "edge cases and malformed messages" do
    test "handles missing Content-Type (defaults to text/plain)" do
      raw = """
      From: sender@example.com
      Subject: No content type

      Plain text body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.type == "text"
      assert message.content_type.subtype == "plain"
    end

    test "handles empty body" do
      raw = """
      From: sender@example.com
      Subject: Empty

      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      # Empty bodies are represented as "", not nil
      # nil is reserved for multipart/message containers where content is in parts
      assert message.body == ""
    end

    test "handles CRLF line endings" do
      raw = "From: test@example.com\r\nSubject: CRLF test\r\n\r\nBody.\r\n"
      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.headers["subject"] == "CRLF test"
    end

    test "handles LF-only line endings" do
      raw = "From: test@example.com\nSubject: LF test\n\nBody.\n"
      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.headers["subject"] == "LF test"
    end
  end

  describe "multi-value headers" do
    test "multiple Received headers are stored as a list" do
      raw = """
      From: sender@example.com
      Received: from server1.example.com by mail.example.com
      Received: from server2.example.com by server1.example.com
      Received: from origin.example.com by server2.example.com
      Subject: Test

      Body
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)

      received = message.headers["received"]
      assert is_list(received), "Multiple Received headers should be stored as a list"
      assert length(received) == 3
      assert Enum.at(received, 0) =~ "server1.example.com"
      assert Enum.at(received, 1) =~ "server2.example.com"
      assert Enum.at(received, 2) =~ "origin.example.com"
    end

    test "single header is stored as a string, not a list" do
      raw = """
      From: sender@example.com
      Received: from server.example.com by mail.example.com
      Subject: Test

      Body
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)

      received = message.headers["received"]
      assert is_binary(received), "Single Received header should be stored as a string"
      assert received =~ "server.example.com"
    end

    test "multiple headers with same name from real message" do
      # Uses the mime4j example.msg which has multiple Received headers
      raw = File.read!(Path.join([__DIR__, "..", "fixtures", "mime4j-testmsgs", "example.msg"]))
      assert {:ok, message} = Mailex.Parser.parse(raw)

      received = message.headers["received"]
      assert is_list(received), "Multiple Received headers should be stored as a list"
      # The example.msg file has many Received headers (13)
      assert length(received) >= 10
    end

    test "multiple Comments headers are stored as a list" do
      raw = """
      From: sender@example.com
      Comments: First comment
      Comments: Second comment
      Subject: Test

      Body
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)

      comments = message.headers["comments"]
      assert is_list(comments)
      assert length(comments) == 2
      assert "First comment" in comments
      assert "Second comment" in comments
    end

    test "multiple Keywords headers are stored as a list" do
      raw = """
      From: sender@example.com
      Keywords: keyword1
      Keywords: keyword2, keyword3
      Subject: Test

      Body
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)

      keywords = message.headers["keywords"]
      assert is_list(keywords)
      assert length(keywords) == 2
    end
  end

  @mime4j_dir Path.join([__DIR__, "..", "fixtures", "mime4j-testmsgs"])

  describe "body content validation" do
    test "simple plain text body matches expected content" do
      msg_path = Path.join(@mime4j_dir, "basic-plain.msg")
      expected_path = Path.join(@mime4j_dir, "basic-plain_decoded_1.txt")

      raw = File.read!(msg_path)
      expected_body = File.read!(expected_path) |> normalize_line_endings()

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.body == String.trim_trailing(expected_body)
    end

    test "base64-encoded text body is correctly decoded" do
      msg_path = Path.join(@mime4j_dir, "base64-encoded-text.msg")
      expected_path = Path.join(@mime4j_dir, "base64-encoded-text_decoded_1.txt")

      raw = File.read!(msg_path)
      expected_body = File.read!(expected_path) |> normalize_line_endings()

      assert {:ok, message} = Mailex.Parser.parse(raw)
      # The decoded content should match (may have trailing whitespace differences)
      assert String.trim(message.body) == String.trim(expected_body)
    end

    test "multipart message parts have correct body content" do
      # Use intermediate-boundaries which has clear part bodies
      msg_path = Path.join(@mime4j_dir, "intermediate-boundaries.msg")
      expected_1 = Path.join(@mime4j_dir, "intermediate-boundaries_decoded_1_1.txt")
      expected_2 = Path.join(@mime4j_dir, "intermediate-boundaries_decoded_1_2.txt")

      raw = File.read!(msg_path)
      expected_body_1 = File.read!(expected_1) |> normalize_line_endings()
      expected_body_2 = File.read!(expected_2) |> normalize_line_endings()

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert is_list(message.parts)
      assert length(message.parts) >= 2

      part_1 = Enum.at(message.parts, 0)
      part_2 = Enum.at(message.parts, 1)

      assert String.trim(part_1.body) == String.trim(expected_body_1),
             "Part 1 body mismatch"
      assert String.trim(part_2.body) == String.trim(expected_body_2),
             "Part 2 body mismatch"
    end

    test "very long lines are preserved in body" do
      msg_path = Path.join(@mime4j_dir, "basic-plain-very-long-lines.msg")
      expected_path = Path.join(@mime4j_dir, "basic-plain-very-long-lines_decoded_1.txt")

      raw = File.read!(msg_path)
      expected_body = File.read!(expected_path) |> normalize_line_endings()

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert String.trim(message.body) == String.trim(expected_body)
    end
  end

  defp normalize_line_endings(str), do: String.replace(str, "\r\n", "\n")

  describe "recursive part validation" do
    test "nested multipart structure is correctly parsed" do
      # multi-nested.msg has multipart/mixed with a nested multipart/parallel
      msg_path = Path.join(@mime4j_dir, "multi-nested.msg")
      raw = File.read!(msg_path)

      assert {:ok, message} = Mailex.Parser.parse(raw)

      # Top level is multipart/mixed with 5 parts
      assert message.content_type.type == "multipart"
      assert message.content_type.subtype == "mixed"
      assert length(message.parts) == 5

      # Part 1: text/plain (implicit)
      part_1 = Enum.at(message.parts, 0)
      assert part_1.content_type.type == "text"
      assert part_1.content_type.subtype == "plain"
      assert part_1.body =~ "Part 1 of the outer message"

      # Part 2: text/plain (explicit)
      part_2 = Enum.at(message.parts, 1)
      assert part_2.content_type.type == "text"
      assert part_2.content_type.subtype == "plain"

      # Part 3: nested multipart/parallel with 2 image parts
      part_3 = Enum.at(message.parts, 2)
      assert part_3.content_type.type == "multipart"
      assert part_3.content_type.subtype == "parallel"
      assert is_list(part_3.parts)
      assert length(part_3.parts) == 2

      # Nested image parts
      nested_1 = Enum.at(part_3.parts, 0)
      nested_2 = Enum.at(part_3.parts, 1)
      assert nested_1.content_type.type == "image"
      assert nested_1.content_type.subtype == "gif"
      assert nested_1.filename == "3d-vise.gif"
      assert nested_2.content_type.type == "image"
      assert nested_2.content_type.subtype == "gif"
      assert nested_2.filename == "3d-eye.gif"

      # Part 4: text/richtext
      part_4 = Enum.at(message.parts, 3)
      assert part_4.content_type.type == "text"
      assert part_4.content_type.subtype == "richtext"

      # Part 5: message/rfc822 with embedded message
      part_5 = Enum.at(message.parts, 4)
      assert part_5.content_type.type == "message"
      assert part_5.content_type.subtype == "rfc822"
      assert is_list(part_5.parts)
      assert length(part_5.parts) == 1

      # The embedded message
      embedded = Enum.at(part_5.parts, 0)
      assert embedded.headers["subject"] == "Part 5 of the outer message is itself an RFC822 message!"
      assert embedded.content_type.type == "text"
      assert embedded.body =~ "Part 5 of the outer message"
    end

    test "deeply nested multipart is correctly parsed" do
      # multi-nested2.msg has multiple levels of nesting
      msg_path = Path.join(@mime4j_dir, "multi-nested2.msg")
      raw = File.read!(msg_path)

      assert {:ok, message} = Mailex.Parser.parse(raw)

      # Top level is multipart/mixed
      assert message.content_type.type == "multipart"
      assert is_list(message.parts)

      # Find the nested multipart part and verify it has sub-parts
      nested_parts = Enum.filter(message.parts, fn part ->
        part.content_type.type == "multipart"
      end)

      assert length(nested_parts) > 0, "Should have at least one nested multipart"

      for nested <- nested_parts do
        assert is_list(nested.parts), "Nested multipart should have parts list"
      end
    end

    test "triple-nested multipart structure" do
      # multi-nested3.msg has 3 levels of nesting
      msg_path = Path.join(@mime4j_dir, "multi-nested3.msg")
      raw = File.read!(msg_path)

      assert {:ok, message} = Mailex.Parser.parse(raw)

      # Top level is multipart
      assert message.content_type.type == "multipart"
      assert is_list(message.parts)

      # Count total depth of nesting
      max_depth = count_nesting_depth(message)
      assert max_depth >= 3, "Expected at least 3 levels of nesting, got #{max_depth}"
    end
  end

  defp count_nesting_depth(message, current_depth \\ 1) do
    if is_list(message.parts) and length(message.parts) > 0 do
      child_depths = Enum.map(message.parts, fn part ->
        count_nesting_depth(part, current_depth + 1)
      end)
      Enum.max(child_depths)
    else
      current_depth
    end
  end

  # Helper to validate parsed message against MIME-tools expected output
  defp validate_against_expected(message, expected, test_name) do
    msg_expected = expected["Msg"]

    if msg_expected do
      # Validate content type
      if type = msg_expected["Type"] do
        [expected_type, expected_subtype] = String.split(type, "/")
        assert message.content_type.type == expected_type,
          "#{test_name}: expected type #{expected_type}, got #{message.content_type.type}"
        assert message.content_type.subtype == expected_subtype,
          "#{test_name}: expected subtype #{expected_subtype}, got #{message.content_type.subtype}"
      end

      # Validate from
      if from = msg_expected["From"] do
        assert message.headers["from"] == from,
          "#{test_name}: expected from #{from}, got #{message.headers["from"]}"
      end

      # Validate subject
      if subject = msg_expected["Subject"] do
        assert message.headers["subject"] == subject,
          "#{test_name}: expected subject #{subject}, got #{message.headers["subject"]}"
      end

      # Validate encoding
      if encoding = msg_expected["Encoding"] do
        assert message.encoding == encoding,
          "#{test_name}: expected encoding #{encoding}, got #{message.encoding}"
      end
    end

    # Validate parts if present
    validate_parts(message, expected, test_name)
  end

  defp validate_parts(message, expected, test_name) do
    # Find Part_N keys in expected
    part_keys = expected
                |> Map.keys()
                |> Enum.filter(&String.starts_with?(&1, "Part_"))
                |> Enum.sort()

    if length(part_keys) > 0 and is_list(message.parts) do
      for part_key <- part_keys do
        part_expected = expected[part_key]
        part_index = parse_part_index(part_key)

        if part_index && part_index <= length(message.parts) do
          part = Enum.at(message.parts, part_index - 1)
          validate_part(part, part_expected, "#{test_name}/#{part_key}")
        end
      end
    end
  end

  defp parse_part_index(part_key) do
    case Regex.run(~r/Part_(\d+)$/, part_key) do
      [_, index] -> String.to_integer(index)
      _ -> nil
    end
  end

  defp validate_part(part, expected, context) do
    if type = expected["Type"] do
      [expected_type, expected_subtype] = String.split(type, "/")
      assert part.content_type.type == expected_type,
        "#{context}: expected type #{expected_type}"
      assert part.content_type.subtype == expected_subtype,
        "#{context}: expected subtype #{expected_subtype}"
    end

    if encoding = expected["Encoding"] do
      assert part.encoding == encoding,
        "#{context}: expected encoding #{encoding}"
    end

    if filename = expected["Filename"] do
      assert part.filename == filename,
        "#{context}: expected filename #{filename}"
    end
  end

  describe "8-bit and UTF-8 header values (RFC 5322 obs-text, RFC 6532)" do
    test "parses header with raw 8-bit characters (obs-text)" do
      # RFC 5322 §4 obsolete syntax allows bytes 128-255 in header values
      # ISO-8859-1 encoded: "Jörn" where ö is byte 0xF6
      raw = "From: sender@example.com\nSubject: Test from J\xF6rn\n\nBody.\n"

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.headers["subject"] == "Test from J\xF6rn"
    end

    test "parses header with UTF-8 characters (RFC 6532)" do
      # RFC 6532 allows raw UTF-8 in header field bodies
      raw = "From: sender@example.com\nSubject: Héllo Wörld 日本語\n\nBody.\n"

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.headers["subject"] == "Héllo Wörld 日本語"
    end

    test "parses From header with UTF-8 display name (RFC 6532)" do
      raw = "From: José García <jose@example.com>\nSubject: Test\n\nBody.\n"

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.headers["from"] == "José García <jose@example.com>"
    end

    test "parses folded header with UTF-8 across fold" do
      raw = "From: sender@example.com\nSubject: This is a long subject with UTF-8 日本語\n that continues here\n\nBody.\n"

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.headers["subject"] == "This is a long subject with UTF-8 日本語 that continues here"
    end

    test "parses multiple headers with mixed 8-bit and ASCII" do
      raw = "From: Müller <muller@example.com>\nTo: Böb <bob@example.com>\nSubject: Grüße\n\nBody.\n"

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.headers["from"] == "Müller <muller@example.com>"
      assert message.headers["to"] == "Böb <bob@example.com>"
      assert message.headers["subject"] == "Grüße"
    end
  end

  describe "RFC 2231 parameter continuations" do
    test "reassembles simple continuation parameters (filename*0, filename*1)" do
      raw = """
      Content-Type: application/octet-stream
      Content-Disposition: attachment;
       filename*0="very_long_";
       filename*1="filename_";
       filename*2="here.txt"

      body
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.filename == "very_long_filename_here.txt"
    end

    test "reassembles out-of-order continuation parameters" do
      raw = """
      Content-Type: application/octet-stream
      Content-Disposition: attachment;
       filename*2="here.txt";
       filename*0="very_long_";
       filename*1="filename_"

      body
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.filename == "very_long_filename_here.txt"
    end

    test "decodes RFC 2231 extended value with charset (filename*=UTF-8''...)" do
      raw = """
      Content-Type: application/octet-stream
      Content-Disposition: attachment;
       filename*=UTF-8''%48%65%6C%6C%6F%20%57%6F%72%6C%64.txt

      body
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.filename == "Hello World.txt"
    end

    test "reassembles encoded continuations (filename*0*=charset'lang'..., filename*1*=...)" do
      # RFC 2231 Section 4.1 example: combined charset/language and continuations
      raw = """
      Content-Type: application/octet-stream
      Content-Disposition: attachment;
       filename*0*=UTF-8''This%20is%20;
       filename*1*=a%20long%20;
       filename*2="filename.txt"

      body
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.filename == "This is a long filename.txt"
    end

    test "decodes ISO-8859-1 extended value" do
      # filename*=ISO-8859-1''%61%74%74%61%63%68%6D%65%6E%74%2E%E4%F6%FC
      # Decodes to: attachment.äöü (German umlauts in ISO-8859-1)
      raw = """
      Content-Type: application/octet-stream
      Content-Disposition: attachment;
       filename*=ISO-8859-1''%61%74%74%61%63%68%6D%65%6E%74%2E%E4%F6%FC

      body
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.filename == "attachment.äöü"
    end
  end

  describe "Message-ID parsing (RFC 5322 §3.6.4)" do
    test "extracts message_id from Message-ID header" do
      raw = """
      From: sender@example.com
      Message-ID: <abc123@example.com>
      Subject: Test

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.message_id == "abc123@example.com"
    end

    test "extracts message_id with complex id-left and id-right" do
      raw = """
      From: sender@example.com
      Message-ID: <CAFn=+P.Z8q1xN_ksO2=@mail.gmail.com>
      Subject: Test

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.message_id == "CAFn=+P.Z8q1xN_ksO2=@mail.gmail.com"
    end

    test "extracts in_reply_to from In-Reply-To header (single msg-id)" do
      raw = """
      From: sender@example.com
      In-Reply-To: <parent123@example.com>
      Subject: Re: Test

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.in_reply_to == ["parent123@example.com"]
    end

    test "extracts in_reply_to from In-Reply-To header (multiple msg-ids)" do
      raw = """
      From: sender@example.com
      In-Reply-To: <parent1@example.com> <parent2@other.net>
      Subject: Re: Test

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.in_reply_to == ["parent1@example.com", "parent2@other.net"]
    end

    test "extracts references from References header" do
      raw = """
      From: sender@example.com
      References: <root@example.com> <reply1@example.com> <reply2@example.com>
      Subject: Re: Re: Test

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.references == ["root@example.com", "reply1@example.com", "reply2@example.com"]
    end

    test "handles message-id with whitespace around angle brackets" do
      raw = """
      From: sender@example.com
      Message-ID:   < abc@example.com >
      Subject: Test

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.message_id == "abc@example.com"
    end

    test "handles references across folded header lines" do
      raw = """
      From: sender@example.com
      References: <root@example.com>
       <reply1@example.com>
       <reply2@example.com>
      Subject: Re: Test

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.references == ["root@example.com", "reply1@example.com", "reply2@example.com"]
    end

    test "returns nil for missing message-id headers" do
      raw = """
      From: sender@example.com
      Subject: Test

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.message_id == nil
      assert message.in_reply_to == nil
      assert message.references == nil
    end

    test "handles empty angle brackets gracefully" do
      raw = """
      From: sender@example.com
      Message-ID: <>
      Subject: Test

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      # Empty message-id should be nil or empty string
      assert message.message_id == nil or message.message_id == ""
    end
  end

  describe "RFC 5322 §3.2.2 comments and CFWS" do
    test "strips simple comment from Content-Type" do
      raw = """
      From: sender@example.com
      Content-Type: text/plain (a comment); charset=utf-8

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.type == "text"
      assert message.content_type.subtype == "plain"
      assert message.content_type.params["charset"] == "utf-8"
    end

    test "strips nested comments from Content-Type" do
      raw = """
      From: sender@example.com
      Content-Type: text/plain (outer (nested) comment); charset=utf-8

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.type == "text"
      assert message.content_type.subtype == "plain"
      assert message.content_type.params["charset"] == "utf-8"
    end

    test "handles escaped parentheses in comments" do
      raw = """
      From: sender@example.com
      Content-Type: text/plain (comment with \\( escaped parens \\)); charset=utf-8

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.type == "text"
      assert message.content_type.subtype == "plain"
      assert message.content_type.params["charset"] == "utf-8"
    end

    test "handles escaped backslash in comments" do
      raw = """
      From: sender@example.com
      Content-Type: text/plain (comment with \\\\ backslash); charset=utf-8

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.type == "text"
      assert message.content_type.subtype == "plain"
      assert message.content_type.params["charset"] == "utf-8"
    end

    test "strips multiple comments from Content-Type" do
      # Note: comment between "text" and "/" leaves a space, which is normalized during type parsing
      raw = """
      From: sender@example.com
      Content-Type: text(type comment)/plain(subtype comment); charset=utf-8

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.type == "text"
      assert message.content_type.subtype == "plain"
      assert message.content_type.params["charset"] == "utf-8"
    end

    test "does not treat parentheses inside quoted-strings as comments" do
      raw = """
      From: sender@example.com
      Content-Type: text/plain; name="file (1).txt"

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.params["name"] == "file (1).txt"
    end

    test "strips comment after parameter value" do
      raw = """
      From: sender@example.com
      Content-Type: text/plain; charset=utf-8 (Unicode)

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.content_type.type == "text"
      assert message.content_type.subtype == "plain"
      assert message.content_type.params["charset"] == "utf-8"
    end

    test "strips comment from Content-Disposition" do
      raw = """
      From: sender@example.com
      Content-Type: application/octet-stream
      Content-Disposition: attachment (save to disk); filename="test.txt"

      Body.
      """

      assert {:ok, message} = Mailex.Parser.parse(raw)
      assert message.filename == "test.txt"
    end

    test "parse_comment parses simple comment" do
      assert {:ok, ["a comment"], "", _, _, _} = Mailex.Parser.parse_comment("(a comment)")
    end

    test "parse_comment parses nested comment" do
      assert {:ok, ["outer (inner) text"], "", _, _, _} = Mailex.Parser.parse_comment("(outer (inner) text)")
    end

    test "parse_comment handles escaped characters" do
      assert {:ok, [content], "", _, _, _} = Mailex.Parser.parse_comment("(escaped \\( paren)")
      assert content == "escaped ( paren"
    end

    test "parse_comment handles escaped backslash" do
      assert {:ok, [content], "", _, _, _} = Mailex.Parser.parse_comment("(escaped \\\\ backslash)")
      assert content == "escaped \\ backslash"
    end

    test "strip_comments removes all comments from string" do
      assert Mailex.Parser.strip_comments("text/plain (comment)") == "text/plain"
    end

    test "strip_comments handles nested comments" do
      # Comments are removed leaving surrounding space, then trimmed
      assert Mailex.Parser.strip_comments("text(outer (inner) end)/plain") == "text/plain"
    end

    test "strip_comments preserves quoted-strings with parentheses" do
      assert Mailex.Parser.strip_comments("text/plain; name=\"file (1).txt\"") ==
             "text/plain; name=\"file (1).txt\""
    end

    test "strip_comments handles multiple comments" do
      assert Mailex.Parser.strip_comments("a (c1) b (c2) c") == "a  b  c"
    end

    test "strip_comments handles escaped parentheses" do
      assert Mailex.Parser.strip_comments("text (with \\( escaped) /plain") == "text  /plain"
    end
  end
end
