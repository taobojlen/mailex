# RFC Compliance TODO

This document lists the gaps between the current Mailex parser implementation and full RFC compliance for email message parsing.

---

## 1. Header Field Parsing

### 1.2 Header unfolding trims whitespace incorrectly

**Status:** ✅ Implemented

**Problem:** `join_field_body/1` uses `String.trim/1` on each line before joining with `" "`. RFC unfolding should replace `CRLF` + WSP with a single space without trimming other whitespace. Current behavior:
- Removes meaningful leading/trailing spaces inside quoted-strings or comments
- Collapses whitespace beyond what RFC permits
- Can corrupt parameter values and unstructured field bodies

**RFCs:**
- RFC 5322 §2.2.3 — Long Header Fields (folding/unfolding rules)
- RFC 5322 §3.2.2 — FWS (Folding White Space) grammar

**Implementation:**
- For each continuation line, replace `CRLF + 1+WSP` with a single space
- Do NOT use `String.trim/1` in header value assembly
- Keep initial line as-is (minus trailing CRLF); for continuations, drop leading WSP or replace with single space

---

### 1.3 Malformed header lines terminate parsing prematurely

**Status:** ✅ Implemented

**Problem:** Parser stops headers when `header_field` fails. Any malformed header line (missing `:`) prematurely ends headers and treats remainder as body. Robust parsers should detect end-of-headers strictly by a blank line.

**RFCs:**
- RFC 5322 §2.2 — Message format is header fields, then CRLF, then body

**Implementation:**
- Detect end-of-headers by blank line only, not by `header_field` parse failure
- Option: accumulate malformed lines under a special key, or attach to previous field body

---

## 2. Message-ID Parsing

### 2.1 No parsing for Message-ID / In-Reply-To / References

**Status:** ✅ Implemented

**Problem:** These are stored as raw header values only. No validation or extraction of msg-id tokens.

**RFCs:**
- RFC 5322 §3.6.4 — Identification Fields
- `msg-id = [CFWS] "<" id-left "@" id-right ">" [CFWS]`
- `In-Reply-To` and `References` contain one or more msg-ids

**Implementation:**
Implemented:
- `parse_msg_id/1` NimbleParsec combinator for single msg-id
- `parse_msg_id_list/1` NimbleParsec combinator for In-Reply-To/References
- Proper `dot-atom-text` parsing for id-left
- `no-fold-literal` support for domain literals (e.g., `[192.168.1.1]`, `[IPv6:...]`)
- CFWS (comments and folding whitespace) handling around msg-ids
- Extraction integrated into Message struct: `message_id`, `in_reply_to`, `references`
- Fallback to lenient regex for non-compliant but common real-world IDs

---

## 3. MIME Type/Subtype Handling

### 3.1 Content-Type parsing breaks on quoted-strings and comments

**Status:** ✅ Implemented

**Problem:** Using `String.split(value, ";")` and `String.split(part, "=", parts: 2)` fails when:
- Parameter values are quoted-strings containing `;` or `=` (legal)
- Comments are present: `text/plain (comment); charset=utf-8`
- Folding whitespace exists around separators

**RFCs:**
- RFC 2045 §5.1 — Syntax of the Content-Type Header Field
- RFC 2045 §5.1 — Parameter values are `token / quoted-string`
- RFC 5322 §3.2.2 — CFWS applies in header field values

**Implementation:**
Implement a real `content-type` value parser with NimbleParsec:
- `type "/" subtype` as tokens with optional CFWS
- `";" attribute "=" value` repeating, where value is `token` or `quoted-string`
- Properly handle backslash escapes in quoted-strings (`\"`, `\\`)

---

### 3.2 Missing Content-Type defaults are incomplete

**Status:** ✅ Implemented

**Problem:** Default type is applied for `multipart/digest` parts (`message/rfc822`), but RFC 2045/2046 defaults for missing Content-Type in general are not consistently applied.

**RFCs:**
- RFC 2045 §5.2 — Content-Type Defaults: `text/plain; charset=us-ascii`
- RFC 2046 §5.1.5 — multipart/digest: parts default to `message/rfc822`

**Implementation:**
- If a part lacks Content-Type and is not in multipart/digest, default to `text/plain; charset=us-ascii`
- Current multipart/digest logic is correct; extend defaulting to other contexts

---

## 4. Obsolete Syntax Support

### 4.1 No explicit support for obs-* productions

**Status:** Partially Implemented

