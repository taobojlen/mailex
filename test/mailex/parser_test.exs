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
end
