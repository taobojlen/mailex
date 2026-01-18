# Mailex Parser TODO

## Overview

Mailex is an RFC 5322 email parser built with NimbleParsec. The parser handles:
- Header parsing with folding (continuation lines)
- MIME multipart messages (nested)
- Content-Transfer-Encoding: base64, quoted-printable
- RFC 2047 encoded words in headers (e.g., `=?UTF-8?B?...?=`)
- message/rfc822 embedded messages

**Test suites:**
- `test/mailex/parser_test.exs` - Unit tests + MIME-tools conformance (JSON expected output)
- `test/mailex/mime4j_conformance_test.exs` - Apache James Mime4J conformance (XML expected output)

**Test fixtures:**
- `test/fixtures/testmsgs/` - Original test messages with JSON expected output
- `test/fixtures/mime4j-testmsgs/` - Apache James Mime4J corpus (48 .msg files with .xml expected)

Run tests: `mix test`

---

## Parser Issues

### RFC Compliance

- [x] **Field name character range is incomplete** (parser.ex:14)
  
  ```elixir
  # Current - excludes " (0x22)
  field_name = ascii_string([?!, ?#..?9, ?;..?~], min: 1)
  
  # Should be - includes all printable ASCII except ":"
  field_name = ascii_string([?!..?9, ?;..?~], min: 1)
  ```
  
  RFC 5322 Section 2.2 allows any printable US-ASCII except colon in field names.
  This could cause parsing failures on unusual but valid headers.

- [x] **Boundary splitting is fragile** (parser.ex:235)
  
  ```elixir
  # Current - splits anywhere the boundary string appears
  parts = String.split(body, delimiter)
  ```
  
  **Problem:** If a base64-encoded attachment happens to contain the boundary string,
  this will incorrectly split the message. Per RFC 2046, boundaries must appear at
  the start of a line, preceded by CRLF (or LF).
  
  **Fix:** Use regex like `~r/\r?\n--#{Regex.escape(boundary)}/` or scan line-by-line.

- [x] **Unconditional backslash removal in RFC 2047 decoding** (parser.ex:389)
  
  ```elixir
  # Current - removes ALL backslashes
  decoded |> String.replace("\\", "")
  ```
  
  **Problem:** This is meant to handle RFC 2231 escaped characters, but it removes
  legitimate backslashes from content. A filename like `C:\Users\file.txt` becomes
  `C:Usersfile.txt`.
  
  **Fix:** Only remove backslashes that precede specific escaped characters, or
  remove this line entirely and implement proper RFC 2231 decoding separately.

- [x] **No charset conversion**
  
  The parser extracts charset from Content-Type (e.g., `charset=iso-8859-1`) but
  doesn't convert the body to UTF-8. This means:
  - Bodies with non-UTF-8 charsets are returned as-is (wrong bytes for Elixir strings)
  - Calling code must handle charset conversion manually
  
  **Fix:** Use `:iconv` or similar to convert to UTF-8, or document this limitation.

### Code Quality

- [x] **Body trimming may corrupt binary content** (parser.ex:75)
  
  ```elixir
  body = String.trim_trailing(rest)
  ```
  
  **Problem:** If a binary attachment (image, PDF, etc.) happens to end with bytes
  that look like whitespace (0x20, 0x09, 0x0A, 0x0D), they'll be stripped.
  
  **Fix:** Don't trim the body, or only trim for text/* content types.

- [x] **No struct for Message**
  
  Currently returns plain maps like:
  ```elixir
  %{headers: %{}, content_type: %{}, encoding: "7bit", body: nil, parts: nil, filename: nil}
  ```
  
  **Recommendation:** Define a struct for better documentation and pattern matching:
  ```elixir
  defmodule Mailex.Message do
    defstruct [:headers, :content_type, :encoding, :body, :parts, :filename]
  end
  ```

- [x] **Inconsistent empty part handling**

  After fixing the double-boundary issue, empty parts now have `body: ""` while
  missing bodies have `body: nil`. Should pick one convention and stick with it.

  **Resolution:** The convention is now documented: `body: ""` for empty content,
  `body: nil` only for multipart/message containers where content is in `parts`.

---

## Test Improvements

- [x] **Add validation for skipped headers**

  The Mime4J conformance tests skip comparing these headers because they can have
  multiple values and the XML only shows the first:
  - `received`, `x-filter`, `comments`, `keywords`

  Should add separate tests that verify multi-value headers are stored as lists
  and contain all expected values.

  **Resolution:** Added "multi-value headers" test suite in parser_test.exs that
  verifies Received, Comments, and Keywords headers are correctly stored as lists.

- [x] **Add body content validation**

  Currently tests only verify structure (part count, content-types), not that
  decoded body content matches expected. The XML files contain encoded bodies,
  but the `*_decoded.xml` files contain expected decoded output.

  **Fix:** Parse `*_decoded.xml` files and compare body content.

  **Resolution:** Added "body content validation" test suite that compares decoded
  body content with the `*_decoded_*.txt` fixture files for simple, base64-encoded,
  multipart, and very-long-line messages.

- [ ] **Add recursive part validation**
  
  Only validates top-level parts' content-types. Nested multipart structures
  (e.g., multipart/alternative inside multipart/mixed) are parsed but not
  validated against expected output.

---

## Future Enhancements

- [ ] **RFC 2231 parameter continuations**
  
  Long filenames can be split across multiple parameters:
  ```
  Content-Disposition: attachment;
    filename*0="very";
    filename*1="long";
    filename*2="filename.txt"
  ```

- [ ] **S/MIME support**
  
  Handle `application/pkcs7-signature`, `application/pkcs7-mime` for signed
  and encrypted messages.

- [ ] **Streaming parser for large messages**
  
  Current parser loads entire message into memory. For large attachments,
  a streaming approach would be more efficient.

- [ ] **Message serialization**
  
  Ability to convert `%Mailex.Message{}` back to raw RFC 5322 format.
