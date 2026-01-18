defmodule Mailex.DateTimeParserTest do
  use ExUnit.Case, async: true

  alias Mailex.DateTimeParser

  describe "basic date-time parsing" do
    test "parses standard RFC 5322 date-time" do
      assert {:ok, result} = DateTimeParser.parse("Mon, 21 Nov 2022 09:55:06 -0600")
      assert result.day == 21
      assert result.month == 11
      assert result.year == 2022
      assert result.hour == 9
      assert result.minute == 55
      assert result.second == 6
      assert result.zone_offset == -360  # -0600 in minutes
      assert result.day_of_week == :mon
    end

    test "parses date-time without day-of-week" do
      assert {:ok, result} = DateTimeParser.parse("21 Nov 2022 09:55:06 -0600")
      assert result.day == 21
      assert result.month == 11
      assert result.year == 2022
      assert result.day_of_week == nil
    end

    test "parses date-time without seconds" do
      assert {:ok, result} = DateTimeParser.parse("Mon, 21 Nov 2022 09:55 -0600")
      assert result.hour == 9
      assert result.minute == 55
      assert result.second == 0
    end

    test "parses positive UTC offset" do
      assert {:ok, result} = DateTimeParser.parse("21 Nov 2022 09:55:06 +0530")
      assert result.zone_offset == 330  # +0530 in minutes
    end

    test "parses UTC zero offset" do
      assert {:ok, result} = DateTimeParser.parse("21 Nov 2022 09:55:06 +0000")
      assert result.zone_offset == 0
    end
  end

  describe "all month names" do
    @months [
      {"Jan", 1}, {"Feb", 2}, {"Mar", 3}, {"Apr", 4},
      {"May", 5}, {"Jun", 6}, {"Jul", 7}, {"Aug", 8},
      {"Sep", 9}, {"Oct", 10}, {"Nov", 11}, {"Dec", 12}
    ]

    for {month_name, month_num} <- @months do
      test "parses #{month_name}" do
        input = "01 #{unquote(month_name)} 2022 12:00:00 +0000"
        assert {:ok, result} = DateTimeParser.parse(input)
        assert result.month == unquote(month_num)
      end
    end
  end

  describe "all day-of-week names" do
    @days [
      {"Mon", :mon}, {"Tue", :tue}, {"Wed", :wed}, {"Thu", :thu},
      {"Fri", :fri}, {"Sat", :sat}, {"Sun", :sun}
    ]

    for {day_name, day_atom} <- @days do
      test "parses #{day_name}" do
        input = "#{unquote(day_name)}, 01 Jan 2022 12:00:00 +0000"
        assert {:ok, result} = DateTimeParser.parse(input)
        assert result.day_of_week == unquote(day_atom)
      end
    end
  end

  describe "obsolete date formats (RFC 5322 §4.3)" do
    test "parses 2-digit year 00-49 as 2000-2049" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 22 12:00:00 +0000")
      assert result.year == 2022
    end

    test "parses 2-digit year 50-99 as 1950-1999" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 99 12:00:00 +0000")
      assert result.year == 1999
    end

    test "parses 2-digit year 00 as 2000" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 00 12:00:00 +0000")
      assert result.year == 2000
    end

    test "parses 2-digit year 49 as 2049" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 49 12:00:00 +0000")
      assert result.year == 2049
    end

    test "parses 2-digit year 50 as 1950" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 50 12:00:00 +0000")
      assert result.year == 1950
    end

    test "parses 3-digit year as 1900 + value" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 122 12:00:00 +0000")
      assert result.year == 2022  # 1900 + 122
    end
  end

  describe "obsolete named timezones" do
    test "parses UT as +0000" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 UT")
      assert result.zone_offset == 0
    end

    test "parses GMT as +0000" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 GMT")
      assert result.zone_offset == 0
    end

    test "parses EST as -0500" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 EST")
      assert result.zone_offset == -300
    end

    test "parses EDT as -0400" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 EDT")
      assert result.zone_offset == -240
    end

    test "parses CST as -0600" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 CST")
      assert result.zone_offset == -360
    end

    test "parses CDT as -0500" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 CDT")
      assert result.zone_offset == -300
    end

    test "parses MST as -0700" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 MST")
      assert result.zone_offset == -420
    end

    test "parses MDT as -0600" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 MDT")
      assert result.zone_offset == -360
    end

    test "parses PST as -0800" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 PST")
      assert result.zone_offset == -480
    end

    test "parses PDT as -0700" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 PDT")
      assert result.zone_offset == -420
    end
  end

  describe "military timezone handling" do
    test "parses Z as +0000" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 Z")
      assert result.zone_offset == 0
    end

    test "treats other military zones as -0000 (unknown)" do
      # Per RFC 5322, military zones A-Z (except Z) should be treated as -0000
      # because they were defined incorrectly in RFC 822
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 A")
      assert result.zone_offset == 0
    end
  end

  describe "whitespace handling (CFWS)" do
    test "handles extra whitespace between components" do
      assert {:ok, result} = DateTimeParser.parse("Mon,  21  Nov  2022  09:55:06  -0600")
      assert result.day == 21
      assert result.month == 11
      assert result.year == 2022
    end

    test "handles comments in date-time" do
      assert {:ok, result} = DateTimeParser.parse("Mon, 21 Nov 2022 (comment) 09:55:06 -0600")
      assert result.day == 21
    end

    test "handles trailing CFWS" do
      assert {:ok, result} = DateTimeParser.parse("Mon, 21 Nov 2022 09:55:06 -0600  ")
      assert result.day == 21
    end

    test "handles leading whitespace" do
      assert {:ok, result} = DateTimeParser.parse("  Mon, 21 Nov 2022 09:55:06 -0600")
      assert result.day == 21
    end
  end

  describe "edge cases" do
    test "handles single digit day without leading zero" do
      assert {:ok, result} = DateTimeParser.parse("1 Jan 2022 12:00:00 +0000")
      assert result.day == 1
    end

    test "handles day with leading zero" do
      assert {:ok, result} = DateTimeParser.parse("01 Jan 2022 12:00:00 +0000")
      assert result.day == 1
    end

    test "rejects invalid month" do
      assert {:error, _} = DateTimeParser.parse("01 Foo 2022 12:00:00 +0000")
    end

    test "rejects invalid day-of-week" do
      assert {:error, _} = DateTimeParser.parse("Foo, 01 Jan 2022 12:00:00 +0000")
    end

    test "rejects missing timezone" do
      assert {:error, _} = DateTimeParser.parse("01 Jan 2022 12:00:00")
    end
  end

  describe "DateTime conversion" do
    test "converts to Elixir DateTime struct" do
      assert {:ok, result} = DateTimeParser.parse("Mon, 21 Nov 2022 09:55:06 +0530")
      {:ok, dt} = DateTimeParser.to_datetime(result)
      assert dt.year == 2022
      assert dt.month == 11
      assert dt.day == 21
      assert dt.hour == 9
      assert dt.minute == 55
      assert dt.second == 6
      assert dt.utc_offset == 19800  # +0530 in seconds
    end

    test "converts to UTC DateTime" do
      assert {:ok, result} = DateTimeParser.parse("Mon, 21 Nov 2022 09:55:06 +0530")
      {:ok, utc_dt} = DateTimeParser.to_utc_datetime(result)
      # 09:55:06 +0530 = 04:25:06 UTC
      assert utc_dt.hour == 4
      assert utc_dt.minute == 25
      assert utc_dt.second == 6
      assert utc_dt.time_zone == "Etc/UTC"
    end
  end
end
