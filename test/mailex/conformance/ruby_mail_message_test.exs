defmodule Mailex.Conformance.RubyMailMessageTest do
  @moduledoc """
  Conformance tests using Ruby mail gem's error_emails fixtures.

  These tests validate Mailex's ability to gracefully handle malformed and
  edge-case emails from the Ruby mail gem test suite. The fixtures cover:

  - Bad date headers (empty, malformed)
  - Bad/invalid subject encoding
  - Unparseable From/To headers
  - Content-Transfer-Encoding edge cases (7-bit, empty, spam, x-uuencode, etc.)
  - Empty In-Reply-To and group lists
  - Encoding issues (binary, 8bit markers)
  - Missing body/content-disposition
  - Multiple Content-Types and References headers

  Source: https://github.com/mikel/mail/tree/master/spec/fixtures/emails/error_emails
  """

  use ExUnit.Case, async: true

  alias Mailex.TestFixtures

  @cases TestFixtures.load_ruby_mail_cases!()
  @deviations TestFixtures.load_ruby_mail_deviations!()
  @expected_file_count 28

  describe "fixture completeness" do
    test "all #{@expected_file_count} .eml files are present" do
      files = TestFixtures.list_ruby_mail_eml_files!()
      assert length(files) == @expected_file_count
    end

    test "manifest covers all fixture files" do
      files = TestFixtures.list_ruby_mail_eml_files!()
      case_files = @cases |> Enum.map(& &1.file) |> Enum.sort()
      assert case_files == files
    end

    test "all test IDs are unique" do
      ids = Enum.map(@cases, & &1.id)
      assert ids == Enum.uniq(ids)
    end
  end

  for c <- @cases do
    deviation = Map.get(@deviations, c.id)

    if deviation && deviation[:behavior] == :skip do
      @tag :skip
      @tag reason: deviation[:reason]
    end

    @tag :conformance
    @tag :ruby_mail
    @tag category: c.category
    test "#{c.id} (#{c.file})" do
      c = unquote(Macro.escape(c))
      deviation = unquote(Macro.escape(deviation))

      raw = TestFixtures.load_ruby_mail_eml!(c.file)
      result = Mailex.parse(raw)

      assert_expectations(result, c.expect, deviation)
    end
  end

  defp assert_expectations(result, expect, deviation) do
    case expect[:result] do
      :ok ->
        assert {:ok, message} = result
        assert_message_expectations(message, expect, deviation)

      :error ->
        assert {:error, _} = result
    end
  end

  defp assert_message_expectations(message, expect, _deviation) do
    if subject = expect[:subject] do
      assert message.headers["subject"] == subject,
             "Expected subject #{inspect(subject)}, got #{inspect(message.headers["subject"])}"
    end

    if from = expect[:from] do
      assert message.headers["from"] == from
    end

    if content_type = expect[:content_type] do
      {type, subtype} = content_type
      assert message.content_type.type == type
      assert message.content_type.subtype == subtype
    end

    if expect[:has_body] do
      assert message.body != nil and message.body != "",
             "Expected non-empty body"
    end

    if parts_count = expect[:parts_count] do
      assert length(message.parts || []) == parts_count,
             "Expected #{parts_count} parts, got #{length(message.parts || [])}"
    end

    if attachments_count = expect[:attachments_count] do
      actual = count_attachments(message)

      assert actual == attachments_count,
             "Expected #{attachments_count} attachments, got #{actual}"
    end
  end

  defp count_attachments(%{parts: nil}), do: 0

  defp count_attachments(%{parts: parts}) do
    Enum.count(parts, fn part ->
      part.disposition_type == "attachment" or
        part.filename != nil
    end)
  end
end