**Problem:** RFC 5322 §4 defines obsolete syntax forms that still appear in real email. Current parser partially supports header folding but not:
- `obs-phrase` (period allowed in display names)
- `obs-local-part` (CFWS between dot-atom parts)
- `obs-domain` (CFWS between labels)
- `obs-route` (route addresses: `<@hop1,@hop2:user@final>`)
- `obs-date` (2-digit years, named timezones)

**RFCs:**
- RFC 5322 §4 — Obsolete Syntax (entire section)
- RFC 5322 §4.4 — Obsolete Addressing (routes, obs-local-part, obs-domain)
- RFC 5322 §4.3 — Obsolete Date and Time

**Implementation:**
Implemented:
- `obs-text` bytes (128-255) in header field bodies — parser already accepts these due to NimbleParsec's handling of byte ranges with exclusions

Pending (depends on other features):
- `obs-phrase` — requires address parsing
- `obs-local-part`, `obs-domain` — requires address parsing
- `obs-route` — requires address parsing
- `obs-date` — requires date parsing

---

## 5. Comments (CFWS) Handling

### 5.1 No parsing or skipping of comments

**Status:** ✅ Implemented

**Problem:** Comments can appear in many header values: `From: John (CEO) <a@b>`. Current `String.split` based parsing fails on comments. RFC 2047 decoding and address parsing require CFWS awareness.

**RFCs:**
- RFC 5322 §3.2.2 — Comments, CFWS, FWS
- Comments use nesting: `comment = "(" *(ctext / quoted-pair / comment) ")"`

**Implementation:**
Implemented:
- `comment` NimbleParsec combinator with proper nesting and quoted-pair support
- `parse_comment/1` public parser function for testing
- `strip_comments/1` helper that removes comments while preserving quoted-strings
- Applied to `parse_content_type/1` and `parse_disposition_params/1`

---

## 6. Quoted-String Parsing

### 6.1 Quoted-string escapes not properly handled

**Status:** ✅ Implemented

