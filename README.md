# Mailex

RFC 5322 email message parser for Elixir, built with [NimbleParsec](https://hexdocs.pm/nimble_parsec/NimbleParsec.html).

## Installation

Add `mailex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mailex, "~> 0.1.0"}
  ]
end
```

## Usage

### Parsing an email

```elixir
raw_email = """
From: sender@example.com
To: recipient@example.com
Subject: Hello World
Content-Type: text/plain

This is the message body.
"""

{:ok, message} = Mailex.parse(raw_email)
```

### Parsing with exceptions

```elixir
message = Mailex.parse!(raw_email)
```

## API

### `Mailex.parse/1`

```elixir
@spec parse(binary()) :: {:ok, map()} | {:error, term()}
```

Parses a raw email message string into a structured map. Returns `{:ok, message}` on success, `{:error, reason}` on failure.

### `Mailex.parse!/1`

```elixir
@spec parse!(binary()) :: map()
```

Parses a raw email message string, raising on failure.

## Message Structure

The parser returns a map with the following fields:

```elixir
%{
  headers: %{
    "from" => "sender@example.com",
    "to" => "recipient@example.com",
    "subject" => "Hello World",
    "content-type" => "text/plain"
  },
  content_type: %{
    type: "text",
    subtype: "plain",
    params: %{"charset" => "us-ascii"}
  },
  encoding: "7bit",
  body: "This is the message body.",
  parts: nil,
  filename: nil
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `headers` | `map` | All headers as lowercase keys. Multiple headers with the same name are stored as a list. |
| `content_type` | `map` | Parsed Content-Type with `type`, `subtype`, and `params`. Defaults to `text/plain`. |
| `encoding` | `string` | Content-Transfer-Encoding. Defaults to `"7bit"`. |
| `body` | `string \| nil` | Decoded message body for non-multipart messages. |
| `parts` | `list \| nil` | List of parsed parts for multipart messages. Each part has the same structure. |
| `filename` | `string \| nil` | Filename from Content-Disposition or Content-Type name parameter. |

## Features

- Header parsing with folding (continuation lines)
- Multiple headers with same name (e.g., Received) stored as lists
- Content-Type parsing with parameters (boundary, charset, name)
- Multipart message handling with recursive part parsing
- Nested message/rfc822 support
- multipart/digest with correct default content-type (message/rfc822)
- base64 and quoted-printable decoding
- RFC 2047 encoded-word decoding in filenames
- Mbox format "From " line handling
- CRLF and LF line ending normalization

## Examples

### Multipart message

```elixir
{:ok, message} = Mailex.parse(multipart_email)

message.content_type.type
#=> "multipart"

message.content_type.subtype
#=> "mixed"

message.content_type.params["boundary"]
#=> "----=_Part_0"

length(message.parts)
#=> 3

# Access first part
first_part = hd(message.parts)
first_part.content_type.type
#=> "text"
first_part.body
#=> "Hello, this is the message text."
```

### Attachments

```elixir
{:ok, message} = Mailex.parse(email_with_attachment)

attachment = Enum.find(message.parts, & &1.filename)
attachment.filename
#=> "document.pdf"

attachment.content_type
#=> %{type: "application", subtype: "pdf", params: %{}}

# Body is already decoded from base64
byte_size(attachment.body)
#=> 12345
```

### Multiple headers

```elixir
{:ok, message} = Mailex.parse(email_with_multiple_received)

message.headers["received"]
#=> ["from server1.example.com", "from server2.example.com"]
```

## License

MIT
