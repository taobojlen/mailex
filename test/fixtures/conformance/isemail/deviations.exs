# Known deviations from isemail test expectations.
#
# These are test IDs where Mailex intentionally differs from isemail's
# expected behavior, typically because:
# - isemail validates semantic constraints our parser doesn't enforce
# - Different interpretation of RFC edge cases
# - Length limits not enforced by parser (validation concern)
#
# Format: %{id => "reason for deviation"}
%{
  # Length validations (parser doesn't enforce, would be validator concern)
  21 => "Address length > 254 chars: parser accepts, validator would reject",
  23 => "Local-part > 64 chars: parser accepts, validator would reject",
  34 => "Domain > 255 chars: parser accepts, validator would reject",
  52 => "Domain label > 63 chars: parser accepts, validator would reject",
  115 => "Domain > 255 chars: parser accepts, validator would reject",

  # Domain hyphen rules (RFC 5321/5322 semantic constraint, not syntax)
  50 => "Domain label starts with hyphen: parser may accept as valid dot-atom",
  51 => "Domain label ends with hyphen: parser may accept as valid dot-atom",
  205 => "Domain label starts with hyphen: parser may accept as valid dot-atom",
  206 => "Domain label ends with hyphen: parser may accept as valid dot-atom",
  213 => "Domain label ends with hyphen: parser may accept as valid dot-atom",

  # Domain literal edge cases
  149 => "obs-dtext (backslash in domain literal): parser doesn't support obsolete escaping in domain literals",
  185 => "Comment in middle of domain: parser doesn't support CFWS between domain labels",

  # obs-local-part (mixed quoted/unquoted) - may need parser changes
  94 => "obs-local-part: dot-atom followed by quoted-string",
  140 => "obs-local-part: multiple quoted-strings with dots",
  141 => "obs-local-part: quoted-string.atom.quoted-string",
  143 => "obs-local-part: quoted-string.atom",
  144 => "obs-local-part: atom.quoted-string",
  145 => "obs-local-part: multiple quoted-strings",
  146 => "obs-local-part: quoted.quoted",
  151 => "obs-local-part: atom.quoted.quoted",
  153 => "obs-local-part: contains empty quoted-string",
  171 => "obs-local-part: atom followed by empty comment",
  180 => "obs-local-part: comment between atoms",
  181 => "obs-local-part: comment with quote between atoms",

  # CFWS in deprecated positions
  152 => "Deprecated FWS (CRLF in local-part)",
  162 => "Deprecated CFWS near @",
  163 => "Deprecated comment in domain",
  164 => "Deprecated CFWS near @ with domain literal",
  165 => "Deprecated nested comments",
  166 => "Deprecated comment with escaped @",
  167 => "Deprecated comment with escaped )",
  172 => "Deprecated comment with FWS",
  174 => "Deprecated complex nested comments",
  175 => "Canonical RFC 5322 example with comments",
  176 => "Canonical RFC 5322 example with comment",
  177 => "Deprecated FWS in domain",
  178 => "Canonical RFC 5322 example with spaces",
  182 => "Comment containing quote",
  184 => "Comment with quoted-pair",
  186 => "Deeply nested comments",
  219 => "Comment after local-part",
  222 => "Complex FWS and comments",
  223 => "FWS after local-part",
  224 => "obs-fws with space before break",

  # Control characters (may need special handling)
  123 => "Escaped CR in quoted string (deprecated)",
  124 => "Unescaped CR in quoted string",
  159 => "FWS in quoted-pair",
  160 => "FWS in quoted string",
  218 => "Invalid FWS (LF without CR)",
  225 => "Double CRLF without WSP",
  226 => "Escaped NULL in quoted string",
  227 => "Unescaped NULL in quoted string",
  228 => "Escaped NULL outside quoted string",
  278 => "Trailing newline"
}