**Problem:** MIME parameters and RFC 5322 productions depend on `quoted-string` with `quoted-pair` handling. The current `unquote_value/1` likely doesn't handle:
- Backslash escapes: `\"` → `"`, `\\` → `\`
- Preserved qtext characters
- FWS within quoted-strings

**RFCs:**
- RFC 5322 §3.2.4 — Quoted Strings
- RFC 2045 — Parameter values include `quoted-string`
- `quoted-string = DQUOTE *([FWS] qcontent) [FWS] DQUOTE`
- `qcontent = qtext / quoted-pair`

**Implementation:**
Implemented:
- `unquote_value/1` properly handles backslash escapes using regex replacement
- `unescape_quoted_string/1` converts `\X` → `X` for any character X (VCHAR or WSP)
- Header unfolding normalizes FWS (CRLF+WSP) before quoted-string processing
- Used for MIME parameters in Content-Type and Content-Disposition headers
- Handles UTF-8 characters correctly (regex `.` matches codepoints, not bytes)

Pending (depends on address parsing):
- Reuse for display names in address headers (`"Last, First" <a@b>`)

---

## 7. Internationalized Email Support

### 7.1 RFC 6532 UTF-8 headers not supported

**Status:** ✅ Implemented

**Problem:** Header body parsing rejects non-ASCII bytes (see 1.1). RFC 6532 allows raw UTF-8 directly in headers without RFC 2047 encoding.

**RFCs:**
- RFC 6532 §3 — UTF-8 in message headers
- RFC 6532 §3.2 — Syntax Extensions to RFC 5322

**Implementation:**
Implemented:
- NimbleParsec header body parser uses `utf8_char` for comment parsing and `ascii_char([not: ?\r, not: ?\n])` for field body
- Raw UTF-8 bytes are preserved through header parsing without modification
- Field-names remain ASCII-only (correct per RFC 6532)
- Tests verify raw UTF-8 in Subject, From, custom X- headers, and through header folding

---

### 7.2 Internationalized email addresses not supported

**Status:** ✅ Implemented

**Problem:** Non-ASCII local-parts and domains (EAI - Email Address Internationalization) cannot be parsed because address parsing doesn't exist.

**RFCs:**
- RFC 6532 — Address internationalization in headers
- RFC 6531 — SMTPUTF8 transport
- RFC 5890/5891 — IDNA (Internationalized Domain Names)

**Implementation:**
Implemented:
- Extended `AddressParser` to support RFC 6532 internationalized email addresses
- `atext` combinator now accepts both ASCII characters and UTF-8 non-ASCII (codepoints > 127)
- `codepoints_to_string/1` helper converts UTF-8 codepoints to proper UTF-8 binary strings
- UTF-8 supported in local-part, domain, and display-name
- Tests cover Japanese, Chinese, German umlauts, Cyrillic, Arabic, and emoji characters

---

## 8. multipart/related Support

### 8.1 Root part resolution not implemented

**Status:** ✅ Implemented

**Problem:** multipart/related messages have `start` and `type` parameters to identify the "root" part. Currently these are parsed as generic parameters but not interpreted. Clients cannot reliably determine which part is the main document vs related resources.

**RFCs:**
- RFC 2387 §3 — The Multipart/Related Content-Type
- RFC 2387 §3.1 — The Type Parameter (MIME type of root)
- RFC 2387 §3.2 — The Start Parameter (Content-ID of root)

**Implementation:**
Implemented:
- Added `content_id` field to Message struct to parse Content-ID headers (RFC 2392)
- Added `related_root_index` field to Message struct for multipart/related messages
- `extract_content_id/1` extracts Content-ID value, stripping angle brackets
- `resolve_related_root/2` finds root part index:
  - If `start` parameter exists, find part whose Content-ID matches (stripping angle brackets for comparison)
  - If no `start` parameter or no matching Content-ID, default to first part (index 0)
- `type` parameter is preserved in content_type params for client interpretation

---

## 9. Content-Disposition Improvements

### 9.1 Disposition type and additional parameters not exposed

**Status:** ✅ Implemented

**Problem:** `parse_disposition_params/1` uses `String.split(disposition, ";")` which:
- Ignores disposition-type token (`inline`/`attachment`/extension-token)
- Doesn't expose other standard params: `creation-date`, `modification-date`, `read-date`, `size`
- Fails on quoted-strings containing `;`

**RFCs:**
- RFC 2183 §2 — Content-Disposition header field
- RFC 2183 §2.1-2.4 — Parameters: filename, creation-date, modification-date, read-date, size

**Implementation:**
Implemented:
- `parse_content_disposition/1` uses `tokenize_header_value/1` to properly parse disposition-type and parameters
- Disposition-type is extracted and stored in `Message.disposition_type` (lowercased)
- All parameters are exposed in `Message.disposition_params` map
- Properly handles quoted-strings containing semicolons
- Handles extension disposition-type tokens (e.g., `form-data`)

---

### 9.2 RFC 2231 parameter handling edge cases

**Status:** ✅ Implemented

**Problem:** RFC 2231 implementation may have issues with:
1. **Precedence:** If both `filename` and `filename*` exist, `filename*` should win
2. **Continuations:** `filename*0*=` includes `charset'lang'...` only in first segment; later segments are percent-encoded without repeating charset/lang
3. **Decoding order:** Percent-decode bytes first, then charset convert
4. **Quoted-strings:** Extended values are NOT quoted-strings; avoid unquoting before percent-decoding

**RFCs:**
- RFC 2231 §3 — Parameter Value Extensions
- RFC 2231 §4 — Continuations

**Implementation:**
Implemented:
- `reassemble_rfc2231_params/1` correctly handles precedence: regular < extended < reassembled (later takes precedence)
- Extended values (`param*`) take precedence over regular values (`param`)
- Continuation segments sorted and concatenated in order
- First segment with `*` has `charset'lang'bytes`, subsequent segments are just percent-encoded
- `percent_decode_to_binary/1` decodes percent-encoded bytes first, then `convert_charset/2` converts from source charset
- Mixed encoded (`*N*`) and unencoded (`*N`) continuation segments handled correctly

---

## 10. RFC 2047 Encoded-Word Improvements

### 10.1 RFC 2047 decoding is not charset-aware

**Status:** ✅ Implemented

**Problem:** `decode_rfc2047/1` decodes Base64/Q to bytes but never converts from declared charset to UTF-8. Also missing adjacent encoded-word whitespace handling.

**RFCs:**
- RFC 2047 §2 — Encoded-word syntax
- RFC 2047 §6.2 — Whitespace between adjacent encoded-words should be ignored

**Implementation:**
Implemented:
- `decode_rfc2047/1` now extracts charset and uses `convert_charset/2` to convert to UTF-8
- Supports ISO-8859-1/15, US-ASCII, UTF-8, and other charsets via codepagex
- Adjacent encoded-word whitespace collapsing: `?=[ \t\r\n]+=?` patterns are collapsed
- `decode_base64_to_binary/1` and `decode_q_encoding_to_binary/1` for proper binary handling
- Handles charset with language tag (e.g., `ISO-8859-1*de`)

---

### 10.2 RFC 2047 only applied to filename, not other headers

**Status:** ✅ Implemented

**Problem:** RFC 2047 decoding is only applied to filename extraction. Should also be applied to:
- Subject header
- Display-names in address headers
- Comments header
- Any unstructured header exposed to users

**RFCs:**
- RFC 2047 §5 — Use of encoded-words in message headers

**Implementation:**
Implemented:
- `build_headers/1` now applies `decode_rfc2047/1` to all header values during parsing
- Subject and Comments headers are always decoded
- Other headers are decoded if they contain encoded-word patterns (`=?` and `?=`)
- Display-names in address headers are decoded (address parsing itself is separate feature)

---

## 11. Multipart Boundary Parsing

### 11.1 Boundary delimiter parsing not fully RFC-compliant

**Status:** ✅ Implemented

**Problem:** `split_multipart/2` uses regex to detect boundary at start-of-line but doesn't enforce full delimiter-line structure:
- Boundary delimiter line is `--boundary` + optional transport padding (LWSP) + CRLF
- Closing delimiter is `--boundary--` + optional transport padding + CRLF
- Current regex might match boundary as prefix of longer line content

**RFCs:**
- RFC 2046 §5.1.1 — Common Syntax (boundary delimiter line definition)

**Implementation:**
Implemented:
- Replaced regex-based `split_multipart/2` with line-by-line parser
- `parse_multipart_lines/6` recursive state machine (`:preamble` → `:in_part`)
- `is_boundary_line?/2` validates delimiter with LWSP-only suffix check
- `is_close_boundary_line?/2` validates close-delimiter (`--boundary--`)
- `lwsp_only?/1` ensures only spaces/tabs follow boundary (per RFC 2046 §5.1.1)
- Boundaries must be exact matches, not prefixes (e.g., `--abcX` won't match boundary `abc`)
- Transport padding (trailing whitespace) properly allowed on delimiter lines

---

## Implementation Priority

Suggested order based on impact and dependencies:

### Phase 1: Foundation (High Impact)
1. **1.2** Fix header unfolding to not trim whitespace

### Phase 2: Lexical Primitives (Enables Everything Else) ✅
2. ✅ **6.1** ~~Implement proper `quoted-string` parsing with escapes~~
3. ✅ **5.1** ~~Implement CFWS/comment handling~~
4. ✅ **Phase 2 complete** ~~Implement `token` parser per RFC 2045~~

### Phase 3: MIME Parsing Rebuild ✅
5. ✅ **3.1** ~~Rebuild Content-Type parser using primitives~~
6. ✅ **3.2** ~~Complete Content-Type defaults~~
7. ✅ **9.1** ~~Rebuild Content-Disposition parser~~
8. ✅ **9.2** ~~Fix RFC 2231 edge cases~~

### Phase 4: Structured Header Parsing ✅
9. ✅ **2.1** ~~Implement Message-ID parsing~~

### Phase 5: Enhanced Features ✅
10. ✅ **8.1** ~~Add multipart/related root resolution~~
11. ✅ **10.1** ~~Fix RFC 2047 charset conversion~~
12. ✅ **10.2** ~~Apply RFC 2047 to more headers~~
13. ✅ **7.1** ~~Full RFC 6532 UTF-8 header support~~
14. ✅ **7.2** ~~Internationalized address support~~

### Phase 6: Robustness
15. **4.1** Add obsolete syntax tolerance
16. ✅ **1.3** ~~Improve malformed header handling~~
17. ✅ **11.1** ~~Improve multipart boundary parsing~~

---

## References

- [RFC 5322](rfcs/rfc5322.txt) — Internet Message Format
- [RFC 2045](rfcs/rfc2045.txt) — MIME Part One: Format of Internet Message Bodies
- [RFC 2046](rfcs/rfc2046.txt) — MIME Part Two: Media Types
- [RFC 2047](rfcs/rfc2047.txt) — MIME Part Three: Message Header Extensions for Non-ASCII Text
- [RFC 2049](rfcs/rfc2049.txt) — MIME Part Five: Conformance Criteria and Examples
- [RFC 2183](rfcs/rfc2183.txt) — Content-Disposition Header Field
- [RFC 2231](rfcs/rfc2231.txt) — MIME Parameter Value and Encoded Word Extensions
- [RFC 2387](rfcs/rfc2387.txt) — The MIME Multipart/Related Content-type
- [RFC 6531](rfcs/rfc6531.txt) — SMTP Extension for Internationalized Email
- [RFC 6532](rfcs/rfc6532.txt) — Internationalized Email Headers
- [RFC 6854](rfcs/rfc6854.txt) — Update to Allow Group Syntax in From:/Sender:
