defmodule Mailex.Parser do
  @moduledoc """
  RFC 5322 email message parser using NimbleParsec.
  """

  alias Mailex.Message

  import NimbleParsec

  # Characters
  wsp = ascii_char([?\s, ?\t])
  crlf = choice([string("\r\n"), string("\n")])

  # RFC 5322 §3.2.2 Comments
  # ctext = printable US-ASCII except "(", ")", or "\"
  # Characters 33-39 (!-'), 42-91 (*-[), 93-126 (]-~)
  # Also include space and tab as they're allowed in comment content
  ctext = utf8_char([?\s, ?\t, ?!..?', ?*..?[, ?]..?~, 0x80..0x10FFFF])

  # quoted-pair = "\" followed by any printable char or space/tab
  comment_quoted_pair =
    ignore(string("\\"))
    |> utf8_char([0x20..0x7E, 0x80..0x10FFFF])

  # Forward declaration for nested comments - we'll use lookahead/recursion
  # ccontent = ctext / quoted-pair / comment
  # comment = "(" *([FWS] ccontent) [FWS] ")"
  defcombinatorp :comment_content,
    choice([
      comment_quoted_pair,
      ctext,
      # Nested comment - recursively parse and wrap in parens for reconstruction
      parsec(:nested_comment)
    ])

  defcombinatorp :nested_comment,
    ignore(string("("))
    |> repeat(parsec(:comment_content))
    |> ignore(string(")"))
    |> reduce({__MODULE__, :wrap_nested_comment, []})

  # Top-level comment parser
  comment =
    ignore(string("("))
    |> repeat(parsec(:comment_content))
    |> ignore(string(")"))
    |> reduce({:erlang, :list_to_binary, []})

  defparsec :parse_comment, comment

  # RFC 2045 §5.1 token parser
  # token := 1*<any (US-ASCII) CHAR except SPACE, CTLs, or tspecials>
  # tspecials := "(" / ")" / "<" / ">" / "@" / "," / ";" / ":" / "\" / <"> / "/" / "[" / "]" / "?" / "="
  # CTLs are 0-31 and 127
  # Valid token chars: 33-126 (printable ASCII) excluding tspecials and space (32)
  # tspecials bytes: 40,41,60,62,64,44,59,58,92,34,47,91,93,63,61
  #   ( ) < > @ , ; : \ " / [ ] ? =
  #   40 41 60 62 64 44 59 58 92 34 47 91 93 63 61
  token =
    ascii_string(
      [
        # ! to ' (33-39), excluding none
        ?!..?',
        # * to + (42-43)
        ?*..?+,
        # - to . (45-46) - skip comma (44)
        ?-..?.,
        # 0-9 (48-57) - skip / (47)
        ?0..?9,
        # A-Z (65-90) - skip : ; < = > ? @ (58-64)
        ?A..?Z,
        # ^ to z (94-122) - skip [ \ ] (91-93)
        ?^..?z,
        # { | } ~ (123-126)
        ?{..?~
      ],
      min: 1
    )

  defparsec :parse_token, token

  # Field name: any printable ASCII except ":"
  # RFC 5322 Section 2.2: printable US-ASCII chars (0x21-0x7E) except colon (0x3A)
  field_name =
    ascii_string([?!..?9, ?;..?~], min: 1)
    |> reduce({Enum, :join, [""]})

  # Field body: everything until end of line (including folded lines)
  # Folded lines start with whitespace
  # Match any byte except CR/LF for header body content
  # RFC 5322 §4 obs-text allows bytes 128-255, RFC 6532 allows UTF-8
  field_body_char = ascii_char([not: ?\r, not: ?\n])

  field_body_line =
    repeat(field_body_char)
    |> reduce({:erlang, :list_to_binary, []})

  # A continuation line starts with whitespace after CRLF
  # RFC 5322 §2.2.3: Unfolding replaces CRLF+WSP with single space
  # We capture first WSP as the fold character, rest of WSP + line content follow
  continuation =
    crlf
    |> ignore()
    |> ascii_char([?\s, ?\t])
    |> reduce({:erlang, :list_to_binary, []})
    |> optional(times(wsp, min: 1) |> reduce({:erlang, :list_to_binary, []}))
    |> concat(field_body_line)
    |> reduce({__MODULE__, :join_continuation, []})

  field_body =
    field_body_line
    |> repeat(continuation)
    |> reduce({__MODULE__, :join_field_body, []})

  # A single header field
  header_field =
    field_name
    |> ignore(string(":"))
    |> ignore(repeat(wsp))
    |> concat(field_body)
    |> wrap()

  # RFC 5322 §2.2: Malformed line (no colon) - skip it but continue parsing
  # This ensures we detect end-of-headers by blank line, not by parse failure
  malformed_line =
    lookahead_not(crlf)
    |> repeat(ascii_char([not: ?\r, not: ?\n]))
    |> ignore()

  # A header line is either a valid header field or a malformed line to skip
  header_or_malformed =
    choice([
      header_field,
      malformed_line
    ])
    |> ignore(crlf)

  # All headers end with blank line
  headers =
    repeat(header_or_malformed)
    |> tag(:headers)

  # The full message (headers + blank line + body)
  message =
    headers
    |> ignore(optional(crlf))
    |> post_traverse({__MODULE__, :parse_message, []})

  defparsec :parse_headers, message

  @doc """
  Parses a raw email message string into a structured map.

  Returns `{:ok, message}` on success, `{:error, reason}` on failure.
  """
  @spec parse(binary()) :: {:ok, map()} | {:error, term()}
  def parse(raw) when is_binary(raw) do
    # Normalize line endings
    raw = normalize_line_endings(raw)

    case parse_headers(raw) do
      {:ok, [message], rest, _, _, _} ->
        # rest is the body - don't trim here to avoid corrupting binary content
        message = process_body(message, rest)
        # Extract filename from Content-Disposition if present
        message = extract_filename(message)
        {:ok, message}

      {:error, reason, _, _, _, _} ->
        {:error, reason}
    end
  end

  @doc """
  Parses a raw email message string, raising on failure.
  """
  @spec parse!(binary()) :: map()
  def parse!(raw) do
    case parse(raw) do
      {:ok, message} -> message
      {:error, reason} -> raise "Parse error: #{inspect(reason)}"
    end
  end

  # Normalize CRLF to LF and skip mbox "From " lines
  defp normalize_line_endings(raw) do
    raw
    |> String.replace("\r\n", "\n")
    |> skip_mbox_line()
  end

  # Skip mbox format "From " line at the beginning
  defp skip_mbox_line(<<"From ", rest::binary>>) do
    case String.split(rest, "\n", parts: 2) do
      [_mbox_line, remainder] -> remainder
      _ -> rest
    end
  end
  defp skip_mbox_line(raw), do: raw

  # Join continuation line parts: first WSP (fold char) + optional more WSP + line content
  # RFC 5322 §2.2.3: The CRLF is removed, but the leading WSP is preserved
  def join_continuation(parts), do: Enum.join(parts, "")

  # Join field body parts (initial line + continuations)
  # RFC 5322 §2.2.3: Do NOT trim whitespace - just concatenate parts
  # Each continuation already starts with its leading WSP (the fold replacement)
  def join_field_body(parts) do
    Enum.join(parts, "")
  end

  # Helper to wrap nested comment content in parentheses for reconstruction
  def wrap_nested_comment(chars) do
    "(" <> :erlang.list_to_binary(chars) <> ")"
  end

  @doc """
  Strips RFC 5322 comments from a header value.
  Comments are enclosed in parentheses and may be nested.
  Preserves parentheses inside quoted-strings.
  """
  @spec strip_comments(binary()) :: binary()
  def strip_comments(value) when is_binary(value) do
    strip_comments_impl(value, "", false, 0)
    |> String.trim()
  end

  # Strip comments while respecting quoted-strings
  # in_quote: are we inside a quoted-string?
  # depth: nesting depth of comments (0 = not in comment)
  defp strip_comments_impl("", acc, _in_quote, _depth), do: acc

  # Escaped character inside quote - keep both chars
  defp strip_comments_impl(<<"\\", char, rest::binary>>, acc, true = in_quote, depth) do
    strip_comments_impl(rest, acc <> "\\" <> <<char>>, in_quote, depth)
  end

  # Quote toggle (only when not in a comment)
  defp strip_comments_impl(<<"\"", rest::binary>>, acc, in_quote, 0 = depth) do
    strip_comments_impl(rest, acc <> "\"", not in_quote, depth)
  end

  # Quote inside comment - just skip
  defp strip_comments_impl(<<"\"", rest::binary>>, acc, in_quote, depth) when depth > 0 do
    strip_comments_impl(rest, acc, in_quote, depth)
  end

  # Escaped character inside comment - skip both
  defp strip_comments_impl(<<"\\", _char, rest::binary>>, acc, in_quote, depth) when depth > 0 do
    strip_comments_impl(rest, acc, in_quote, depth)
  end

  # Open paren outside quote - start/increase comment depth
  defp strip_comments_impl(<<"(", rest::binary>>, acc, false = in_quote, depth) do
    strip_comments_impl(rest, acc, in_quote, depth + 1)
  end

  # Close paren outside quote - decrease comment depth
  defp strip_comments_impl(<<")", rest::binary>>, acc, false = in_quote, depth) when depth > 0 do
    strip_comments_impl(rest, acc, in_quote, depth - 1)
  end

  # Any char inside comment - skip
  defp strip_comments_impl(<<_char, rest::binary>>, acc, in_quote, depth) when depth > 0 do
    strip_comments_impl(rest, acc, in_quote, depth)
  end

  # Regular char outside comment
  defp strip_comments_impl(<<char, rest::binary>>, acc, in_quote, depth) do
    strip_comments_impl(rest, acc <> <<char>>, in_quote, depth)
  end

  # Post-traverse to build the message structure from parsed headers
  def parse_message(rest, [{:headers, header_pairs}], context, _line, _offset) do
    headers = build_headers(header_pairs)
    content_type = parse_content_type(headers["content-type"])
    encoding = get_encoding(headers)

    message = %Message{
      headers: headers,
      content_type: content_type,
      encoding: encoding,
      body: nil,
      parts: nil,
      filename: nil,
      message_id: extract_message_id(headers["message-id"]),
      in_reply_to: extract_msg_id_list(headers["in-reply-to"]),
      references: extract_msg_id_list(headers["references"])
    }

    {rest, [message], context}
  end

  # Build headers map from list of [name, value] pairs
  defp build_headers(pairs) do
    Enum.reduce(pairs, %{}, fn [name, value], acc ->
      key = String.downcase(name)
      value = String.trim(value)

      case Map.get(acc, key) do
        nil -> Map.put(acc, key, value)
        existing when is_list(existing) -> Map.put(acc, key, existing ++ [value])
        existing -> Map.put(acc, key, [existing, value])
      end
    end)
  end

  # Parse Content-Type header
  # RFC 2045 §5.2: Default is text/plain; charset=us-ascii
  defp parse_content_type(nil), do: %{type: "text", subtype: "plain", params: %{"charset" => "us-ascii"}}
  defp parse_content_type(value) when is_list(value), do: parse_content_type(List.first(value))
  defp parse_content_type(value) do
    # Strip RFC 5322 comments before tokenizing
    value = strip_comments(value)

    # Tokenize respecting quoted-strings, then split on semicolons
    case tokenize_header_value(value) do
      [type_part | param_parts] ->
        {type, subtype} = parse_mime_type(String.trim(type_part))
        params = parse_params_from_tokens(param_parts)
        %{type: type, subtype: subtype, params: params}

      [] ->
        %{type: "text", subtype: "plain", params: %{}}
    end
  end

  defp parse_mime_type(type_str) do
    case String.split(type_str, "/", parts: 2) do
      [type, subtype] -> {String.downcase(type), String.downcase(subtype)}
      [type] -> {String.downcase(type), "plain"}
    end
  end

  # Tokenize header value by semicolons, respecting quoted-strings
  # Returns list of tokens split on ";" but preserving quoted content
  defp tokenize_header_value(value) do
    tokenize_by_semicolon(value, "", [], false)
  end

  defp tokenize_by_semicolon("", current, tokens, _in_quote) do
    Enum.reverse([current | tokens])
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  # Escaped character inside quotes - skip both chars
  defp tokenize_by_semicolon(<<"\\", char, rest::binary>>, current, tokens, true = in_quote) do
    tokenize_by_semicolon(rest, current <> "\\" <> <<char>>, tokens, in_quote)
  end

  # Quote toggle
  defp tokenize_by_semicolon(<<"\"", rest::binary>>, current, tokens, in_quote) do
    tokenize_by_semicolon(rest, current <> "\"", tokens, not in_quote)
  end

  # Semicolon outside quotes - split here
  defp tokenize_by_semicolon(<<";", rest::binary>>, current, tokens, false) do
    tokenize_by_semicolon(rest, "", [current | tokens], false)
  end

  # Regular char
  defp tokenize_by_semicolon(<<char, rest::binary>>, current, tokens, in_quote) do
    tokenize_by_semicolon(rest, current <> <<char>>, tokens, in_quote)
  end

  defp parse_params_from_tokens(parts) do
    raw_params =
      parts
      |> Enum.reduce(%{}, fn part, acc ->
        case parse_param_token(part) do
          {key, value} -> Map.put(acc, key, value)
          nil -> acc
        end
      end)

    # Reassemble RFC 2231 continuation parameters
    reassemble_rfc2231_params(raw_params)
  end

  # Parse a single parameter token "key=value" respecting quoted-strings
  defp parse_param_token(part) do
    part = String.trim(part)
    case find_first_equals_outside_quotes(part) do
      nil -> nil
      pos ->
        key = part |> String.slice(0, pos) |> String.trim() |> String.downcase()
        value = part |> String.slice((pos + 1)..-1//1) |> String.trim() |> unquote_value()
        {key, value}
    end
  end

  # Find position of first "=" that's not inside a quoted-string
  defp find_first_equals_outside_quotes(str) do
    find_equals(str, 0, false)
  end

  defp find_equals("", _pos, _in_quote), do: nil
  defp find_equals(<<"\\", _, rest::binary>>, pos, true = in_quote) do
    find_equals(rest, pos + 2, in_quote)
  end
  defp find_equals(<<"\"", rest::binary>>, pos, in_quote) do
    find_equals(rest, pos + 1, not in_quote)
  end
  defp find_equals(<<"=", _rest::binary>>, pos, false), do: pos
  defp find_equals(<<_, rest::binary>>, pos, in_quote) do
    find_equals(rest, pos + 1, in_quote)
  end

  # Legacy parse_params for places that already have split parts
  defp parse_params(parts) do
    parse_params_from_tokens(parts)
  end

  # RFC 2231 parameter continuation reassembly and extended value decoding
  # Handles patterns like: filename*0="part1"; filename*1="part2"
  # And extended values like: filename*=UTF-8''Hello%20World
  defp reassemble_rfc2231_params(params) do
    # Separate params into: continuations (*0, *1, etc.), extended (*), and regular
    {continuations, rest} =
      Enum.split_with(params, fn {key, _value} ->
        Regex.match?(~r/\*\d+\*?$/, key)
      end)

    {extended, regular} =
      Enum.split_with(rest, fn {key, _value} ->
        # Match keys ending with just * (not *0, *1, etc.)
        String.ends_with?(key, "*") and not Regex.match?(~r/\*\d+\*?$/, key)
      end)

    # Process extended parameters (filename*=charset'lang'value)
    decoded_extended =
      Enum.map(extended, fn {key, value} ->
        base_name = String.trim_trailing(key, "*")
        decoded_value = decode_rfc2231_extended_value(value)
        {base_name, decoded_value}
      end)
      |> Map.new()

    # Group continuations by base name
    grouped =
      Enum.group_by(continuations, fn {key, _value} ->
        # Extract base name (e.g., "filename" from "filename*0" or "filename*0*")
        key |> String.replace(~r/\*\d+\*?$/, "")
      end)

    # Reassemble each group
    reassembled =
      Enum.map(grouped, fn {base_name, parts} ->
        # Sort by numeric index and concatenate values
        sorted_values =
          parts
          |> Enum.map(fn {key, value} ->
            # Extract index from key (e.g., "0" from "filename*0")
            index = key |> String.replace(~r/^.*\*(\d+)\*?$/, "\\1") |> String.to_integer()
            # Check if this segment is encoded (ends with *)
            is_encoded = String.ends_with?(key, "*")
            {index, value, is_encoded}
          end)
          |> Enum.sort_by(fn {index, _, _} -> index end)
          |> Enum.map(fn {_, value, is_encoded} ->
            if is_encoded do
              decode_rfc2231_extended_value(value)
            else
              value
            end
          end)

        {base_name, Enum.join(sorted_values, "")}
      end)
      |> Map.new()

    # Merge: regular < extended < reassembled (later takes precedence)
    Map.new(regular)
    |> Map.merge(decoded_extended)
    |> Map.merge(reassembled)
  end

  # Decode RFC 2231 extended value: charset'language'percent-encoded-value
  defp decode_rfc2231_extended_value(value) do
    case String.split(value, "'", parts: 3) do
      [charset, _language, encoded_value] ->
        # For non-UTF-8 charsets, we need to decode percent-encoded bytes first,
        # then convert from the source charset to UTF-8
        decoded_bytes = percent_decode_to_binary(encoded_value)
        convert_charset(decoded_bytes, charset)

      _ ->
        # If not in charset'lang'value format, just percent-decode as UTF-8
        URI.decode(value)
    end
  end

  # Percent-decode a string to raw binary (without assuming UTF-8)
  defp percent_decode_to_binary(string) do
    string
    |> String.to_charlist()
    |> decode_percent_chars([])
    |> Enum.reverse()
    |> :erlang.list_to_binary()
  end

  defp decode_percent_chars([], acc), do: acc
  defp decode_percent_chars([?%, h1, h2 | rest], acc) do
    byte = List.to_integer([h1, h2], 16)
    decode_percent_chars(rest, [byte | acc])
  end
  defp decode_percent_chars([char | rest], acc) do
    decode_percent_chars(rest, [char | acc])
  end

  defp unquote_value(value) do
    value = String.trim(value)

    if String.starts_with?(value, "\"") and String.ends_with?(value, "\"") do
      value
      |> String.slice(1..-2//1)
      |> unescape_quoted_string()
    else
      value
    end
  end

  # Handle backslash escapes in quoted strings (RFC 2822)
  # A backslash followed by any character means just that character
  defp unescape_quoted_string(str) do
    str
    |> String.replace(~r/\\(.)/, "\\1")
  end

  defp get_encoding(headers) do
    case headers["content-transfer-encoding"] do
      nil -> "7bit"
      value when is_list(value) -> String.downcase(List.first(value))
      value -> String.downcase(String.trim(value))
    end
  end

  # Process body based on content type
  defp process_body(message, body) do
    cond do
      message.content_type.type == "multipart" ->
        process_multipart(message, body)

      message.content_type.type == "message" and message.content_type.subtype == "rfc822" ->
        process_embedded_message(message, body)

      true ->
        charset = message.content_type.params["charset"]
        is_text = message.content_type.type == "text"
        # Only trim trailing whitespace for text content to avoid corrupting binary data
        body = if is_text, do: String.trim_trailing(body), else: body
        decoded_body = decode_body(body, message.encoding, charset, is_text)
        %{message | body: decoded_body}
    end
  end

  # Process multipart body
  defp process_multipart(message, body) do
    boundary = message.content_type.params["boundary"]

    if boundary do
      parts = split_multipart(body, boundary)
      # For multipart/digest, default content-type is message/rfc822
      default_type = if message.content_type.subtype == "digest", do: "message/rfc822", else: nil
      parsed_parts = Enum.map(parts, &parse_part(&1, default_type))
      %{message | parts: parsed_parts, body: nil}
    else
      %{message | body: body}
    end
  end

  # Split multipart body into parts
  # RFC 2046: Boundaries must appear at the start of a line (after CRLF/LF)
  defp split_multipart(body, boundary) do
    delimiter = "--" <> boundary

    # Build regex that matches boundary at start of line (or start of body)
    # The boundary is preceded by CRLF or LF (or nothing at start of body)
    escaped_delimiter = Regex.escape(delimiter)
    boundary_regex = Regex.compile!("(?:^|\\r?\\n)" <> escaped_delimiter)

    # Split by boundary at line start
    parts = Regex.split(boundary_regex, body)

    # First part is preamble (ignore), last part may contain epilogue
    parts = case parts do
      [_preamble | rest] -> rest
      [] -> []
    end

    # Process parts, stopping at end delimiter
    parts
    |> Enum.take_while(fn part ->
      # Check if this is the end marker (starts with --)
      trimmed = String.trim_leading(part)
      not String.starts_with?(trimmed, "--")
    end)
    |> Enum.map(fn part ->
      # Remove any trailing whitespace/tabs after the boundary, then the newline
      part = Regex.replace(~r/^[ \t]*\r?\n/, part, "")
      part
    end)
  end

  # Parse a single part
  defp parse_part(part_content, default_type) do
    case parse(part_content) do
      {:ok, parsed} ->
        # Apply default type if no Content-Type was specified
        parsed = apply_default_type(parsed, default_type)
        # Extract filename from Content-Disposition if present
        parsed = extract_filename(parsed)
        parsed
      {:error, _} ->
        # If parsing fails, treat as plain text
        {type, subtype} = parse_default_type(default_type)
        %Message{
          headers: %{},
          content_type: %{type: type, subtype: subtype, params: %{}},
          encoding: "7bit",
          body: part_content,
          parts: nil,
          filename: nil
        }
    end
  end

  # Apply default type if the part has no Content-Type header
  defp apply_default_type(parsed, nil), do: parsed
  defp apply_default_type(parsed, default_type) do
    if parsed.headers["content-type"] == nil do
      {type, subtype} = parse_default_type(default_type)
      content_type = %{type: type, subtype: subtype, params: %{}}
      %{parsed | content_type: content_type}
    else
      parsed
    end
  end

  defp parse_default_type(nil), do: {"text", "plain"}
  defp parse_default_type(type_str) do
    case String.split(type_str, "/", parts: 2) do
      [type, subtype] -> {String.downcase(type), String.downcase(subtype)}
      [type] -> {String.downcase(type), "plain"}
    end
  end

  # Extract filename from Content-Disposition header
  defp extract_filename(message) do
    filename = case message.headers["content-disposition"] do
      nil ->
        # Try Content-Type name parameter
        message.content_type.params["name"]

      disposition when is_binary(disposition) ->
        params = parse_disposition_params(disposition)
        params["filename"] || message.content_type.params["name"]

      _ ->
        nil
    end

    # Decode RFC 2047 encoded words in filename
    filename = decode_rfc2047(filename)
    %{message | filename: filename}
  end

  defp parse_disposition_params(disposition) do
    # Strip RFC 5322 comments before parsing
    disposition = strip_comments(disposition)

    case String.split(disposition, ";") do
      [_type | params] -> parse_params(params)
      _ -> %{}
    end
  end

  # Process embedded message/rfc822
  defp process_embedded_message(message, body) do
    case parse(body) do
      {:ok, embedded} ->
        %{message | body: nil, parts: [embedded]}
      {:error, _} ->
        %{message | body: body}
    end
  end

  # Decode body based on encoding, then convert charset to UTF-8 for text content
  defp decode_body(body, encoding, charset, is_text) do
    decoded = case encoding do
      "base64" -> decode_base64(body)
      "quoted-printable" -> decode_quoted_printable(body)
      _ -> body
    end

    # Convert charset to UTF-8 for text content
    if is_text and charset do
      convert_charset(decoded, charset)
    else
      decoded
    end
  end

  # Convert text from source charset to UTF-8
  defp convert_charset(text, charset) do
    normalized_charset = normalize_charset(charset)

    cond do
      # Already UTF-8 or ASCII-compatible, no conversion needed
      normalized_charset in ["utf-8", "us-ascii", "ascii"] ->
        text

      # Try to convert using codepagex
      true ->
        case codepagex_encoding(normalized_charset) do
          nil ->
            # Unknown charset, return as-is
            text

          encoding ->
            case Codepagex.to_string(text, encoding) do
              {:ok, converted} -> converted
              {:error, _} -> text  # Conversion failed, return as-is
            end
        end
    end
  end

  # Normalize charset name to lowercase without extra formatting
  defp normalize_charset(charset) do
    charset
    |> String.downcase()
    |> String.trim()
    |> String.replace("_", "-")
  end

  # Map common charset names to codepagex encoding strings
  # Codepagex uses "ISO8859/8859-X" format for ISO-8859 charsets
  defp codepagex_encoding(charset) do
    case charset do
      "iso-8859-1" -> "ISO8859/8859-1"
      "iso-8859-2" -> "ISO8859/8859-2"
      "iso-8859-3" -> "ISO8859/8859-3"
      "iso-8859-4" -> "ISO8859/8859-4"
      "iso-8859-5" -> "ISO8859/8859-5"
      "iso-8859-6" -> "ISO8859/8859-6"
      "iso-8859-7" -> "ISO8859/8859-7"
      "iso-8859-8" -> "ISO8859/8859-8"
      "iso-8859-9" -> "ISO8859/8859-9"
      "iso-8859-10" -> "ISO8859/8859-10"
      "iso-8859-11" -> "ISO8859/8859-11"
      "iso-8859-13" -> "ISO8859/8859-13"
      "iso-8859-14" -> "ISO8859/8859-14"
      "iso-8859-15" -> "ISO8859/8859-15"
      "iso-8859-16" -> "ISO8859/8859-16"
      # Windows and other encodings can be added by configuring codepagex
      # See: https://hexdocs.pm/codepagex/readme.html#selecting-encodings
      _ -> nil
    end
  end

  defp decode_base64(body) do
    # Remove whitespace and decode
    body
    |> String.replace(~r/\s/, "")
    |> Base.decode64()
    |> case do
      {:ok, decoded} -> decoded
      :error -> body
    end
  end

  defp decode_quoted_printable(body) do
    body
    |> String.replace("=\n", "")  # Soft line breaks
    |> String.replace("=\r\n", "")
    |> decode_qp_chars()
  end

  defp decode_qp_chars(str) do
    Regex.replace(~r/=([0-9A-Fa-f]{2})/, str, fn _, hex ->
      {byte, ""} = Integer.parse(hex, 16)
      <<byte>>
    end)
  end

  # RFC 5322 §3.6.4 Message Identification Fields
  # Extract a single message-id from Message-ID header
  # msg-id = [CFWS] "<" id-left "@" id-right ">" [CFWS]
  defp extract_message_id(nil), do: nil
  defp extract_message_id(value) when is_list(value), do: extract_message_id(List.first(value))
  defp extract_message_id(value) do
    case extract_msg_ids(value) do
      [id | _] -> id
      [] -> nil
    end
  end

  # Extract a list of message-ids from In-Reply-To or References headers
  defp extract_msg_id_list(nil), do: nil
  defp extract_msg_id_list(value) when is_list(value) do
    value
    |> Enum.flat_map(&extract_msg_ids/1)
    |> case do
      [] -> nil
      ids -> ids
    end
  end
  defp extract_msg_id_list(value) do
    case extract_msg_ids(value) do
      [] -> nil
      ids -> ids
    end
  end

  # Extract all msg-id tokens from a header value
  # Matches: < id-left @ id-right > with optional whitespace
  defp extract_msg_ids(str) do
    # Pattern: < followed by non-angle-bracket content, then >
    # Allows whitespace inside angle brackets (lenient parsing)
    ~r/<\s*([^<>]+?)\s*>/
    |> Regex.scan(str)
    |> Enum.map(fn [_, content] -> String.trim(content) end)
    |> Enum.filter(&valid_msg_id?/1)
  end

  # A valid msg-id should contain @ (id-left @ id-right)
  # Empty or malformed ids are rejected
  defp valid_msg_id?(id) do
    id != "" and String.contains?(id, "@")
  end

  # RFC 2047 encoded-word decoding
  # Format: =?charset?encoding?encoded_text?=
  def decode_rfc2047(nil), do: nil
  def decode_rfc2047(str) do
    # Pattern for RFC 2047 encoded words
    # charset can include language tag like US-ASCII*EN
    pattern = ~r/=\?([^?*]+)(?:\*[^?]*)?\?([BbQq])\?([^?]*)\?=/

    decoded = Regex.replace(pattern, str, fn _, _charset, encoding, encoded_text ->
      case String.upcase(encoding) do
        "B" -> decode_base64(encoded_text)
        "Q" -> decode_q_encoding(encoded_text)
        _ -> encoded_text
      end
    end)

    decoded
  end

  # Q encoding is similar to quoted-printable but uses underscore for space
  defp decode_q_encoding(str) do
    str
    |> String.replace("_", " ")
    |> decode_qp_chars()
  end
end
