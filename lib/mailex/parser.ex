defmodule Mailex.Parser do
  @moduledoc """
  RFC 5322 email message parser using NimbleParsec.
  """

  import NimbleParsec

  # Characters
  wsp = ascii_char([?\s, ?\t])
  crlf = choice([string("\r\n"), string("\n")])

  # Field name: any printable ASCII except ":"
  # RFC 5322 Section 2.2: printable US-ASCII chars (0x21-0x7E) except colon (0x3A)
  field_name =
    ascii_string([?!..?9, ?;..?~], min: 1)
    |> reduce({Enum, :join, [""]})

  # Field body: everything until end of line (including folded lines)
  # Folded lines start with whitespace
  field_body_char = ascii_char([not: ?\r, not: ?\n])

  field_body_line =
    repeat(field_body_char)
    |> reduce({List, :to_string, []})

  # A continuation line starts with whitespace after CRLF
  continuation =
    crlf
    |> ignore()
    |> concat(times(wsp, min: 1) |> reduce({List, :to_string, []}))
    |> concat(field_body_line)
    |> reduce({Enum, :join, [""]})

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

  # All headers end with blank line
  headers =
    repeat(
      header_field
      |> ignore(crlf)
    )
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
        # rest is the body
        body = String.trim_trailing(rest)
        message = process_body(message, body)
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

  # Join field body parts (initial line + continuations)
  def join_field_body(parts) do
    parts
    |> Enum.map(&String.trim/1)
    |> Enum.join(" ")
  end

  # Post-traverse to build the message structure from parsed headers
  def parse_message(rest, [{:headers, header_pairs}], context, _line, _offset) do
    headers = build_headers(header_pairs)
    content_type = parse_content_type(headers["content-type"])
    encoding = get_encoding(headers)

    message = %{
      headers: headers,
      content_type: content_type,
      encoding: encoding,
      body: nil,
      parts: nil,
      filename: nil
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
  defp parse_content_type(nil), do: %{type: "text", subtype: "plain", params: %{}}
  defp parse_content_type(value) when is_list(value), do: parse_content_type(List.first(value))
  defp parse_content_type(value) do
    # Split on semicolon for parameters
    [type_part | param_parts] = String.split(value, ";")

    {type, subtype} = parse_mime_type(String.trim(type_part))
    params = parse_params(param_parts)

    %{type: type, subtype: subtype, params: params}
  end

  defp parse_mime_type(type_str) do
    case String.split(type_str, "/", parts: 2) do
      [type, subtype] -> {String.downcase(type), String.downcase(subtype)}
      [type] -> {String.downcase(type), "plain"}
    end
  end

  defp parse_params(parts) do
    parts
    |> Enum.map(&String.trim/1)
    |> Enum.reduce(%{}, fn part, acc ->
      case String.split(part, "=", parts: 2) do
        [key, value] ->
          key = String.downcase(String.trim(key))
          value = value |> String.trim() |> unquote_value()
          Map.put(acc, key, value)
        _ ->
          acc
      end
    end)
  end

  defp unquote_value(value) do
    value
    |> String.trim()
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
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
        decoded_body = decode_body(body, message.encoding)
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
  defp split_multipart(body, boundary) do
    delimiter = "--" <> boundary

    # Split by delimiter
    parts = String.split(body, delimiter)

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
        %{
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

  # Decode body based on encoding
  defp decode_body(body, encoding) do
    case encoding do
      "base64" -> decode_base64(body)
      "quoted-printable" -> decode_quoted_printable(body)
      _ -> body
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

    # Also handle escaped backslashes (remove them per RFC 2231)
    decoded
    |> String.replace("\\", "")
  end

  # Q encoding is similar to quoted-printable but uses underscore for space
  defp decode_q_encoding(str) do
    str
    |> String.replace("_", " ")
    |> decode_qp_chars()
  end
end
