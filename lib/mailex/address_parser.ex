defmodule Mailex.AddressParser do
  @moduledoc """
  RFC 5322 email address parser using NimbleParsec.

  Parses email addresses according to RFC 5322 §3.4, including:
  - addr-spec (simple address like user@domain)
  - mailbox (with optional display-name)
  - group (named list of mailboxes)
  - address-list (comma-separated addresses)

  Supports obsolete syntax (RFC 5322 §4.4):
  - obs-phrase (periods in display names)
  - obs-local-part (CFWS between parts)

  Supports RFC 6532 internationalized email addresses (EAI):
  - UTF-8 characters in local-part
  - UTF-8 characters in domain (internationalized domain names)
  - UTF-8 characters in display-name
  """

  import NimbleParsec

  # ===========================================================================
  # Lexical primitives (RFC 5322 §3.2)
  # ===========================================================================

  wsp = ascii_char([?\s, ?\t])
  crlf = choice([string("\r\n"), string("\n")])

  fws =
    choice([
      crlf |> concat(times(wsp, min: 1)),
      times(wsp, min: 1)
    ])
    |> ignore()

  quoted_pair =
    ignore(string("\\"))
    |> ascii_char([0x00..0x7F])

  ctext = ascii_char([0x21..0x27, 0x2A..0x5B, 0x5D..0x7E])

  defcombinatorp :comment_content,
    repeat(
      choice([
        ctext |> ignore(),
        quoted_pair |> ignore(),
        parsec(:nested_comment),
        fws
      ])
    )

  defcombinatorp :nested_comment,
    ignore(ascii_char([?(]))
    |> concat(parsec(:comment_content))
    |> ignore(ascii_char([?)]))

  comment =
    ignore(ascii_char([?(]))
    |> concat(parsec(:comment_content))
    |> ignore(ascii_char([?)]))

  # Use defcombinatorp for cfws to reduce code duplication - this is used ~13 times
  # and generates substantial code for comment parsing. Using parsec(:cfws) generates
  # a function call instead of inlining all the code each time.
  defcombinatorp :cfws, times(choice([fws, comment]), min: 1) |> ignore()
  defcombinatorp :optional_cfws, optional(parsec(:cfws))

  # RFC 5322 atext: printable ASCII characters excluding specials
  ascii_atext = ascii_char([?a..?z, ?A..?Z, ?0..?9, ?!, ?#, ?$, ?%, ?&, ?', ?*, ?+, ?-, ?/, ?=, ??, ?^, ?_, ?`, ?{, ?|, ?}, ?~])

  # RFC 6532 UTF8-non-ascii: any UTF-8 character outside ASCII range (codepoints > 127)
  # Use explicit range 128..0x10FFFF for better NimbleParsec code generation
  utf8_non_ascii = utf8_char([0x80..0x10FFFF])

  # Combined atext that supports both ASCII and UTF-8 (RFC 5322 + RFC 6532)
  atext = choice([ascii_atext, utf8_non_ascii])

  # Define dot_atom_text as a combinator to share code
  defcombinatorp :dot_atom_text,
    times(atext, min: 1)
    |> repeat(string(".") |> concat(times(atext, min: 1)))
    |> reduce({__MODULE__, :codepoints_to_string, []})

  dot_atom_text = parsec(:dot_atom_text)

  qtext = ascii_char([0x21, 0x23..0x5B, 0x5D..0x7E])

  qcontent = choice([qtext, quoted_pair])

  quoted_string_inner =
    ignore(ascii_char([?"]))
    |> repeat(choice([qcontent, wsp |> replace(?\s)]))
    |> ignore(ascii_char([?"]))
    |> reduce({:erlang, :list_to_binary, []})

  _quoted_string =
    parsec(:optional_cfws)
    |> concat(quoted_string_inner)
    |> concat(parsec(:optional_cfws))

  # ===========================================================================
  # Address components (RFC 5322 §3.4)
  # ===========================================================================

  local_part =
    choice([
      quoted_string_inner |> unwrap_and_tag(:quoted_local),
      dot_atom_text |> unwrap_and_tag(:dot_local)
    ])

  dtext = ascii_char([0x21..0x5A, 0x5E..0x7E])

  domain_literal_inner =
    string("[")
    |> repeat(choice([dtext, wsp]))
    |> string("]")
    |> reduce({:erlang, :list_to_binary, []})

  domain =
    choice([
      domain_literal_inner |> unwrap_and_tag(:domain_literal),
      dot_atom_text |> unwrap_and_tag(:dot_domain)
    ])

  # Note: addr_spec is defined for reference but the defparsec was removed
  # to improve compile time. We parse via address_list and extract results.
  _addr_spec =
    parsec(:optional_cfws)
    |> concat(local_part)
    |> ignore(parsec(:optional_cfws))
    |> ignore(string("@"))
    |> ignore(parsec(:optional_cfws))
    |> concat(domain)
    |> concat(parsec(:optional_cfws))
    |> post_traverse({__MODULE__, :build_addr_spec, []})

  angle_addr =
    parsec(:optional_cfws)
    |> ignore(string("<"))
    |> ignore(parsec(:optional_cfws))
    |> concat(local_part)
    |> ignore(parsec(:optional_cfws))
    |> ignore(string("@"))
    |> ignore(parsec(:optional_cfws))
    |> concat(domain)
    |> ignore(parsec(:optional_cfws))
    |> ignore(string(">"))
    |> concat(parsec(:optional_cfws))
    |> post_traverse({__MODULE__, :build_addr_spec, []})

  phrase_word =
    choice([
      quoted_string_inner,
      dot_atom_text,
      string(".")
    ])

  phrase =
    parsec(:optional_cfws)
    |> concat(phrase_word)
    |> repeat(
      choice([
        times(wsp, min: 1) |> replace(" ") |> concat(phrase_word),
        phrase_word
      ])
    )
    |> concat(parsec(:optional_cfws))
    |> reduce({__MODULE__, :join_phrase, []})

  name_addr =
    phrase
    |> unwrap_and_tag(:display_name)
    |> concat(angle_addr)
    |> post_traverse({__MODULE__, :build_name_addr, []})

  bare_angle_addr =
    parsec(:optional_cfws)
    |> ignore(string("<"))
    |> ignore(parsec(:optional_cfws))
    |> concat(local_part)
    |> ignore(parsec(:optional_cfws))
    |> ignore(string("@"))
    |> ignore(parsec(:optional_cfws))
    |> concat(domain)
    |> ignore(parsec(:optional_cfws))
    |> ignore(string(">"))
    |> concat(parsec(:optional_cfws))
    |> post_traverse({__MODULE__, :build_bare_mailbox, []})

  bare_addr_spec =
    parsec(:optional_cfws)
    |> concat(local_part)
    |> ignore(parsec(:optional_cfws))
    |> ignore(string("@"))
    |> ignore(parsec(:optional_cfws))
    |> concat(domain)
    |> concat(parsec(:optional_cfws))
    |> concat(optional(comment))
    |> post_traverse({__MODULE__, :build_bare_mailbox, []})

  mailbox = choice([name_addr, bare_angle_addr, bare_addr_spec])

  mailbox_sep = parsec(:optional_cfws) |> ignore(string(",")) |> concat(parsec(:optional_cfws))

  mailbox_list =
    optional(mailbox)
    |> repeat(mailbox_sep |> concat(optional(mailbox)))
    |> post_traverse({__MODULE__, :collect_list, []})

  group =
    parsec(:optional_cfws)
    |> concat(phrase |> unwrap_and_tag(:group_name))
    |> ignore(string(":"))
    |> concat(parsec(:optional_cfws))
    |> concat(tag(optional(mailbox_list), :members))
    |> ignore(parsec(:optional_cfws))
    |> ignore(string(";"))
    |> concat(parsec(:optional_cfws))
    |> post_traverse({__MODULE__, :build_group, []})

  address = choice([group, mailbox])

  address_sep = parsec(:optional_cfws) |> ignore(string(",")) |> concat(parsec(:optional_cfws))

  address_list =
    repeat(address_sep)
    |> concat(optional(address))
    |> repeat(address_sep |> concat(optional(address)))
    |> post_traverse({__MODULE__, :collect_list, []})

  # ===========================================================================
  # Parser definitions
  # ===========================================================================

  # Only generate one parser entry point to reduce compile time.
  # NimbleParsec generates substantial code for each defparsec, so minimizing
  # entry points significantly improves compilation speed.
  #
  # The other parse_* functions reuse this parser and validate results.
  defparsec :do_parse_address_list, address_list |> eos()

  # ===========================================================================
  # Public API
  # ===========================================================================

  @doc """
  Parses an addr-spec (bare email address without display name).

  Returns `{:ok, map}` with `:local_part` and `:domain` keys on success.

  ## Examples

      iex> Mailex.AddressParser.parse_addr_spec("user@example.com")
      {:ok, %{local_part: "user", domain: "example.com"}}

      iex> Mailex.AddressParser.parse_addr_spec("\"quoted.user\"@example.com")
      {:ok, %{local_part: "quoted.user", domain: "example.com"}}

  """
  @spec parse_addr_spec(binary()) :: {:ok, map()} | {:error, term()}
  def parse_addr_spec(input) when is_binary(input) do
    # Parse as address list and extract addr-spec components
    case parse_address_list(input) do
      {:ok, [%{type: :mailbox, address: addr}]} ->
        case String.split(addr, "@", parts: 2) do
          [local, domain] -> {:ok, %{local_part: local, domain: domain}}
          _ -> {:error, "invalid addr-spec"}
        end
      {:ok, _} -> {:error, "expected single addr-spec"}
      error -> error
    end
  end

  @doc """
  Parses a mailbox (email address with optional display name).

  Returns `{:ok, map}` with `:type`, `:name`, and `:address` keys on success.

  ## Examples

      iex> Mailex.AddressParser.parse_mailbox("user@example.com")
      {:ok, %{type: :mailbox, name: nil, address: "user@example.com"}}

      iex> Mailex.AddressParser.parse_mailbox("John Doe <john@example.com>")
      {:ok, %{type: :mailbox, name: "John Doe", address: "john@example.com"}}

      iex> Mailex.AddressParser.parse_mailbox("\"John Doe\" <john@example.com>")
      {:ok, %{type: :mailbox, name: "John Doe", address: "john@example.com"}}

  """
  @spec parse_mailbox(binary()) :: {:ok, map()} | {:error, term()}
  def parse_mailbox(input) when is_binary(input) do
    case parse_address_list(input) do
      {:ok, [%{type: :mailbox} = result]} -> {:ok, result}
      {:ok, [%{type: :group}]} -> {:error, "expected mailbox, got group"}
      {:ok, _} -> {:error, "expected single mailbox"}
      error -> error
    end
  end

  @doc """
  Parses an RFC 5322 group (named list of mailboxes).

  Returns `{:ok, map}` with `:type`, `:name`, and `:members` keys on success.

  ## Examples

      iex> Mailex.AddressParser.parse_group("Team: alice@example.com, bob@example.com;")
      {:ok, %{type: :group, name: "Team", members: [
        %{type: :mailbox, name: nil, address: "alice@example.com"},
        %{type: :mailbox, name: nil, address: "bob@example.com"}
      ]}}

      iex> Mailex.AddressParser.parse_group("Empty:;")
      {:ok, %{type: :group, name: "Empty", members: []}}

  """
  @spec parse_group(binary()) :: {:ok, map()} | {:error, term()}
  def parse_group(input) when is_binary(input) do
    case parse_address_list(input) do
      {:ok, [%{type: :group} = result]} -> {:ok, result}
      {:ok, [%{type: :mailbox}]} -> {:error, "expected group, got mailbox"}
      {:ok, _} -> {:error, "expected single group"}
      error -> error
    end
  end

  @doc """
  Parses a single address (either a mailbox or a group).

  Returns `{:ok, map}` on success. The result has `:type` key that is
  either `:mailbox` or `:group`.

  ## Examples

      iex> Mailex.AddressParser.parse_address("user@example.com")
      {:ok, %{type: :mailbox, name: nil, address: "user@example.com"}}

      iex> Mailex.AddressParser.parse_address("Team: user@example.com;")
      {:ok, %{type: :group, name: "Team", members: [...]}}

  """
  @spec parse_address(binary()) :: {:ok, map()} | {:error, term()}
  def parse_address(input) when is_binary(input) do
    case parse_address_list(input) do
      {:ok, [result]} -> {:ok, result}
      {:ok, _} -> {:error, "expected single address"}
      error -> error
    end
  end

  @doc """
  Parses a comma-separated list of addresses.

  Returns `{:ok, list}` where each element is a mailbox or group map.

  ## Examples

      iex> Mailex.AddressParser.parse_address_list("alice@example.com, bob@example.com")
      {:ok, [
        %{type: :mailbox, name: nil, address: "alice@example.com"},
        %{type: :mailbox, name: nil, address: "bob@example.com"}
      ]}

      iex> Mailex.AddressParser.parse_address_list("Alice <alice@example.com>, Team: bob@example.com;")
      {:ok, [
        %{type: :mailbox, name: "Alice", address: "alice@example.com"},
        %{type: :group, name: "Team", members: [...]}
      ]}

  """
  @spec parse_address_list(binary()) :: {:ok, [map()]} | {:error, term()}
  def parse_address_list(input) when is_binary(input) do
    case do_parse_address_list(input) do
      {:ok, [result], "", _, _, _} -> {:ok, result}
      {:ok, _, rest, _, _, _} -> {:error, "unexpected input: #{inspect(rest)}"}
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end

  # ===========================================================================
  # Builder functions (called by post_traverse)
  # ===========================================================================

  def build_addr_spec(rest, args, context, _line, _offset) do
    {local, domain} = extract_local_domain(args)
    result = %{local_part: local, domain: domain}
    {rest, [result], context}
  end

  def build_bare_mailbox(rest, args, context, _line, _offset) do
    {local, domain} = extract_local_domain(args)
    address = "#{local}@#{domain}"
    result = %{type: :mailbox, name: nil, address: address}
    {rest, [result], context}
  end

  def build_name_addr(rest, args, context, _line, _offset) do
    {display_name, addr} = extract_name_addr(args)
    address = "#{addr.local_part}@#{addr.domain}"
    result = %{type: :mailbox, name: String.trim(display_name), address: address}
    {rest, [result], context}
  end

  def build_group(rest, args, context, _line, _offset) do
    {name, members} = extract_group(args)
    result = %{type: :group, name: String.trim(name), members: members}
    {rest, [result], context}
  end

  def collect_list(rest, args, context, _line, _offset) do
    items = args |> Enum.filter(&is_map/1) |> Enum.reverse()
    {rest, [items], context}
  end

  def join_phrase(parts) do
    parts
    |> Enum.map(&to_string/1)
    |> Enum.join("")
    |> String.trim()
  end

  # ===========================================================================
  # Helper functions
  # ===========================================================================

  @doc false
  # Converts a list of Unicode codepoints and strings to a UTF-8 binary.
  # This handles the output from utf8_char which returns codepoints as integers.
  def codepoints_to_string(parts) do
    parts
    |> Enum.map(fn
      cp when is_integer(cp) -> <<cp::utf8>>
      str when is_binary(str) -> str
    end)
    |> IO.iodata_to_binary()
  end

  defp extract_local_domain(args) do
    local = find_local(args)
    domain = find_domain(args)
    {local, domain}
  end

  defp find_local(args) do
    Enum.find_value(args, fn
      {:quoted_local, val} -> val
      {:dot_local, val} -> val
      _ -> nil
    end)
  end

  defp find_domain(args) do
    Enum.find_value(args, fn
      {:domain_literal, val} -> val
      {:dot_domain, val} -> val
      _ -> nil
    end)
  end

  defp extract_name_addr(args) do
    display_name = Enum.find_value(args, fn
      {:display_name, name} -> name
      _ -> nil
    end)

    addr = Enum.find(args, &is_map/1)
    {display_name || "", addr}
  end

  defp extract_group(args) do
    name = Enum.find_value(args, fn
      {:group_name, n} -> n
      _ -> nil
    end)

    members = Enum.find_value(args, fn
      {:members, [m]} when is_list(m) -> m
      {:members, _} -> []
      _ -> nil
    end) || []

    {name || "", members}
  end
end
