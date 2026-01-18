defmodule Mailex.Message do
  @moduledoc """
  Struct representing a parsed email message.

  ## Fields

  - `:headers` - Map of header name (lowercase) to value(s). Single values are strings,
    multiple values (e.g., multiple Received headers) are lists of strings.
  - `:content_type` - Map with `:type`, `:subtype`, and `:params` keys.
    Example: `%{type: "text", subtype: "plain", params: %{"charset" => "utf-8"}}`
  - `:encoding` - Content-Transfer-Encoding value (e.g., "7bit", "base64", "quoted-printable")
  - `:body` - Decoded body content for non-multipart messages (empty string `""` if no content),
    `nil` for multipart/message containers where content is in `:parts`.
  - `:parts` - List of `%Mailex.Message{}` structs for multipart messages, `nil` otherwise.
  - `:filename` - Extracted filename from Content-Disposition or Content-Type name parameter.
  - `:message_id` - Extracted Message-ID (without angle brackets), `nil` if not present.
  - `:in_reply_to` - List of message IDs from In-Reply-To header, `nil` if not present.
  - `:references` - List of message IDs from References header (for threading), `nil` if not present.
  """

  @type t :: %__MODULE__{
          headers: %{String.t() => String.t() | [String.t()]},
          content_type: %{type: String.t(), subtype: String.t(), params: %{String.t() => String.t()}},
          encoding: String.t(),
          body: binary() | nil,
          parts: [t()] | nil,
          filename: String.t() | nil,
          message_id: String.t() | nil,
          in_reply_to: [String.t()] | nil,
          references: [String.t()] | nil
        }

  defstruct [:headers, :content_type, :encoding, :body, :parts, :filename, :message_id, :in_reply_to, :references]
end
