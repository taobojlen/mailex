# isemail Conformance Test Fixtures

Source: [dominicsayers/isemail](https://github.com/dominicsayers/isemail/blob/master/test/tests-original.xml)

Version: 3.04 (279 test cases)

## Test Categories

- `ISEMAIL_VALID_CATEGORY` - Valid RFC 5322 addresses
- `ISEMAIL_RFC5321` - Valid but use RFC 5321 features (quoted strings, address literals)
- `ISEMAIL_RFC5322` - Valid syntax but violate RFC 5322 recommendations (length limits, etc.)
- `ISEMAIL_DEPREC` - Deprecated/obsolete forms (still valid per RFC 5322 §4)
- `ISEMAIL_CFWS` - Contains comments or folding whitespace
- `ISEMAIL_DNSWARN` - Valid syntax but DNS warnings (no MX record, etc.)
- `ISEMAIL_ERR` - Invalid addresses (syntax errors)

## How We Use These Tests

For `Mailex.AddressParser` (a *parser*, not a full validator):

- `ISEMAIL_ERR` → must fail to parse
- All other categories → must parse successfully

This is because our parser validates syntax only, not:
- Length limits (local-part > 64, domain > 255, label > 63)
- DNS resolution
- SMTP-level constraints

## Control Character Encoding

The XML uses Unicode "control pictures" (U+2400 block) to represent ASCII control characters.
For example, `&#x240D;&#x240A;` represents CRLF. The test loader decodes these.

## Updating

To update from upstream:
1. Download from https://raw.githubusercontent.com/dominicsayers/isemail/master/test/tests-original.xml
2. Replace `tests-original.xml`
3. Re-run tests to check for regressions
