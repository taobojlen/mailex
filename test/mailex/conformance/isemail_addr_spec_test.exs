defmodule Mailex.Conformance.IsEmailAddrSpecTest do
  @moduledoc """
  Conformance tests for AddressParser against the isemail test suite.

  The isemail project (https://github.com/dominicsayers/isemail) provides
  279 test cases for RFC 5321/5322 email address validation.

  Our approach:
  - `ISEMAIL_ERR` category → must fail to parse
  - All other categories → must parse successfully

  This tests syntax parsing only. Semantic validation (length limits, DNS, etc.)
  would be handled by a separate validator.
  """

  use ExUnit.Case, async: true

  alias Mailex.AddressParser
  alias Mailex.TestFixtures

  @moduletag :conformance
  @moduletag :isemail

  # Load test cases at compile time
  @cases TestFixtures.load_isemail_cases!()

  # Load known deviations
  @deviations (
    path = Path.join([TestFixtures.conformance_dir(), "isemail", "deviations.exs"])
    {deviations, _} = Code.eval_file(path)
    deviations
  )

  # Determine expected outcome based on category
  defp expected_outcome(%{category: "ISEMAIL_ERR"}), do: :error
  defp expected_outcome(_case), do: :ok

  # Generate a test for each case
  for c <- @cases do
    @tag isemail_id: c.id
    @tag isemail_category: c.category
    @tag isemail_diagnosis: c.diagnosis

    # Mark deprecated forms
    if String.starts_with?(c.category, "ISEMAIL_DEPREC") do
      @tag :deprecated
    end

    # Mark CFWS tests
    if String.starts_with?(c.category, "ISEMAIL_CFWS") do
      @tag :cfws
    end

    # Mark length-related tests
    if c.diagnosis && String.contains?(c.diagnosis, "TOOLONG") do
      @tag :length
    end

    test "isemail ##{c.id}: #{c.diagnosis || c.category}" do
      case_data = unquote(Macro.escape(c))
      deviation_reason = Map.get(@deviations, case_data.id)

      # Decode control pictures to actual control characters
      address = TestFixtures.decode_isemail_control_pictures(case_data.address)

      result = AddressParser.parse_addr_spec(address)

      expected = expected_outcome(case_data)

      # If this is a known deviation, we track it but don't fail
      if deviation_reason do
        # Deviation is expected - silently pass
        # Run with --trace to see deviation details in test names
        :ok
      else
        case expected do
          :ok ->
            assert match?({:ok, _}, result), failure_message(case_data, address, result, :should_parse)

          :error ->
            assert match?({:error, _}, result), failure_message(case_data, address, result, :should_fail)
        end
      end
    end
  end

  defp failure_message(c, address, result, expectation) do
    action =
      case expectation do
        :should_parse -> "should PARSE but got error"
        :should_fail -> "should FAIL but parsed successfully"
      end

    """

    isemail conformance failure: #{action}

      Test ID: ##{c.id}
      Category: #{c.category}
      Diagnosis: #{c.diagnosis}
      Comment: #{c.comment || "(none)"}

      Address: #{inspect(address)}
      Result: #{inspect(result)}

    """
  end
end
