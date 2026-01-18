# RFC Compliance TODO

This document lists the gaps between the current Mailex parser implementation and full RFC compliance for email message parsing.

---

## 1. Header Field Parsing

### 1.2 Header unfolding trims whitespace incorrectly

**Status:** Partially Implemented (buggy)

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

**Status:** Not Implemented

**Problem:** Parser stops headers when `header_field` fails. Any malformed header line (missing `:`) prematurely ends headers and treats remainder as body. Robust parsers should detect end-of-headers strictly by a blank line.

**RFCs:**
- RFC 5322 §2.2 — Message format is header fields, then CRLF, then body

**Implementation:**
- Detect end-of-headers by blank line only, not by `header_field` parse failure
- Option: accumulate malformed lines under a special key, or attach to previous field body

---

## 2. Message-ID Parsing

### 2.1 No parsing for Message-ID / In-Reply-To / References

**Status:** Not Implemented

**Problem:** These are stored as raw header values only. No validation or extraction of msg-id tokens.

**RFCs:**
- RFC 5322 §3.6.4 — Identification Fields
- `msg-id = [CFWS] "<" id-left "@" id-right ">" [CFWS]`
- `In-Reply-To` and `References` contain one or more msg-ids

**Implementation:**
- Add a combinator for `msg-id` and `msg-id-list`
- Handle CFWS around angle brackets and separators
- Extract list of message IDs from `References` for threading

---

## 3. MIME Type/Subtype Handling

### 3.1 Content-Type parsing breaks on quoted-strings and comments

**Status:** ✅ Implemented (quoted-strings fixed, comments not yet handled)

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

**Status:** Partially Implemented

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

**Status:** Partially Implemented (incomplete)

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
- Properly parse quoted-string with escape handling
- Reuse for MIME params (`charset="utf-8"`) and display names (`"Last, First" <a@b>`)
- Handle folding whitespace within quoted-strings

---

## 7. Internationalized Email Support

### 7.1 RFC 6532 UTF-8 headers not supported

**Status:** Not Implemented

**Problem:** Header body parsing rejects non-ASCII bytes (see 1.1). RFC 6532 allows raw UTF-8 directly in headers without RFC 2047 encoding.

**RFCs:**
- RFC 6532 §3 — UTF-8 in message headers
- RFC 6532 §3.2 — Syntax Extensions to RFC 5322

**Implementation:**
- Allow raw UTF-8 bytes in header field bodies
- Update structured parsers (addresses, phrases) to accept UTF-8 where RFC 6532 permits
- Keep field-names ASCII-only (RFC 6532 does not allow UTF-8 field names)

---

### 7.2 Internationalized email addresses not supported

**Status:** Not Implemented

**Problem:** Non-ASCII local-parts and domains (EAI - Email Address Internationalization) cannot be parsed because address parsing doesn't exist.

**RFCs:**
- RFC 6532 — Address internationalization in headers
- RFC 6531 — SMTPUTF8 transport
- RFC 5890/5891 — IDNA (Internationalized Domain Names)

**Implementation:**
- When implementing `addr-spec`, permit UTF-8 in local-part and domain
- Consider returning both original UTF-8 address and ASCII-compatible (punycode) domain form

---

## 8. multipart/related Support

### 8.1 Root part resolution not implemented

**Status:** Not Implemented

**Problem:** multipart/related messages have `start` and `type` parameters to identify the "root" part. Currently these are parsed as generic parameters but not interpreted. Clients cannot reliably determine which part is the main document vs related resources.

**RFCs:**
- RFC 2387 §3 — The Multipart/Related Content-Type
- RFC 2387 §3.1 — The Type Parameter (MIME type of root)
- RFC 2387 §3.2 — The Start Parameter (Content-ID of root)

**Implementation:**
When `content-type` is `multipart/related`:
- Parse `start` parameter (a Content-ID reference)
- Parse `type` parameter (expected MIME type of root)
- Identify root part: if `start` exists, find part whose `Content-ID` matches (note angle brackets); else first part is root
- Store in parsed structure: `message.related_root_index` or flag on the root part

---

## 9. Content-Disposition Improvements

### 9.1 Disposition type and additional parameters not exposed

**Status:** Partially Implemented

**Problem:** `parse_disposition_params/1` uses `String.split(disposition, ";")` which:
- Ignores disposition-type token (`inline`/`attachment`/extension-token)
- Doesn't expose other standard params: `creation-date`, `modification-date`, `read-date`, `size`
- Fails on quoted-strings containing `;`

**RFCs:**
- RFC 2183 §2 — Content-Disposition header field
- RFC 2183 §2.1-2.4 — Parameters: filename, creation-date, modification-date, read-date, size

