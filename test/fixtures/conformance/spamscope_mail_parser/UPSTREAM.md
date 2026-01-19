# SpamScope mail-parser Test Fixtures

## Source

- **Repository:** https://github.com/SpamScope/mail-parser
- **Directory:** https://github.com/SpamScope/mail-parser/tree/develop/tests/mails
- **Commit SHA:** 1c700e45cba7907d1ab34a5f9b95a276da956d61
- **License:** Apache-2.0 (see upstream repository)

## Files

- 18 standard `.eml` files (`mail_test_1` through `mail_test_18`)
- 3 malformed `.eml` files (`mail_malformed_1` through `mail_malformed_3`)
- 1 Outlook `.msg` file (`mail_outlook_1.msg`) - not used in tests

Total: 22 files

## Modifications

Files are byte-identical to upstream, with `.eml` extension added for clarity.

## Update Procedure

To update fixtures from upstream:

1. Check the latest commit SHA on the `develop` branch
2. Download new/changed files from `tests/mails/`
3. Update this file with the new commit SHA
4. Re-run tests and update `tests.exs` expectations as needed
