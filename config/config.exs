import Config

# codepagex only compiles the ISO-8859 family into usable encodings by default.
# mailex can address additional legacy charsets (see `Mailex.Parser`'s charset
# mapping), but codepagex still has to compile them. We enumerate the encodings
# the test suite relies on here so windows-* and the full ISO-8859 range are
# transcoded for real.
#
# Applications that use mailex should configure the encodings they care about the
# same way (see the "Character encodings" section of the README).
config :codepagex, :encodings, [
  "ISO8859/8859-1",
  "ISO8859/8859-2",
  "ISO8859/8859-3",
  "ISO8859/8859-4",
  "ISO8859/8859-5",
  "ISO8859/8859-6",
  "ISO8859/8859-7",
  "ISO8859/8859-8",
  "ISO8859/8859-9",
  "ISO8859/8859-10",
  "ISO8859/8859-11",
  "ISO8859/8859-13",
  "ISO8859/8859-14",
  "ISO8859/8859-15",
  "ISO8859/8859-16",
  "VENDORS/MICSFT/WINDOWS/CP1250",
  "VENDORS/MICSFT/WINDOWS/CP1251",
  "VENDORS/MICSFT/WINDOWS/CP1252",
  "VENDORS/MICSFT/WINDOWS/CP1253",
  "VENDORS/MICSFT/WINDOWS/CP1254",
  "VENDORS/MICSFT/WINDOWS/CP1255",
  "VENDORS/MICSFT/WINDOWS/CP1256",
  "VENDORS/MICSFT/WINDOWS/CP1257",
  "VENDORS/MICSFT/WINDOWS/CP1258"
]
