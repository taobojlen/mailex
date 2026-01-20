defmodule Mailex do
  @moduledoc """
  RFC 5322 email message parser.

  Mailex parses raw email messages into structured `Mailex.Message` structs,
  handling headers, MIME multipart bodies, attachments, and various encodings.

  ## Features

  - RFC 5322 compliant header parsing
  - MIME multipart message support (mixed, alternative, related, digest)
  - Content-Transfer-Encoding decoding (base64, quoted-printable)
  - RFC 2047 encoded-word decoding in headers
  - RFC 2231 parameter continuation and encoding
  - Charset conversion to UTF-8
  - RFC 6532 internationalized email addresses (UTF-8)
  - Message threading (Message-ID, In-Reply-To, References)

  ## Basic Usage

      iex> raw_email = \"\"\"
      ...> From: sender@example.com
      ...> To: recipient@example.com
      ...> Subject: Hello
      ...> Content-Type: text/plain; charset=utf-8
      ...>
      ...> Hello, World!
      ...> \"\"\"
      iex> {:ok, message} = Mailex.parse(raw_email)
      iex> message.headers["subject"]
      "Hello"
      iex> message.body
      "Hello, World!"

  ## Parsing Multipart Messages

  Multipart messages have their parts parsed recursively:

      {:ok, message} = Mailex.parse(raw_multipart_email)
      message.content_type.type  # => "multipart"
      message.content_type.subtype  # => "mixed"
      message.parts  # => [%Mailex.Message{}, %Mailex.Message{}, ...]

  ## Error Handling

  Use `parse/1` for pattern matching on results:

      case Mailex.parse(raw) do
        {:ok, message} -> process(message)
        {:error, reason} -> handle_error(reason)
      end

  Or use `parse!/1` when you expect valid input:

      message = Mailex.parse!(raw)  # Raises on parse error

  ## Related Modules

  - `Mailex.Message` - The struct representing a parsed email
  - `Mailex.AddressParser` - Parse email addresses from header values
  - `Mailex.DateTimeParser` - Parse RFC 5322 date-time values
  """

  @doc """
  Parses a raw email message string.

  Returns `{:ok, message}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> Mailex.parse("From: test@example.com\\n\\nHello")
      {:ok, %Mailex.Message{headers: %{"from" => "test@example.com"}, body: "Hello", ...}}

      iex> Mailex.parse("")
      {:ok, %Mailex.Message{headers: %{}, body: "", ...}}

  """
  defdelegate parse(raw), to: Mailex.Parser

  @doc """
  Parses a raw email message string, raising on failure.

  ## Examples

      iex> message = Mailex.parse!("From: test@example.com\\n\\nHello")
      iex> message.headers["from"]
      "test@example.com"

  ## Raises

  Raises a `RuntimeError` if parsing fails.
  """
  defdelegate parse!(raw), to: Mailex.Parser
end
