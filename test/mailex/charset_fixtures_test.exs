defmodule Mailex.CharsetFixturesTest do
  use ExUnit.Case, async: true

  # Real-world-style messages in legacy charsets. The fixtures use synthetic
  # content but exercise the same decoding paths that previously left raw,
  # non-UTF-8 bytes in the parsed result.
  #
  # These rely on the Windows codepages being compiled into codepagex; see
  # config/config.exs.
  @charsets_dir Path.join([__DIR__, "..", "fixtures", "charsets"])

  defp parse_fixture!(name) do
    @charsets_dir
    |> Path.join(name)
    |> File.read!()
    |> Mailex.parse!()
  end

  test "windows-1252 RFC 2047 subject is decoded to valid UTF-8" do
    message = parse_fixture!("windows-1252-subject.eml")

    subject = message.headers["subject"]
    assert String.valid?(subject)
    # 0x97 -> em dash, 0x92 -> right single quote
    assert subject == "Your weekly digest — what’s new"
  end

  test "windows-1252 body with raw 8-bit bytes is decoded to valid UTF-8" do
    # The fixture contains literal cp1252 bytes (0x92/0x93/0x94/0x97) and is not
    # valid UTF-8 on disk.
    refute String.valid?(File.read!(Path.join(@charsets_dir, "windows-1252-body-8bit.eml")))

    message = parse_fixture!("windows-1252-body-8bit.eml")

    assert String.valid?(message.body)
    assert String.trim(message.body) == "Save 50% today — don’t miss our “biggest” sale!"
  end

  test "windows-1251 (Cyrillic) subject and body are decoded to valid UTF-8" do
    message = parse_fixture!("windows-1251-cyrillic.eml")

    assert String.valid?(message.headers["subject"])
    assert message.headers["subject"] == "Привет"
    assert String.valid?(message.body)
    assert String.trim(message.body) == "Привет, мир!"
  end

  test "supported legacy charset labels decode headers and bodies to their Unicode characters" do
    # Fixed mapping witnesses, independently checked against Python's standard codecs.
    iso_examples = [
      {"iso-8859-1", 0xE9, "é"},
      {"iso-8859-2", 0xA1, "Ą"},
      {"iso-8859-3", 0xA1, "Ħ"},
      {"iso-8859-4", 0xA2, "ĸ"},
      {"iso-8859-5", 0xB0, "А"},
      {"iso-8859-6", 0xC7, "ا"},
      {"iso-8859-7", 0xC1, "Α"},
      {"iso-8859-8", 0xE0, "א"},
      {"iso-8859-9", 0xD0, "Ğ"},
      {"iso-8859-10", 0xA2, "Ē"},
      {"iso-8859-11", 0xA1, "ก"},
      {"iso-8859-13", 0xC1, "Į"},
      {"iso-8859-14", 0xA1, "Ḃ"},
      {"iso-8859-15", 0xA4, "€"},
      {"iso-8859-16", 0xAA, "Ș"}
    ]

    windows_examples = [
      {1250, 0xA5, "Ą"},
      {1251, 0xC0, "А"},
      {1252, 0x80, "€"},
      {1253, 0xC1, "Α"},
      {1254, 0xD0, "Ğ"},
      {1255, 0xE0, "א"},
      {1256, 0xC7, "ا"},
      {1257, 0xC1, "Į"},
      {1258, 0xD5, "Ơ"}
    ]

    aliases =
      for {number, byte, expected} <- windows_examples,
          label <- ["windows-#{number}", "cp#{number}"],
          do: {label, byte, expected}

    for {charset, byte, character} <- iso_examples ++ aliases do
      label = charset |> String.upcase() |> String.replace("-", "_")
      bytes = "left " <> <<byte>> <> " right"
      expected = "left " <> character <> " right"
      encoded = Base.encode64(bytes)

      raw =
        "Subject: =?#{label}?B?#{encoded}?=\r\n" <>
          "Content-Type: text/plain; charset=#{label}\r\n" <>
          "Content-Transfer-Encoding: base64\r\n\r\n#{encoded}"

      assert {:ok, message} = Mailex.parse(raw)
      assert message.headers["subject"] == expected, "subject charset #{label}"
      assert message.body == expected, "body charset #{label}"
    end
  end

  test "failed or unknown charset conversion preserves the decoded bytes" do
    # 0xA5 has no character assignment in ISO-8859-3.
    bytes = "left " <> <<0xA5>> <> " right"
    encoded = Base.encode64(bytes)

    for charset <- ["iso-8859-3", "unknown-charset"] do
      raw =
        "Subject: =?#{charset}?B?#{encoded}?=\n" <>
          "Content-Type: text/plain; charset=#{charset}\n" <>
          "Content-Transfer-Encoding: base64\n\n#{encoded}"

      assert {:ok, message} = Mailex.parse(raw)
      assert message.headers["subject"] == bytes
      assert message.body == bytes
    end
  end
end
