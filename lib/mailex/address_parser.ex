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

  cfws = times(choice([fws, comment]), min: 1) |> ignore()
  optional_cfws = optional(cfws)

  atext = ascii_char([?a..?z, ?A..?Z, ?0..?9, ?!, ?#, ?$, ?%, ?&, ?', ?*, ?+, ?-, ?/, ?=, ??, ?^, ?_, ?`, ?{, ?|, ?}, ?~])

  dot_atom_text =
    times(atext, min: 1)
    |> repeat(string(".") |> concat(times(atext, min: 1)))
    |> reduce({:erlang, :list_to_binary, []})

  qtext = ascii_char([0x21, 0x23..0x5B, 0x5D..0x7E])

  qcontent = choice([qtext, quoted_pair])

  quoted_string_inner =
    ignore(ascii_char([?"]))
    |> repeat(choice([qcontent, wsp |> replace(?\s)]))
    |> ignore(ascii_char([?"]))
    |> reduce({:erlang, :list_to_binary, []})

  _quoted_string =
    optional_cfws
    |> concat(quoted_string_inner)
    |> concat(optional_cfws)

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

  addr_spec =
    optional_cfws
    |> concat(local_part)
    |> ignore(optional_cfws)
    |> ignore(string("@"))
    |> ignore(optional_cfws)
    |> concat(domain)
    |> concat(optional_cfws)
    |> post_traverse({__MODULE__, :build_addr_spec, []})

  angle_addr =
    optional_cfws
    |> ignore(string("<"))
    |> ignore(optional_cfws)
    |> concat(local_part)
    |> ignore(optional_cfws)
    |> ignore(string("@"))
    |> ignore(optional_cfws)
    |> concat(domain)
    |> ignore(optional_cfws)
    |> ignore(string(">"))
    |> concat(optional_cfws)
    |> post_traverse({__MODULE__, :build_addr_spec, []})

  phrase_word =
    choice([
      quoted_string_inner,
      dot_atom_text,
      string(".")
    ])

  phrase =
    optional_cfws
    |> concat(phrase_word)
    |> repeat(
      choice([
        times(wsp, min: 1) |> replace(" ") |> concat(phrase_word),
        phrase_word
      ])
    )
    |> concat(optional_cfws)
    |> reduce({__MODULE__, :join_phrase, []})

  name_addr =
    phrase
    |> unwrap_and_tag(:display_name)
    |> concat(angle_addr)
    |> post_traverse({__MODULE__, :build_name_addr, []})

  bare_angle_addr =
    optional_cfws
    |> ignore(string("<"))
    |> ignore(optional_cfws)
    |> concat(local_part)
    |> ignore(optional_cfws)
    |> ignore(string("@"))
    |> ignore(optional_cfws)
    |> concat(domain)
    |> ignore(optional_cfws)
    |> ignore(string(">"))
    |> concat(optional_cfws)
    |> post_traverse({__MODULE__, :build_bare_mailbox, []})

  bare_addr_spec =
    optional_cfws
    |> concat(local_part)
    |> ignore(optional_cfws)
    |> ignore(string("@"))
    |> ignore(optional_cfws)
    |> concat(domain)
    |> concat(optional_cfws)
    |> concat(optional(comment))
    |> post_traverse({__MODULE__, :build_bare_mailbox, []})

  mailbox = choice([name_addr, bare_angle_addr, bare_addr_spec])

  mailbox_sep = optional_cfws |> ignore(string(",")) |> concat(optional_cfws)

  mailbox_list =
    optional(mailbox)
    |> repeat(mailbox_sep |> concat(optional(mailbox)))
    |> post_traverse({__MODULE__, :collect_list, []})

  group =
    optional_cfws
    |> concat(phrase |> unwrap_and_tag(:group_name))
    |> ignore(string(":"))
    |> concat(optional_cfws)
    |> concat(tag(optional(mailbox_list), :members))
    |> ignore(optional_cfws)
    |> ignore(string(";"))
    |> concat(optional_cfws)
    |> post_traverse({__MODULE__, :build_group, []})

  address = choice([group, mailbox])

  address_sep = optional_cfws |> ignore(string(",")) |> concat(optional_cfws)

  address_list =
    repeat(address_sep)
    |> concat(optional(address))
    |> repeat(address_sep |> concat(optional(address)))
    |> post_traverse({__MODULE__, :collect_list, []})

  # ===========================================================================
  # Parser definitions
  # ===========================================================================

  defparsec :do_parse_addr_spec, addr_spec |> eos()
  defparsec :do_parse_mailbox, mailbox |> eos()
  defparsec :do_parse_group, group |> eos()
  defparsec :do_parse_address, address |> eos()
  defparsec :do_parse_address_list, address_list |> eos()

  # ===========================================================================
  # Public API
  # ===========================================================================

  def parse_addr_spec(input) when is_binary(input) do
    case do_parse_addr_spec(input) do
      {:ok, [result], "", _, _, _} -> {:ok, result}
      {:ok, _, rest, _, _, _} -> {:error, "unexpected input: #{inspect(rest)}"}
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end

  def parse_mailbox(input) when is_binary(input) do
    case do_parse_mailbox(input) do
      {:ok, [result], "", _, _, _} -> {:ok, result}
      {:ok, _, rest, _, _, _} -> {:error, "unexpected input: #{inspect(rest)}"}
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end

  def parse_group(input) when is_binary(input) do
    case do_parse_group(input) do
      {:ok, [result], "", _, _, _} -> {:ok, result}
      {:ok, _, rest, _, _, _} -> {:error, "unexpected input: #{inspect(rest)}"}
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end

  def parse_address(input) when is_binary(input) do
    case do_parse_address(input) do
      {:ok, [result], "", _, _, _} -> {:ok, result}
      {:ok, _, rest, _, _, _} -> {:error, "unexpected input: #{inspect(rest)}"}
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end

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
