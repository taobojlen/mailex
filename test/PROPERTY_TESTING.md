# Property testing

The `property-discovery` branch contains StreamData generators, independent
models, serializers, and the integrated fixes. Each fix branch starts at `main`
and contains only its deterministic regression and production change. The fix
branches do not require StreamData. The independent fix branches are local to
the investigation orb.

The exception-handling regressions cover applications parsing untrusted messages.
They demonstrate parser and conversion failures, not application-level security
impact or exploitability.

The approach follows [Property Testing with Agent Swarms](https://recursion.wtf/posts/agents-and-property-tests/)
and [proptest-praxis](https://github.com/inanna-malick/agent-skills/blob/main/skills/proptest-praxis/SKILL.md).

## Run

```sh
mix deps.get
MIX_ENV=test mix compile --warnings-as-errors
mix format --check-formatted
mix test
PROPERTY_RUNS=5000 mix test test/mailex/property_discovery_test.exs --seed 314159
mix test --exclude discovery
```

`PROPERTY_RUNS` sets the case count for each property; the default is 200.
ExUnit's `--seed` drives StreamData, including shrinking. Failures print the
reduced generated values. Keep those values, not just the seed, because generator
changes can change the cases a seed produces. The deterministic regressions in
the existing test files retain the confirmed witnesses.

This orb has the pinned Elixir 1.19.5 / OTP 28 toolchain through mise. Prefix
commands with `$HOME/.local/bin/mise exec --` to select it explicitly. Elixir
1.18.4 / OTP 25 is also available with
`PATH=/tmp/mailex-elixir/bin:/usr/bin:/bin MIX_HOME=$HOME/.mix`. Both toolchains
pass compilation, formatting, and the coverage command. Validation on the
repository's full CI version matrix is not included.

## Targets and oracles

| Target | Independent check | Interactions |
| --- | --- | --- |
| Date parsing and conversion | Elixir calendar constructors and UTC timestamp arithmetic | Signed offsets, midnight, date rollover, comments, folding, leap seconds, invalid calendar dates |
| Address parsing and API validation | Generated mailbox/group trees and explicit cardinality/type rules | Quoted separators, escaped quotes/backslashes, Unicode, groups, duplicate addresses, malformed suffixes |
| MIME parameters | Known source strings and a direct Latin-1 byte-to-codepoint model | Out-of-order segments, precedence, mixed encoded/unencoded segments, charset across segments, UTF-8 split inside characters, malformed escapes |
| RFC 2047 headers | Independently encode B/Q words and compare with source text | Mixed encodings, adjacent words, folded separators, plain lookalikes, Unicode, punctuation |
| Body transfer encodings | Byte-for-byte encode/parse round trips | Arbitrary octets, base64 padding, narrow line wrapping, quoted-printable soft breaks, LF/CRLF |
| Header histories | Recompute grouped headers and reference IDs from the operation list | Small key/value pools, interleaved duplicates, mixed key case, folded fields, observation after every prefix |
| Multipart state machine | Replay explicit delimiter/content events against a separate state model | Near-misses, repeated opens, transport padding, EOF without close, preamble, epilogue, operations after close |
| Recursive MIME | Serialize generated trees and compare payload/container/root views | Mixed, related, digest, embedded messages, overlapping boundary prefixes, implicit versus explicit types |
| Comments | Generate syntax trees and compute the reconstructed and stripped text | Unicode, nested comments, escaped delimiters, quoted literals, message-ID extraction |
| Unencoded binary content | Exact octet comparison through three container paths | Embedded CRLF and LF, invalid UTF-8 octets, trailing whitespace, multipart encapsulation newline versus EOF |

Stateful tests exercise the multipart parser and evolving header histories.
There is no mutable store or streaming public API to model. Header histories
parse each prefix from scratch; they do not claim to test a cache.

The multipart generator weights closed histories, early-close controls, and
unterminated histories 4:1:2. Live prefixes cannot close early and hide the forced
open → content → near-miss → open interaction. Its model takes event semantics
from the generated AST, not from production boundary recognition. Nested MIME
boundaries share prefixes but do not collide. RFC 2047 words are at most 60
characters, below the standard's 75-character limit.

## Reviewable fixes

Every row has a deterministic regression that fails without its fix. Every
isolated branch passes the complete existing suite, formatting, and compilation
with warnings as errors, using seed 424242.

| Local branch | Confirmed contract violation | Tests on that branch |
| --- | --- | --- |
| `fix/utc-rollover` | A positive offset crossing midnight produces the wrong UTC date | 740 pass |
| `fix/quoted-addr-spec` | `@` inside a quoted local-part becomes a separator; addr-spec accepts mailbox-only syntax | 741 pass |
| `fix/rfc2231-charset` | Later continuation bytes do not use the first segment's charset | 740 pass |
| `fix/digest-default` | An implicit digest part has message/rfc822 metadata but no parsed embedded message | 740 pass |
| `fix/encoded-word-whitespace` | Plain encoded-word lookalikes lose intervening whitespace | 740 pass |
| `fix/quoted-unicode` | UTF-8 address syntax is rejected in quoted strings, comments, and domain literals | 740 pass |
| `fix/binary-body-preservation` | Normalization and multipart line reconstruction change binary body octets | 740 pass |
| `private/unicode-comments` | Comment reconstruction corrupts Unicode and can raise for nested comments in Message-ID | 740 pass |
| `private/extended-parameters` | Invalid percent escapes raise instead of using the parser's tolerant decoding behavior | 740 pass |
| `private/date-conversion-errors` | Unrepresentable dates and leap seconds raise instead of returning conversion errors | 740 pass |

The `private/` branch prefix identifies the exception-handling fixes, not a claim
of an exploitable vulnerability. Nested Unicode comments are a demonstrated
public `Mailex.parse/1` exception path; a single non-nested Unicode comment is not
the same failure. Date errors require a caller to invoke a conversion function.

## Validation and calibration

The integrated suite reports **19 properties, 752 tests, and zero failures**.
Full runs use 5,000 cases per property with seeds **314159, 271828, and 8675309**:
285,000 generated cases in total, excluding earlier discovery runs. Many cases
contain multiple API calls or a full operation history.

Four deliberate mutations are detected individually with seed 424242. All are
removed, and the production files match the committed fixes.

| Mutation | Detecting property | Successful cases before detection | Reduced witness |
| --- | --- | --- | --- |
| Prepend a third duplicate header value | Header histories | 8 | References values 0, 0, 1 |
| Accept arbitrary closing-boundary suffixes | Multipart event model | 0 | `--a--X` inside the first of two parts |
| Always choose related root index 0 | Recursive MIME tree model | 0 | Embedded related message with two parts and root 1 |
| Skip nonterminal quoted-printable soft breaks | Binary transfer round trip | 7 | Three NUL bytes, wrapping width 1 |

The charset fixture suite checks fixed byte-to-Unicode witnesses for all 33
supported legacy charset labels, including both Windows aliases and normalized
uppercase/underscore spellings. Expected characters are independently checked
against Python's standard codecs. Each label is exercised through public message
parsing for both RFC 2047 headers and base64 bodies. Undefined bytes in a known
charset and unknown charsets must preserve the transfer-decoded bytes. Mapping
`cp1258` to CP1252 deliberately makes the charset test fail with seed 577215;
that mutation is removed.

`PROPERTY_RUNS=1000 mix test --cover --seed 577215` passes with **94.12%**
coverage on both toolchains. `mix test --cover --seed 424242 --exclude discovery`
passes with **90.59%** coverage, so meeting Mix's default 90% threshold does not
depend on generated cases. No threshold or coverage exclusions are changed.
Compilation, formatting, and non-coverage test commands pass.

Remaining limits include recursive MIME depth 2, bounded operation histories,
and incomplete byte-table coverage within each legacy charset. Some parser error/fallback
branches are not reached. The tests respect intentional trailing-text trimming
and do not assert strict rejection of every malformed email or inconsistent
weekday. Passing random runs do not establish exhaustive RFC conformance or
absence of security issues.

## Local performance validation

CodSpeed CLI 5.2.1 and exec-harness 1.3.0 run the eight existing workloads
locally without uploading results. The orb uses Elixir 1.19.5 / OTP 28.4 on two
CPUs. Native profiling and CPU isolation are disabled; BEAM eprof provides
separate diagnostic profiles.

```sh
MIX_ENV=prod mise exec -- mix compile --warnings-as-errors
PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH" \
  MIX_ENV=prod CODSPEED_ISOLATION=false CODSPEED_PROFILER_ENABLED=false \
  CODSPEED_PERF_ENABLED=false \
  mise exec -- codspeed run --mode walltime --skip-upload --skip-setup
```

Both checkouts use the same runtime, dependency versions, fixtures, script
iteration counts, and `codspeed.yml`. Each has its own production build.
The reference is `main` at [`b9787ab`](https://github.com/taobojlen/mailex/commit/b9787ab94be4553e9fb649bf09a4be28ccf3a093).
Three serial baseline/branch pairs yield these medians of block medians.
Times include BEAM startup; a negative change means faster execution.

| Workload | Main, ms | Branch, ms | Change |
| --- | ---: | ---: | ---: |
| Plain text | 802.9 | 737.6 | −8.1% |
| Nested multipart | 882.1 | 754.4 | −14.5% |
| Attachments | 768.5 | 674.1 | −12.3% |
| Large message | 830.1 | 636.3 | −23.3% |
| Encoded headers | 640.1 | 653.7 | +2.1% |
| Conformance corpus | 858.5 | 790.5 | −7.9% |
| Addresses | 709.2 | 653.4 | −7.9% |
| Dates | 545.1 | 521.1 | −4.4% |

The encoded-header signal does not reproduce in longer, order-balanced blocks.
Four 30-second blocks in baseline → branch → branch → baseline order measure
646.9 ms versus 632.6 ms (−2.2%). Fifteen alternating warm-parser pairs using
the same five fixtures and 550 iterations measure 219.4 ms versus 211.9 ms
(−3.4%); every pair favors the branch and all checksums match. Warm-parser
measurements exclude startup and are not CodSpeed scores.

The multipart parser uses byte offsets to retain actual line terminators.
Delimiter handling removes exactly one LF or CRLF; EOF retains payload bytes.
Public results match the [reference parser](https://github.com/taobojlen/mailex/commit/b1d8a3f7fc23d024a591ece50d63b8e9d0eb35a1) on 225 message fixtures and 2,000
generated binary multipart controls. A deliberately retained CR at a CRLF
boundary changes the result and is detected by the equivalence comparison.

These measurements establish no reproducible regression in the eight workloads
on this orb. They do not guarantee performance for every input, runtime, host,
or CI runner. Shared-host walltime noise and process startup limit precision.
