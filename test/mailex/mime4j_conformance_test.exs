defmodule Mailex.Mime4jConformanceTest do
  @moduledoc """
  Conformance tests using Apache James Mime4J test corpus.

  These tests validate our parser against the same test messages used by
  Apache James Mime4J, a well-established RFC-compliant MIME parser.

  The XML files contain the expected parse structure that we validate against.
  Note: XML files contain *encoded* bodies, while our parser *decodes* them,
  so body comparison focuses on structure, not content.
  """

  use ExUnit.Case, async: true

  @fixtures_dir Path.join([__DIR__, "..", "fixtures", "mime4j-testmsgs"])

  # Get all .msg files that have corresponding .xml expected output
  @msg_files_with_xml (if File.dir?(@fixtures_dir) do
                         msg_files =
                           @fixtures_dir
                           |> File.ls!()
                           |> Enum.filter(&String.ends_with?(&1, ".msg"))

                         msg_files
                         |> Enum.filter(fn msg_file ->
                           xml_file = Path.rootname(msg_file) <> ".xml"
                           File.exists?(Path.join(@fixtures_dir, xml_file))
                         end)
                         |> Enum.sort()
                       else
                         []
                       end)

  describe "Apache James Mime4J conformance tests" do
    for msg_file <- @msg_files_with_xml do
      test_name = Path.rootname(msg_file)

      @tag fixture: msg_file
      @tag :mime4j
      test "correctly parses #{test_name}" do
        msg_path = Path.join(@fixtures_dir, unquote(msg_file))
        xml_path = Path.join(@fixtures_dir, unquote(test_name) <> ".xml")

        raw = File.read!(msg_path)
        xml_content = File.read!(xml_path)

        # Parse the message
        result = Mailex.Parser.parse(raw)

        assert {:ok, message} = result,
               "Failed to parse #{unquote(test_name)}: #{inspect(result)}"

        # Validate structure against XML expected output
        validate_message_structure(message, xml_content, unquote(test_name))
      end
    end
  end

  # Validate that the parsed message structure matches XML expected output
  defp validate_message_structure(message, xml_content, test_name) do
    # Check if it's a multipart message at the top level
    is_multipart_expected = xml_starts_with_multipart?(xml_content)

    if is_multipart_expected do
      validate_multipart(message, xml_content, test_name)
    else
      validate_simple(message, xml_content, test_name)
    end

    # Validate headers
    validate_headers(message, xml_content, test_name)
  end

  # Check if the message's direct child is <multipart> (not nested in a body-part)
  defp xml_starts_with_multipart?(xml_content) do
    case Regex.run(~r/<message>\s*<header>.*?<\/header>\s*<(\w+)>/s, xml_content) do
      [_, "multipart"] -> true
      _ -> false
    end
  end

  defp validate_multipart(message, xml_content, test_name) do
    assert message.content_type.type == "multipart",
           "#{test_name}: expected multipart, got #{message.content_type.type}"

    assert is_list(message.parts),
           "#{test_name}: expected parts list for multipart message"

    # Count expected body-parts at top level only using token-based parsing
    expected_part_count = count_direct_body_parts(xml_content)

    assert length(message.parts) == expected_part_count,
           "#{test_name}: expected #{expected_part_count} parts, got #{length(message.parts)}"

    # Validate each part's content-type if specified in XML
    validate_parts_content_types(message.parts, xml_content, test_name)
  end

  defp validate_simple(message, xml_content, test_name) do
    # For simple (non-multipart) messages, verify body exists when expected
    has_body_expected = String.contains?(xml_content, "<body>")

    if has_body_expected do
      # Just verify we have a body (content may differ due to encoding)
      assert message.body != nil or message.parts != nil,
             "#{test_name}: expected body content"
    end

    # Verify content-type if present
    expected_type = extract_content_type_from_xml(xml_content)

    if expected_type do
      actual_type = "#{message.content_type.type}/#{message.content_type.subtype}"

      assert String.downcase(actual_type) == String.downcase(expected_type),
             "#{test_name}: expected content-type #{expected_type}, got #{actual_type}"
    end
  end

  defp validate_headers(message, xml_content, test_name) do
    # Extract expected headers from XML
    expected_headers = extract_headers_from_xml(xml_content)

    for {name, expected_value} <- expected_headers do
      header_name = String.downcase(name)
      actual_value = message.headers[header_name]

      # Skip content-type as it's handled separately with parameters
      # Skip headers that can have multiple values (Received, etc.)
      # Skip headers that may contain RFC 2047 encoded-words (our parser decodes them,
      # but the XML expected values contain raw encoded forms)
      skip_headers = ["content-type", "received", "comments", "keywords", "x-filter",
                      "from", "to", "cc", "bcc", "subject", "content-disposition", "sender"]

      if header_name not in skip_headers and actual_value do
        # Handle list values - compare against first if it's a list
        actual_for_compare =
          case actual_value do
            list when is_list(list) -> List.first(list)
            val -> val
          end

        # Normalize for comparison (handle folded headers, XML escaping)
        expected_normalized = normalize_header_value(unescape_xml(expected_value))
        actual_normalized = normalize_header_value(to_string(actual_for_compare))

        assert actual_normalized == expected_normalized,
               """
               #{test_name}: header '#{name}' mismatch
               Expected: #{inspect(expected_normalized)}
               Got: #{inspect(actual_normalized)}
               """
      end
    end
  end

  defp validate_parts_content_types(parts, xml_content, test_name) do
    # Extract content-types from direct body-parts in XML
    expected_types = extract_direct_part_content_types(xml_content)

    for {expected_type, index} <- Enum.with_index(expected_types) do
      if index < length(parts) and expected_type do
        part = Enum.at(parts, index)
        actual_type = "#{part.content_type.type}/#{part.content_type.subtype}"

        assert String.downcase(actual_type) == String.downcase(expected_type),
               "#{test_name} part #{index + 1}: expected #{expected_type}, got #{actual_type}"
      end
    end
  end

  # Count only direct children body-parts of the first multipart using tokenization
  defp count_direct_body_parts(xml_content) do
    # Find the first <multipart> and count body-parts at depth 1
    tokens = tokenize_xml(xml_content)
    count_at_depth(tokens, :looking_for_multipart, 0, 0)
  end

  # Simple XML tokenizer - extracts just the tags we care about
  defp tokenize_xml(content) do
    Regex.scan(~r/<(\/?)(\w+(?:-\w+)*)>/, content)
    |> Enum.map(fn
      [_, "", tag] -> {:open, tag}
      [_, "/", tag] -> {:close, tag}
    end)
  end

  # State machine to count body-parts at depth 1 (direct children of multipart)
  defp count_at_depth([], _, _, count), do: count

  defp count_at_depth([{:open, "multipart"} | rest], :looking_for_multipart, _, count) do
    count_at_depth(rest, :in_multipart, 0, count)
  end

  defp count_at_depth([_ | rest], :looking_for_multipart, _, count) do
    count_at_depth(rest, :looking_for_multipart, 0, count)
  end

  defp count_at_depth([{:open, "body-part"} | rest], :in_multipart, 0, count) do
    # Found a direct child body-part
    count_at_depth(rest, :in_multipart, 1, count + 1)
  end

  defp count_at_depth([{:open, "body-part"} | rest], :in_multipart, depth, count) do
    count_at_depth(rest, :in_multipart, depth + 1, count)
  end

  defp count_at_depth([{:close, "body-part"} | rest], :in_multipart, depth, count) do
    count_at_depth(rest, :in_multipart, depth - 1, count)
  end

  defp count_at_depth([{:open, "multipart"} | rest], :in_multipart, depth, count) do
    count_at_depth(rest, :in_multipart, depth + 1, count)
  end

  defp count_at_depth([{:close, "multipart"} | _rest], :in_multipart, 0, count) do
    # End of the first multipart - we're done
    count
  end

  defp count_at_depth([{:close, "multipart"} | rest], :in_multipart, depth, count) do
    count_at_depth(rest, :in_multipart, depth - 1, count)
  end

  defp count_at_depth([_ | rest], :in_multipart, depth, count) do
    count_at_depth(rest, :in_multipart, depth, count)
  end

  # Extract content-type from first header section
  defp extract_content_type_from_xml(xml_content) do
    case Regex.run(~r/<header>.*?Content-[Tt]ype:\s*([^\s;<\n]+)/s, xml_content) do
      [_, type] -> String.trim(type)
      _ -> nil
    end
  end

  # Extract headers from top-level <header> in XML
  defp extract_headers_from_xml(xml_content) do
    # Get the first header section (message headers, not part headers)
    case Regex.run(~r/<header>(.*?)<\/header>/s, xml_content) do
      [_, header_section] ->
        # Extract field values - handle multi-line fields
        Regex.scan(~r/<field>\n?([^:]+):\s*(.*?)<\/field>/s, header_section)
        |> Enum.map(fn [_, name, value] ->
          {String.trim(name), String.trim(value)}
        end)

      _ ->
        []
    end
  end

  # Extract content-types from direct body-parts only using tokenization
  defp extract_direct_part_content_types(xml_content) do
    tokens = tokenize_xml_with_content(xml_content)
    extract_types_at_depth(tokens, :looking_for_multipart, 0, [])
  end

  # Tokenizer that also captures header content for body-parts
  defp tokenize_xml_with_content(content) do
    # Split into chunks at tag boundaries
    parts = Regex.split(~r/(<\/?[\w-]+>)/, content, include_captures: true)

    parts
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.flat_map(fn
      [tag, following] ->
        case Regex.run(~r/<(\/?)(\w+(?:-\w+)*)>/, tag) do
          [_, "", name] -> [{:open, name, following}]
          [_, "/", name] -> [{:close, name}]
          _ -> []
        end

      _ ->
        []
    end)
  end

  defp extract_types_at_depth([], _, _, types), do: Enum.reverse(types)

  defp extract_types_at_depth([{:open, "multipart", _} | rest], :looking_for_multipart, _, types) do
    extract_types_at_depth(rest, :in_multipart, 0, types)
  end

  defp extract_types_at_depth([_ | rest], :looking_for_multipart, _, types) do
    extract_types_at_depth(rest, :looking_for_multipart, 0, types)
  end

  defp extract_types_at_depth([{:open, "body-part", _} | rest], :in_multipart, 0, types) do
    # Found a direct child body-part - extract its content-type from following content
    content_type = extract_content_type_from_part(rest)
    extract_types_at_depth(rest, :in_multipart, 1, [content_type | types])
  end

  defp extract_types_at_depth([{:open, "body-part", _} | rest], :in_multipart, depth, types) do
    extract_types_at_depth(rest, :in_multipart, depth + 1, types)
  end

  defp extract_types_at_depth([{:close, "body-part"} | rest], :in_multipart, depth, types) do
    extract_types_at_depth(rest, :in_multipart, depth - 1, types)
  end

  defp extract_types_at_depth([{:open, "multipart", _} | rest], :in_multipart, depth, types) do
    extract_types_at_depth(rest, :in_multipart, depth + 1, types)
  end

  defp extract_types_at_depth([{:close, "multipart"} | _rest], :in_multipart, 0, types) do
    Enum.reverse(types)
  end

  defp extract_types_at_depth([{:close, "multipart"} | rest], :in_multipart, depth, types) do
    extract_types_at_depth(rest, :in_multipart, depth - 1, types)
  end

  defp extract_types_at_depth([_ | rest], :in_multipart, depth, types) do
    extract_types_at_depth(rest, :in_multipart, depth, types)
  end

  # Extract content-type from the tokens following a body-part
  defp extract_content_type_from_part(tokens) do
    # Look for Content-Type in the header section
    tokens
    |> Enum.take_while(fn
      {:close, "header"} -> false
      {:close, "body-part"} -> false
      _ -> true
    end)
    |> Enum.find_value(fn
      {:open, "field", content} ->
        case Regex.run(~r/Content-[Tt]ype:\s*([^\s;<\n]+)/i, content) do
          [_, type] -> String.trim(type)
          _ -> nil
        end

      _ ->
        nil
    end)
  end

  defp normalize_header_value(value) do
    value
    |> String.replace(~r/\r?\n\s+/, " ")  # Unfold
    |> String.trim()
    |> String.replace(~r/\s+/, " ")  # Normalize whitespace
  end

  # Unescape XML entities
  defp unescape_xml(str) do
    str
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
  end
end
