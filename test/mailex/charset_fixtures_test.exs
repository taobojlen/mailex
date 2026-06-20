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
end
