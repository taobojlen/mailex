# Mailex Parser - Conformance Testing TODO

Validate Mailex against real-world email parsing edge cases using test fixtures from established projects.

---

## 1. Email Address Parsing Conformance

### 1.1 isemail Test Suite

**Source:** [dominicsayers/isemail](https://github.com/dominicsayers/isemail/blob/master/test/tests-original.xml)

**Format:** XML with 156+ test cases

**Categories covered:**
- Valid RFC 5322 addresses
- RFC 5321 quoted strings and escaping
- IPv4 and IPv6 address literals
- Length violations (local-part >64, domain >255)
- Deprecated/obsolete forms (mixed quoted/unquoted atoms)
- Format errors (consecutive dots, unclosed quotes, etc.)

**Task:** Convert XML test cases to ExUnit tests for `AddressParser`

---

## 2. Full Message Parsing Conformance

### 2.1 Ruby mail gem fixtures

**Source:** [mikel/mail](https://github.com/mikel/mail/tree/master/spec/fixtures/emails)

**Format:** .eml files organized by category

**Categories:**
- `error_emails/` - 28 malformed email scenarios:
  - Bad date headers
  - Bad encoded subjects
  - Unparseable From fields
  - Content-Transfer-Encoding edge cases
  - Missing body/headers
  - Multiple Content-Types
  - Invalid character encodings
- `mime_emails/` - MIME structure edge cases
- `multi_charset/` - Character encoding variations
- `rfc2822/` - Standards compliance
- `rfc6532/` - Internationalized email

**Task:** Port relevant .eml fixtures and create ExUnit tests

### 2.2 Elixir ecosystem fixtures

**Source:** [DockYard/elixir-mail](https://github.com/DockYard/elixir-mail/tree/master/test/fixtures)

**Format:** .eml files (5 files)

**Categories:**
- Multipart with attachments
- Multipart without text parts
- Recursive/nested MIME structures
- Simple multipart
- Plain text

**Task:** Compare behavior with elixir-mail on shared fixtures

### 2.3 gen_smtp fixtures

**Source:** [gen-smtp/gen_smtp](https://github.com/gen-smtp/gen_smtp/tree/master/test/fixtures)

**Format:** .eml files

**Task:** Port relevant Erlang/Elixir ecosystem fixtures

---

## 3. Priority Order

1. **isemail address tests** - Most comprehensive, well-documented
2. **Ruby mail error_emails** - Real-world malformed messages
3. **Ruby mail mime_emails** - MIME edge cases
4. **Elixir-mail fixtures** - Same ecosystem comparison

---

## 4. Implementation Approach

### Step 1: Create test fixture directory
```
test/fixtures/conformance/
├── isemail/           # Converted from XML
├── mail-gem/          # Copied from mikel/mail
│   ├── error_emails/
│   └── mime_emails/
└── elixir-mail/       # Copied from DockYard
```

### Step 2: Write fixture loader
```elixir
defmodule Mailex.TestFixtures do
  def load_eml(path), do: File.read!(path)
  def load_isemail_tests(path), do: # Parse XML
end
```

### Step 3: Create conformance test modules
```elixir
# test/mailex/conformance/isemail_test.exs
# test/mailex/conformance/error_emails_test.exs
# test/mailex/conformance/mime_emails_test.exs
```

### Step 4: Document any intentional deviations
- Track cases where Mailex intentionally differs from other parsers
- Note cases that are "too broken" to parse (spam, etc.)

---

## References

- [dominicsayers/isemail](https://github.com/dominicsayers/isemail) - RFC 5321/5322 address validation
- [mikel/mail](https://github.com/mikel/mail) - Ruby mail gem with extensive fixtures
- [DockYard/elixir-mail](https://github.com/DockYard/elixir-mail) - Elixir mail library
- [gen-smtp/gen_smtp](https://github.com/gen-smtp/gen_smtp) - Erlang SMTP library
- [stalwartlabs/mail-parser](https://github.com/stalwartlabs/mail-parser) - Production Rust parser
