defmodule Mailex.Conformance.GenSMTPMessageTest do
  @moduledoc """
  Conformance tests using gen_smtp's .eml fixtures.

  These tests validate Mailex's message parsing against real-world email fixtures
  from the gen_smtp Erlang library. The fixtures cover:

  - Plain text messages (with/without MIME headers)
  - Multipart messages (alternative, mixed)
  - Malformed boundary handling
  - Attachments (text, image, multiple)
  - Nested messages (message/rfc822)
  - Unicode encoding (subjects, bodies, attachment names)

  Source: https://github.com/gen-smtp/gen_smtp/tree/master/test/fixtures
  """

  use ExUnit.Case, async: true

  alias Mailex.TestFixtures

  @cases TestFixtures.load_gen_smtp_cases!()
  @deviations TestFixtures.load_gen_smtp_deviations!()
  @expected_file_count 27

  describe "fixture completeness" do
    test "all #{@expected_file_count} .eml files are present" do
      files = TestFixtures.list_gen_smtp_eml_files!()
      assert length(files) == @expected_file_count
    end

    test "manifest covers all fixture files" do
      files = TestFixtures.list_gen_smtp_eml_files!()
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
    @tag :gen_smtp
    @tag category: c.category
    test "#{c.id} (#{c.file})" do
      c = unquote(Macro.escape(c))
      deviation = unquote(Macro.escape(deviation))

      raw = TestFixtures.load_gen_smtp_eml!(c.file)
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

    if expect[:has_message_rfc822_part] do
      assert has_message_rfc822_part?(message),
             "Expected message/rfc822 part"
    end
  end

  defp count_attachments(%{parts: nil}), do: 0

  defp count_attachments(%{parts: parts}) do
    Enum.count(parts, fn part ->
      part.disposition_type == "attachment" or
        part.filename != nil
    end)
  end

  defp has_message_rfc822_part?(%{parts: nil}), do: false

  defp has_message_rfc822_part?(%{parts: parts}) do
    Enum.any?(parts, fn part ->
      (part.content_type.type == "message" and part.content_type.subtype == "rfc822") or
        has_message_rfc822_part?(part)
    end)
  end
end
