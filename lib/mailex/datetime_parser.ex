defmodule Mailex.DateTimeParser do
  @moduledoc """
  RFC 5322 date-time parser using NimbleParsec.

  Parses date-time values according to RFC 5322 §3.3, including:
  - Standard format: [day-of-week ","] day month year time zone
  - Obsolete 2-digit years (RFC 5322 §4.3)
  - Named timezones (UT, GMT, EST, EDT, CST, CDT, MST, MDT, PST, PDT)
  - Military single-letter zones
  """

  import NimbleParsec

  # ===========================================================================
  # Result struct
  # ===========================================================================

  defstruct [
    :day_of_week,
    :day,
    :month,
    :year,
    :hour,
    :minute,
    :second,
    :zone_offset
  ]

  @type t :: %__MODULE__{
    day_of_week: :mon | :tue | :wed | :thu | :fri | :sat | :sun | nil,
    day: 1..31,
    month: 1..12,
    year: non_neg_integer(),
    hour: 0..23,
    minute: 0..59,
    second: 0..60,
    zone_offset: integer()
  }

  # ===========================================================================
  # Lexical primitives
  # ===========================================================================

  wsp = ascii_char([?\s, ?\t])
  crlf = choice([string("\r\n"), string("\n")])

  fws =
    choice([
      crlf |> concat(times(wsp, min: 1)),
      times(wsp, min: 1)
    ])
    |> ignore()

  ctext = ascii_char([0x21..0x27, 0x2A..0x5B, 0x5D..0x7E])
  quoted_pair = ignore(string("\\")) |> ascii_char([0x00..0x7F])

  defcombinatorp :comment_content,
    repeat(choice([ctext |> ignore(), quoted_pair |> ignore(), parsec(:dt_nested_comment), fws]))

  defcombinatorp :dt_nested_comment,
    ignore(ascii_char([?(])) |> concat(parsec(:comment_content)) |> ignore(ascii_char([?)]))

  comment =
    ignore(ascii_char([?(]))
    |> concat(parsec(:comment_content))
    |> ignore(ascii_char([?)]))

  cfws = times(choice([fws, comment]), min: 1) |> ignore()
  optional_cfws = optional(cfws)

  # ===========================================================================
  # Day of week
  # ===========================================================================

  day_name =
    choice([
      string("Mon") |> replace(:mon),
      string("Tue") |> replace(:tue),
      string("Wed") |> replace(:wed),
      string("Thu") |> replace(:thu),
      string("Fri") |> replace(:fri),
      string("Sat") |> replace(:sat),
      string("Sun") |> replace(:sun)
    ])

  day_of_week =
    optional_cfws
    |> concat(day_name)
    |> concat(optional_cfws)
    |> ignore(string(","))
    |> unwrap_and_tag(:day_of_week)

  # ===========================================================================
  # Date components
  # ===========================================================================

  digit = ascii_char([?0..?9])

  day_num =
    optional_cfws
    |> concat(times(digit, min: 1, max: 2))
    |> concat(optional_cfws)
    |> reduce({__MODULE__, :parse_digits, []})
    |> unwrap_and_tag(:day)

  month_name =
    choice([
      string("Jan") |> replace(1),
      string("Feb") |> replace(2),
      string("Mar") |> replace(3),
      string("Apr") |> replace(4),
      string("May") |> replace(5),
      string("Jun") |> replace(6),
      string("Jul") |> replace(7),
      string("Aug") |> replace(8),
      string("Sep") |> replace(9),
      string("Oct") |> replace(10),
      string("Nov") |> replace(11),
      string("Dec") |> replace(12)
    ])
    |> unwrap_and_tag(:month)

  year_num =
    optional_cfws
    |> concat(times(digit, min: 2))
    |> concat(optional_cfws)
    |> reduce({__MODULE__, :parse_year, []})
    |> unwrap_and_tag(:year)

  date = day_num |> concat(month_name) |> concat(year_num)

  # ===========================================================================
  # Time components
  # ===========================================================================

  two_digit =
    optional_cfws
    |> concat(times(digit, 2))
    |> concat(optional_cfws)
    |> reduce({__MODULE__, :parse_digits, []})

  hour = two_digit |> unwrap_and_tag(:hour)
  minute = two_digit |> unwrap_and_tag(:minute)
  second = two_digit |> unwrap_and_tag(:second)

  time_of_day =
    hour
    |> ignore(string(":"))
    |> concat(minute)
    |> concat(optional(ignore(string(":")) |> concat(second)))

  # ===========================================================================
  # Timezone
  # ===========================================================================

  numeric_zone =
    optional_cfws
    |> concat(choice([string("+") |> replace(1), string("-") |> replace(-1)]))
    |> concat(times(digit, 4))
    |> reduce({__MODULE__, :parse_numeric_zone, []})
    |> unwrap_and_tag(:zone_offset)

  named_zone =
    optional_cfws
    |> concat(
      choice([
        string("UT") |> replace(0),
        string("GMT") |> replace(0),
        string("EST") |> replace(-300),
        string("EDT") |> replace(-240),
        string("CST") |> replace(-360),
        string("CDT") |> replace(-300),
        string("MST") |> replace(-420),
        string("MDT") |> replace(-360),
        string("PST") |> replace(-480),
        string("PDT") |> replace(-420),
        string("Z") |> replace(0),
        ascii_char([?A..?I, ?K..?Z, ?a..?i, ?k..?z]) |> replace(0)
      ])
    )
    |> concat(optional_cfws)
    |> unwrap_and_tag(:zone_offset)

  zone = choice([numeric_zone, named_zone])

  time = time_of_day |> concat(zone)

  # ===========================================================================
  # Full date-time
  # ===========================================================================

  date_time =
    optional_cfws
    |> concat(optional(day_of_week))
    |> concat(date)
    |> concat(time)
    |> concat(optional_cfws)
    |> post_traverse({__MODULE__, :build_datetime, []})

  defparsec :do_parse, date_time |> eos()

  # ===========================================================================
  # Public API
  # ===========================================================================

  @spec parse(binary()) :: {:ok, t()} | {:error, term()}
  def parse(input) when is_binary(input) do
    case do_parse(input) do
      {:ok, [result], "", _, _, _} -> {:ok, result}
      {:ok, _, rest, _, _, _} -> {:error, "unexpected input: #{inspect(rest)}"}
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end

  @spec to_datetime(t()) :: {:ok, DateTime.t()} | {:error, term()}
  def to_datetime(%__MODULE__{} = dt) do
    offset_seconds = dt.zone_offset * 60

    case DateTime.new(
      Date.new!(dt.year, dt.month, dt.day),
      Time.new!(dt.hour, dt.minute, dt.second || 0),
      "Etc/UTC",
      offset_seconds
    ) do
      {:ok, datetime} ->
        datetime = %{datetime | utc_offset: offset_seconds, std_offset: 0, zone_abbr: zone_abbr(dt.zone_offset)}
        {:ok, datetime}
      error -> error
    end
  end

  @spec to_utc_datetime(t()) :: {:ok, DateTime.t()} | {:error, term()}
  def to_utc_datetime(%__MODULE__{} = dt) do
    offset_minutes = dt.zone_offset
    total_minutes = dt.hour * 60 + dt.minute - offset_minutes

    days_delta = div(total_minutes, 1440)
    remaining_minutes = rem(total_minutes, 1440)

    {adjusted_hour, remaining_minutes} =
      if remaining_minutes < 0 do
        {div(remaining_minutes + 1440, 60), rem(remaining_minutes + 1440, 60)}
      else
        {div(remaining_minutes, 60), rem(remaining_minutes, 60)}
      end

    base_date = Date.new!(dt.year, dt.month, dt.day)
    adjusted_date = Date.add(base_date, days_delta)

    DateTime.new(adjusted_date, Time.new!(adjusted_hour, remaining_minutes, dt.second || 0), "Etc/UTC")
  end

  # ===========================================================================
  # Builder functions
  # ===========================================================================

  def build_datetime(rest, args, context, _line, _offset) do
    result = %__MODULE__{
      day_of_week: Keyword.get(args, :day_of_week),
      day: Keyword.get(args, :day),
      month: Keyword.get(args, :month),
      year: Keyword.get(args, :year),
      hour: Keyword.get(args, :hour),
      minute: Keyword.get(args, :minute),
      second: Keyword.get(args, :second, 0),
      zone_offset: Keyword.get(args, :zone_offset)
    }
    {rest, [result], context}
  end

  def parse_digits(chars) do
    chars
    |> Enum.filter(&is_integer/1)
    |> List.to_string()
    |> String.to_integer()
  end

  def parse_year(chars) do
    digits = chars |> Enum.filter(&is_integer/1) |> List.to_string()
    year = String.to_integer(digits)

    case String.length(digits) do
      2 when year <= 49 -> 2000 + year
      2 -> 1900 + year
      3 -> 1900 + year
      _ -> year
    end
  end

  def parse_numeric_zone([sign | digits]) do
    num = digits |> List.to_string() |> String.to_integer()
    hours = div(num, 100)
    minutes = rem(num, 100)
    sign * (hours * 60 + minutes)
  end

  defp zone_abbr(0), do: "UTC"
  defp zone_abbr(offset) when offset > 0 do
    hours = div(offset, 60)
    mins = rem(offset, 60)
    "+#{String.pad_leading(Integer.to_string(hours), 2, "0")}#{String.pad_leading(Integer.to_string(mins), 2, "0")}"
  end
  defp zone_abbr(offset) do
    offset = abs(offset)
    hours = div(offset, 60)
    mins = rem(offset, 60)
    "-#{String.pad_leading(Integer.to_string(hours), 2, "0")}#{String.pad_leading(Integer.to_string(mins), 2, "0")}"
  end
end