**Implementation:**
- Parse disposition-type as a token
- Use proper MIME parameter parser (same as Content-Type)
- Expose full params map, not just filename
- Optionally parse `size` as integer and `*-date` params as RFC 5322 date-time

---

### 9.2 RFC 2231 parameter handling edge cases

**Status:** Partially Implemented (edge cases)

**Problem:** RFC 2231 implementation may have issues with:
1. **Precedence:** If both `filename` and `filename*` exist, `filename*` should win
2. **Continuations:** `filename*0*=` includes `charset'lang'...` only in first segment; later segments are percent-encoded without repeating charset/lang
3. **Decoding order:** Percent-decode bytes first, then charset convert
4. **Quoted-strings:** Extended values are NOT quoted-strings; avoid unquoting before percent-decoding

**RFCs:**
- RFC 2231 §3 — Parameter Value Extensions
- RFC 2231 §4 — Continuations

**Implementation:**
- Collect segments in order (`*0*`, `*1*`...)
- First segment: parse `charset'lang'bytes`
- Subsequent segments: just percent-encoded bytes (no charset prefix)
- Percent-decode all bytes, then convert from charset to UTF-8 once at end
- Ensure `param*` takes precedence over `param` in final params map

---

## 10. RFC 2047 Encoded-Word Improvements

### 10.1 RFC 2047 decoding is not charset-aware

**Status:** Partially Implemented (buggy)

**Problem:** `decode_rfc2047/1` decodes Base64/Q to bytes but never converts from declared charset to UTF-8. Also missing adjacent encoded-word whitespace handling.

**RFCs:**
- RFC 2047 §2 — Encoded-word syntax
- RFC 2047 §6.2 — Whitespace between adjacent encoded-words should be ignored

**Implementation:**
- Extract charset from encoded-word
- Decode bytes (Base64 or Q)
- Convert bytes from charset to UTF-8 using `convert_charset/2`
- Collapse whitespace between adjacent encoded-words (linear whitespace between `?=` and `=?` should be ignored)

---

### 10.2 RFC 2047 only applied to filename, not other headers

**Status:** Partially Implemented

**Problem:** RFC 2047 decoding is only applied to filename extraction. Should also be applied to:
- Subject header
- Display-names in address headers
- Comments header
- Any unstructured header exposed to users

**RFCs:**
- RFC 2047 §5 — Use of encoded-words in message headers

**Implementation:**
- Apply RFC 2047 decoding to unstructured headers: Subject, Comments
- Apply to display-name portion of addresses after address parsing
- Apply to comments within structured fields if comments are preserved

---

## 11. Multipart Boundary Parsing

### 11.1 Boundary delimiter parsing not fully RFC-compliant

**Status:** Partially Implemented (edge cases)

**Problem:** `split_multipart/2` uses regex to detect boundary at start-of-line but doesn't enforce full delimiter-line structure:
- Boundary delimiter line is `--boundary` + optional transport padding (LWSP) + CRLF
- Closing delimiter is `--boundary--` + optional transport padding + CRLF
- Current regex might match boundary as prefix of longer line content

**RFCs:**
- RFC 2046 §5.1.1 — Common Syntax (boundary delimiter line definition)

**Implementation:**
Parse multipart by scanning line-by-line:
- Match lines that are exactly delimiter or close-delimiter
- Allow trailing whitespace (transport padding) on delimiter lines
- More correct and simpler than regex splitting

---

## Implementation Priority

Suggested order based on impact and dependencies:

### Phase 1: Foundation (High Impact)
1. **1.2** Fix header unfolding to not trim whitespace

### Phase 2: Lexical Primitives (Enables Everything Else)
2. **6.1** Implement proper `quoted-string` parsing with escapes
3. **5.1** Implement CFWS/comment handling
4. Implement `token` parser per RFC 2045

### Phase 3: MIME Parsing Rebuild
5. **3.1** Rebuild Content-Type parser using primitives
6. **9.1** Rebuild Content-Disposition parser
7. **9.2** Fix RFC 2231 edge cases

### Phase 4: Structured Header Parsing
8. **2.1** Implement Message-ID parsing

### Phase 5: Enhanced Features
9. **8.1** Add multipart/related root resolution
10. **10.1** Fix RFC 2047 charset conversion
11. **10.2** Apply RFC 2047 to more headers
12. **7.1** Full RFC 6532 UTF-8 header support
13. **7.2** Internationalized address support

### Phase 6: Robustness
14. **4.1** Add obsolete syntax tolerance
15. **1.3** Improve malformed header handling
16. **3.2** Complete Content-Type defaults
17. **11.1** Improve multipart boundary parsing

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
