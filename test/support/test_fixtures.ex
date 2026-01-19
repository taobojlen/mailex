defmodule Mailex.TestFixtures do
  @moduledoc """
  Test fixture loading utilities for conformance tests.
  """

  @conformance_dir Path.expand("../fixtures/conformance", __DIR__)

  @doc """
  Returns the path to the conformance test fixtures directory.
  """
  def conformance_dir, do: @conformance_dir

  @doc """
  Reads a file from the conformance fixtures directory.
  """
  def read!(relative_path) do
    Path.join(@conformance_dir, relative_path) |> File.read!()
  end

  @doc """
  Loads the isemail test cases from the generated Elixir fixture file.
  """
  def load_isemail_cases! do
    path = Path.join([@conformance_dir, "isemail", "tests.exs"])
    {cases, _binding} = Code.eval_file(path)
    cases
  end

  @doc """
  Reads a .eml file from the gen_smtp fixtures directory.
  """
  def load_gen_smtp_eml!(filename) do
    read!(Path.join(["gen_smtp", "eml", filename]))
  end

  @doc """
  Lists all .eml files in the gen_smtp fixtures directory.
  """
  def list_gen_smtp_eml_files! do
    dir = Path.join([@conformance_dir, "gen_smtp", "eml"])

    dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".eml"))
    |> Enum.sort()
  end

  @doc """
  Loads the gen_smtp test cases from the manifest file.
  """
  def load_gen_smtp_cases! do
    path = Path.join([@conformance_dir, "gen_smtp", "tests.exs"])
    {cases, _binding} = Code.eval_file(path)
    cases
  end

  @doc """
  Loads documented deviations for gen_smtp fixtures.
  """
  def load_gen_smtp_deviations! do
    path = Path.join([@conformance_dir, "gen_smtp", "deviations.exs"])

    if File.exists?(path) do
      {deviations, _binding} = Code.eval_file(path)
      deviations
    else
      %{}
    end
  end

  # SpamScope mail-parser fixtures

  @doc """
  Reads a .eml file from the spamscope_mail_parser fixtures directory.
  """
  def load_spamscope_eml!(filename) do
    read!(Path.join(["spamscope_mail_parser", "eml", filename]))
  end

  @doc """
  Lists all .eml files in the spamscope_mail_parser fixtures directory.
  """
  def list_spamscope_eml_files! do
    dir = Path.join([@conformance_dir, "spamscope_mail_parser", "eml"])

    dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".eml"))
    |> Enum.sort()
  end

  @doc """
  Loads the spamscope_mail_parser test cases from the manifest file.
  """
  def load_spamscope_cases! do
    path = Path.join([@conformance_dir, "spamscope_mail_parser", "tests.exs"])
    {cases, _binding} = Code.eval_file(path)
    cases
  end

  @doc """
  Loads documented deviations for spamscope_mail_parser fixtures.
  """
  def load_spamscope_deviations! do
    path = Path.join([@conformance_dir, "spamscope_mail_parser", "deviations.exs"])

    if File.exists?(path) do
      {deviations, _binding} = Code.eval_file(path)
      deviations
    else
      %{}
    end
  end

  # Ruby mail gem fixtures

  @doc """
  Reads a .eml file from the ruby_mail fixtures directory.
  """
  def load_ruby_mail_eml!(filename) do
    read!(Path.join(["ruby_mail", "eml", filename]))
  end

  @doc """
  Lists all .eml files in the ruby_mail fixtures directory.
  """
  def list_ruby_mail_eml_files! do
    dir = Path.join([@conformance_dir, "ruby_mail", "eml"])

    dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".eml"))
    |> Enum.sort()
  end

  @doc """
  Loads the ruby_mail test cases from the manifest file.
  """
  def load_ruby_mail_cases! do
    path = Path.join([@conformance_dir, "ruby_mail", "tests.exs"])
    {cases, _binding} = Code.eval_file(path)
    cases
  end

  @doc """
  Loads documented deviations for ruby_mail fixtures.
  """
  def load_ruby_mail_deviations! do
    path = Path.join([@conformance_dir, "ruby_mail", "deviations.exs"])

    if File.exists?(path) do
      {deviations, _binding} = Code.eval_file(path)
      deviations
    else
      %{}
    end
  end

  @doc """
  Decodes Unicode "control pictures" (U+2400 block) into actual ASCII control characters.

  The isemail test suite uses these Unicode symbols to represent ASCII control
  characters that can't be stored directly in XML. For example:
  - U+240D (␍) → ASCII 13 (CR)
  - U+240A (␊) → ASCII 10 (LF)
  - U+2400 (␀) → ASCII 0 (NUL)
  """
  def decode_isemail_control_pictures(str) when is_binary(str) do
    str
    |> String.to_charlist()
    |> Enum.map(fn
      cp when cp in 0x2400..0x241F -> cp - 0x2400
      cp -> cp
    end)
    |> List.to_string()
  end

  @doc """
  Parses the isemail XML file and returns a list of test case maps.

  Each map contains:
  - `:id` - test ID (integer)
  - `:address` - the email address to test (string)
  - `:category` - isemail category (string)
  - `:diagnosis` - specific diagnosis code (string)
  - `:comment` - optional comment explaining the test (string or nil)
  """
  def parse_isemail_xml!(xml_path) do
    xml_content = File.read!(xml_path)

    # Use regex to extract test elements (simple parsing, no XML dep needed)
    Regex.scan(~r/<test id="(\d+)">(.*?)<\/test>/s, xml_content)
    |> Enum.map(fn [_, id_str, content] ->
      %{
        id: String.to_integer(id_str),
        address: extract_xml_field(content, "address"),
        category: extract_xml_field(content, "category"),
        diagnosis: extract_xml_field(content, "diagnosis"),
        comment: extract_xml_field(content, "comment")
      }
    end)
    |> Enum.sort_by(& &1.id)
  end

  defp extract_xml_field(content, field) do
    case Regex.run(~r/<#{field}>(.*?)<\/#{field}>/s, content) do
      [_, value] -> unescape_xml(String.trim(value))
      nil -> nil
    end
  end

  defp unescape_xml(str) do
    str
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
    |> unescape_xml_entities()
  end

  # Handle numeric character references like &#x240D;
  defp unescape_xml_entities(str) do
    Regex.replace(~r/&#x([0-9A-Fa-f]+);/, str, fn _, hex ->
      {codepoint, ""} = Integer.parse(hex, 16)
      <<codepoint::utf8>>
    end)
  end
end
