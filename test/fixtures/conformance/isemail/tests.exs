[
  %{id: 1, address: "first.last@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{
    id: 2,
    address: "1234567890123456789012345678901234567890123456789012345678901234@iana.org",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{
    id: 3,
    address: "first.last@sub.do,com",
    category: "ISEMAIL_ERR",
    comment: "Mistyped comma instead of dot (replaces old #3 which was the same as #57)",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 4,
    address: "\"first\\\"last\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 5,
    address: "first\\@last@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Escaping can only happen within a quoted string",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 6,
    address: "\"first@last\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 7,
    address: "\"first\\\\last\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 8,
    address: "x@x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x2",
    category: "ISEMAIL_DNSWARN",
    comment: "Total length reduced to 254 characters so it's still valid",
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{
    id: 9,
    address: "1234567890123456789012345678901234567890123456789012345678901@12345678901234567890123456789012345678901234567890123456789.12345678901234567890123456789012345678901234567890123456789.123456789012345678901234567890123456789012345678901234567890123.iana.org",
    category: "ISEMAIL_DNSWARN",
    comment: "Total length reduced to 254 characters so it's still valid",
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{
    id: 10,
    address: "first.last@[12.34.56.78]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 11,
    address: "first.last@[IPv6:::12.34.56.78]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 12,
    address: "first.last@[IPv6:1111:2222:3333::4444:12.34.56.78]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 13,
    address: "first.last@[IPv6:1111:2222:3333:4444:5555:6666:12.34.56.78]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 14,
    address: "first.last@[IPv6:::1111:2222:3333:4444:5555:6666]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 15,
    address: "first.last@[IPv6:1111:2222:3333::4444:5555:6666]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 16,
    address: "first.last@[IPv6:1111:2222:3333:4444:5555:6666::]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 17,
    address: "first.last@[IPv6:1111:2222:3333:4444:5555:6666:7777:8888]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 18,
    address: "first.last@x23456789012345678901234567890123456789012345678901234567890123.iana.org",
    category: "ISEMAIL_DNSWARN",
    comment: nil,
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{
    id: 19,
    address: "first.last@3com.com",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{
    id: 20,
    address: "first.last@123.iana.org",
    category: "ISEMAIL_DNSWARN",
    comment: nil,
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{
    id: 21,
    address: "123456789012345678901234567890123456789012345678901234567890@12345678901234567890123456789012345678901234567890123456789.12345678901234567890123456789012345678901234567890123456789.12345678901234567890123456789012345678901234567890123456789.12345.iana.org",
    category: "ISEMAIL_RFC5322",
    comment: "Entire address is longer than 254 characters",
    diagnosis: "ISEMAIL_RFC5322_TOOLONG"
  },
  %{id: 22, address: "first.last", category: "ISEMAIL_ERR", comment: "No @", diagnosis: "ISEMAIL_ERR_NODOMAIN"},
  %{
    id: 23,
    address: "12345678901234567890123456789012345678901234567890123456789012345@iana.org",
    category: "ISEMAIL_RFC5322",
    comment: "Local part more than 64 characters",
    diagnosis: "ISEMAIL_RFC5322_LOCAL_TOOLONG"
  },
  %{
    id: 24,
    address: ".first.last@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Local part starts with a dot",
    diagnosis: "ISEMAIL_ERR_DOT_START"
  },
  %{
    id: 25,
    address: "first.last.@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Local part ends with a dot",
    diagnosis: "ISEMAIL_ERR_DOT_END"
  },
  %{
    id: 26,
    address: "first..last@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Local part has consecutive dots",
    diagnosis: "ISEMAIL_ERR_CONSECUTIVEDOTS"
  },
  %{
    id: 27,
    address: "\"first\"last\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Local part contains unescaped excluded characters",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_QS"
  },
  %{
    id: 28,
    address: "\"first\\last\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: "Any character can be escaped in a quoted string",
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 29,
    address: "\"\"\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Local part contains unescaped excluded characters",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 30,
    address: "\"\\\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Local part cannot end with a backslash",
    diagnosis: "ISEMAIL_ERR_UNCLOSEDQUOTEDSTR"
  },
  %{
    id: 31,
    address: "\"\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: "Local part is effectively empty, but this form is specifically allowed by RFC 5322 & RFC 5321",
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 32,
    address: "first\\\\@last@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Local part contains unescaped excluded characters",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{id: 33, address: "first.last@", category: "ISEMAIL_ERR", comment: "No domain", diagnosis: "ISEMAIL_ERR_NODOMAIN"},
  %{
    id: 34,
    address: "x@x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456789.x23456",
    category: "ISEMAIL_RFC5322",
    comment: "Domain exceeds 255 chars",
    diagnosis: "ISEMAIL_RFC5322_DOMAIN_TOOLONG"
  },
  %{
    id: 35,
    address: "first.last@[.12.34.56.78]",
    category: "ISEMAIL_RFC5322",
    comment: "Only char that can precede IPv4 address is ':'",
    diagnosis: "ISEMAIL_RFC5322_DOMAINLITERAL"
  },
  %{
    id: 36,
    address: "first.last@[12.34.56.789]",
    category: "ISEMAIL_RFC5322",
    comment: "Can't be interpreted as IPv4 so IPv6 tag is missing",
    diagnosis: "ISEMAIL_RFC5322_DOMAINLITERAL"
  },
  %{
    id: 37,
    address: "first.last@[::12.34.56.78]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 tag is missing",
    diagnosis: "ISEMAIL_RFC5322_DOMAINLITERAL"
  },
  %{
    id: 38,
    address: "first.last@[IPv5:::12.34.56.78]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 tag is wrong",
    diagnosis: "ISEMAIL_RFC5322_DOMAINLITERAL"
  },
  %{
    id: 39,
    address: "first.last@[IPv6:1111:2222:3333::4444:5555:12.34.56.78]",
    category: "ISEMAIL_RFC5321",
    comment: "RFC 4291 disagrees with RFC 5321 but is cited by it",
    diagnosis: "ISEMAIL_RFC5321_IPV6DEPRECATED"
  },
  %{
    id: 40,
    address: "first.last@[IPv6:1111:2222:3333:4444:5555:12.34.56.78]",
    category: "ISEMAIL_RFC5322",
    comment: "Not enough IPv6 groups",
    diagnosis: "ISEMAIL_RFC5322_IPV6_GRPCOUNT"
  },
  %{
    id: 41,
    address: "first.last@[IPv6:1111:2222:3333:4444:5555:6666:7777:12.34.56.78]",
    category: "ISEMAIL_RFC5322",
    comment: "Too many IPv6 groups (6 max)",
    diagnosis: "ISEMAIL_RFC5322_IPV6_GRPCOUNT"
  },
  %{
    id: 42,
    address: "first.last@[IPv6:1111:2222:3333:4444:5555:6666:7777]",
    category: "ISEMAIL_RFC5322",
    comment: "Not enough IPv6 groups",
    diagnosis: "ISEMAIL_RFC5322_IPV6_GRPCOUNT"
  },
  %{
    id: 43,
    address: "first.last@[IPv6:1111:2222:3333:4444:5555:6666:7777:8888:9999]",
    category: "ISEMAIL_RFC5322",
    comment: "Too many IPv6 groups (8 max)",
    diagnosis: "ISEMAIL_RFC5322_IPV6_GRPCOUNT"
  },
  %{
    id: 44,
    address: "first.last@[IPv6:1111:2222::3333::4444:5555:6666]",
    category: "ISEMAIL_RFC5322",
    comment: "Too many '::' (can be none or one)",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 45,
    address: "first.last@[IPv6:1111:2222:3333::4444:5555:6666:7777]",
    category: "ISEMAIL_RFC5321",
    comment: "RFC 4291 disagrees with RFC 5321 but is cited by it",
    diagnosis: "ISEMAIL_RFC5321_IPV6DEPRECATED"
  },
  %{
    id: 46,
    address: "first.last@[IPv6:1111:2222:333x::4444:5555]",
    category: "ISEMAIL_RFC5322",
    comment: "x is not valid in an IPv6 address",
    diagnosis: "ISEMAIL_RFC5322_IPV6_BADCHAR"
  },
  %{
    id: 47,
    address: "first.last@[IPv6:1111:2222:33333::4444:5555]",
    category: "ISEMAIL_RFC5322",
    comment: "33333 is not a valid group in an IPv6 address",
    diagnosis: "ISEMAIL_RFC5322_IPV6_BADCHAR"
  },
  %{
    id: 48,
    address: "first.last@example.123",
    category: "ISEMAIL_RFC5321",
    comment: "TLD can't be all digits",
    diagnosis: "ISEMAIL_RFC5321_TLDNUMERIC"
  },
  %{
    id: 49,
    address: "first.last@com",
    category: "ISEMAIL_RFC5321",
    comment: "Mail host is not usually at a Top Level Domain",
    diagnosis: "ISEMAIL_RFC5321_TLD"
  },
  %{
    id: 50,
    address: "first.last@-xample.com",
    category: "ISEMAIL_ERR",
    comment: "Label can't begin with a hyphen",
    diagnosis: "ISEMAIL_ERR_DOMAINHYPHENSTART"
  },
  %{
    id: 51,
    address: "first.last@exampl-.com",
    category: "ISEMAIL_ERR",
    comment: "Label can't end with a hyphen",
    diagnosis: "ISEMAIL_ERR_DOMAINHYPHENEND"
  },
  %{
    id: 52,
    address: "first.last@x234567890123456789012345678901234567890123456789012345678901234.iana.org",
    category: "ISEMAIL_RFC5322",
    comment: "Label can't be longer than 63 octets",
    diagnosis: "ISEMAIL_RFC5322_LABEL_TOOLONG"
  },
  %{
    id: 53,
    address: "\"Abc\\@def\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 54,
    address: "\"Fred\\ Bloggs\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 55,
    address: "\"Joe.\\\\Blow\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 56,
    address: "\"Abc@def\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 57,
    address: "\"Fred Bloggs\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 58,
    address: "user+mailbox@iana.org",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{
    id: 59,
    address: "customer/department=shipping@iana.org",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{id: 60, address: "$A12345@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{
    id: 61,
    address: "!def!xyz%abc@iana.org",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{id: 62, address: "_somename@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{id: 63, address: "dclo@us.ibm.com", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{
    id: 64,
    address: "abc\\@def@iana.org",
    category: "ISEMAIL_ERR",
    comment: "This example from RFC 3696 was corrected in an erratum",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 65,
    address: "abc\\\\@iana.org",
    category: "ISEMAIL_ERR",
    comment: "This example from RFC 3696 was corrected in an erratum",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 66,
    address: "peter.piper@iana.org",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{
    id: 67,
    address: "Doug\\ \\\"Ace\\\"\\ Lovell@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Escaping can only happen in a quoted string",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 68,
    address: "\"Doug \\\"Ace\\\" L.\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 69,
    address: "abc@def@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 70,
    address: "abc\\\\@def@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 71,
    address: "abc\\@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 72,
    address: "@iana.org",
    category: "ISEMAIL_ERR",
    comment: "No local part",
    diagnosis: "ISEMAIL_ERR_NOLOCALPART"
  },
  %{
    id: 73,
    address: "doug@",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_NODOMAIN"
  },
  %{
    id: 74,
    address: "\"qu@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_UNCLOSEDQUOTEDSTR"
  },
  %{
    id: 75,
    address: "ote\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 76,
    address: ".dot@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_DOT_START"
  },
  %{
    id: 77,
    address: "dot.@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_DOT_END"
  },
  %{
    id: 78,
    address: "two..dot@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_CONSECUTIVEDOTS"
  },
  %{
    id: 79,
    address: "\"Doug \"Ace\" L.\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_QS"
  },
  %{
    id: 80,
    address: "Doug\\ \\\"Ace\\\"\\ L\\.@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 81,
    address: "hello world@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_CFWS"
  },
  %{
    id: 82,
    address: "gatsby@f.sc.ot.t.f.i.tzg.era.l.d.",
    category: "ISEMAIL_ERR",
    comment: "Doug Lovell says this should fail",
    diagnosis: "ISEMAIL_ERR_DOT_END"
  },
  %{id: 83, address: "test@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{id: 84, address: "TEST@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{
    id: 85,
    address: "1234567890@iana.org",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{id: 86, address: "test+test@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{id: 87, address: "test-test@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{id: 88, address: "t*est@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{id: 89, address: "+1~1+@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{id: 90, address: "{_test_}@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{
    id: 91,
    address: "\"[[ test ]]\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{id: 92, address: "test.test@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{
    id: 93,
    address: "\"test.test\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 94,
    address: "test.\"test\"@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Obsolete form, but documented in RFC 5322",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 95,
    address: "\"test@test\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 96,
    address: "test@123.123.123.x123",
    category: "ISEMAIL_DNSWARN",
    comment: nil,
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{
    id: 97,
    address: "test@123.123.123.123",
    category: "ISEMAIL_RFC5321",
    comment: "Top Level Domain unlikely to have first character numeric (although ICANN make up their own rules).",
    diagnosis: "ISEMAIL_RFC5321_TLDNUMERIC"
  },
  %{
    id: 98,
    address: "test@[123.123.123.123]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 99,
    address: "test@example.iana.org",
    category: "ISEMAIL_DNSWARN",
    comment: nil,
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{
    id: 100,
    address: "test@example.example.iana.org",
    category: "ISEMAIL_DNSWARN",
    comment: nil,
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{id: 101, address: "test.iana.org", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_NODOMAIN"},
  %{id: 102, address: "test.@iana.org", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_DOT_END"},
  %{
    id: 103,
    address: "test..test@iana.org",
    category: "ISEMAIL_ERR",
    comment: nil,
    diagnosis: "ISEMAIL_ERR_CONSECUTIVEDOTS"
  },
  %{id: 104, address: ".test@iana.org", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_DOT_START"},
  %{
    id: 105,
    address: "test@test@iana.org",
    category: "ISEMAIL_ERR",
    comment: nil,
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{id: 106, address: "test@@iana.org", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"},
  %{
    id: 107,
    address: "-- test --@iana.org",
    category: "ISEMAIL_ERR",
    comment: "No spaces allowed in local part",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_CFWS"
  },
  %{
    id: 108,
    address: "[test]@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Square brackets only allowed within quotes",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 109,
    address: "\"test\\test\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: "Any character can be escaped in a quoted string",
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 110,
    address: "\"test\"test\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Quotes cannot be nested",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_QS"
  },
  %{
    id: 111,
    address: "()[]\\;:,><@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Disallowed Characters",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 112,
    address: "test@.",
    category: "ISEMAIL_ERR",
    comment: "Dave Child says so",
    diagnosis: "ISEMAIL_ERR_DOT_START"
  },
  %{
    id: 113,
    address: "test@example.",
    category: "ISEMAIL_ERR",
    comment: "Dave Child says so",
    diagnosis: "ISEMAIL_ERR_DOT_END"
  },
  %{
    id: 114,
    address: "test@.org",
    category: "ISEMAIL_ERR",
    comment: "Dave Child says so",
    diagnosis: "ISEMAIL_ERR_DOT_START"
  },
  %{
    id: 115,
    address: "test@123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890123.123456789012345678901234567890123456789012345678901234567890.com",
    category: "ISEMAIL_RFC5322",
    comment: "255 characters is maximum length for domain. This is 256.",
    diagnosis: "ISEMAIL_RFC5322_DOMAIN_TOOLONG"
  },
  %{
    id: 116,
    address: "test@example",
    category: "ISEMAIL_RFC5321",
    comment: "Dave Child says so",
    diagnosis: "ISEMAIL_RFC5321_TLD"
  },
  %{
    id: 117,
    address: "test@[123.123.123.123",
    category: "ISEMAIL_ERR",
    comment: "Dave Child says so",
    diagnosis: "ISEMAIL_ERR_UNCLOSEDDOMLIT"
  },
  %{
    id: 118,
    address: "test@123.123.123.123]",
    category: "ISEMAIL_ERR",
    comment: "Dave Child says so",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 119,
    address: "NotAnEmail",
    category: "ISEMAIL_ERR",
    comment: "Phil Haack says so",
    diagnosis: "ISEMAIL_ERR_NODOMAIN"
  },
  %{
    id: 120,
    address: "@NotAnEmail",
    category: "ISEMAIL_ERR",
    comment: "Phil Haack says so",
    diagnosis: "ISEMAIL_ERR_NOLOCALPART"
  },
  %{
    id: 121,
    address: "\"test\\\\blah\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 122,
    address: "\"test\\blah\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: "Any character can be escaped in a quoted string",
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 123,
    address: "\"test\\␍blah\"@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Quoted string specifically excludes carriage returns unless escaped",
    diagnosis: "ISEMAIL_DEPREC_QP"
  },
  %{
    id: 124,
    address: "\"test␍blah\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Quoted string specifically excludes carriage returns",
    diagnosis: "ISEMAIL_ERR_CR_NO_LF"
  },
  %{
    id: 125,
    address: "\"test\\\"blah\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 126,
    address: "\"test\"blah\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Phil Haack says so",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_QS"
  },
  %{
    id: 127,
    address: "customer/department@iana.org",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{
    id: 128,
    address: "_Yosemite.Sam@iana.org",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{id: 129, address: "~@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{
    id: 130,
    address: ".wooly@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Phil Haack says so",
    diagnosis: "ISEMAIL_ERR_DOT_START"
  },
  %{
    id: 131,
    address: "wo..oly@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Phil Haack says so",
    diagnosis: "ISEMAIL_ERR_CONSECUTIVEDOTS"
  },
  %{
    id: 132,
    address: "pootietang.@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Phil Haack says so",
    diagnosis: "ISEMAIL_ERR_DOT_END"
  },
  %{
    id: 133,
    address: ".@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Phil Haack says so",
    diagnosis: "ISEMAIL_ERR_DOT_START"
  },
  %{
    id: 134,
    address: "\"Austin@Powers\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{id: 135, address: "Ima.Fool@iana.org", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{
    id: 136,
    address: "\"Ima.Fool\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 137,
    address: "\"Ima Fool\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 138,
    address: "Ima Fool@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Phil Haack says so",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_CFWS"
  },
  %{
    id: 139,
    address: "phil.h\\@\\@ck@haacked.com",
    category: "ISEMAIL_ERR",
    comment: "Escaping can only happen in a quoted string",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 140,
    address: "\"first\".\"last\"@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: nil,
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 141,
    address: "\"first\".middle.\"last\"@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: nil,
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 142,
    address: "\"first\\\\\"last\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Contains an unescaped quote",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_QS"
  },
  %{
    id: 143,
    address: "\"first\".last@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "obs-local-part form as described in RFC 5322",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 144,
    address: "first.\"last\"@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "obs-local-part form as described in RFC 5322",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 145,
    address: "\"first\".\"middle\".\"last\"@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "obs-local-part form as described in RFC 5322",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 146,
    address: "\"first.middle\".\"last\"@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "obs-local-part form as described in RFC 5322",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 147,
    address: "\"first.middle.last\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 148,
    address: "\"first..last\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: "obs-local-part form as described in RFC 5322",
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 149,
    address: "foo@[\\1.2.3.4]",
    category: "ISEMAIL_RFC5322",
    comment: "RFC 5321 specifies the syntax for address-literal and does not allow escaping",
    diagnosis: "ISEMAIL_RFC5322_DOMLIT_OBSDTEXT"
  },
  %{
    id: 150,
    address: "\"first\\\\\\\"last\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 151,
    address: "first.\"mid\\dle\".\"last\"@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Backslash can escape anything but must escape something",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 152,
    address: "Test.␍␊ Folding.␍␊ Whitespace@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: nil,
    diagnosis: "ISEMAIL_DEPREC_FWS"
  },
  %{
    id: 153,
    address: "first.\"\".last@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Contains a zero-length element",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 154,
    address: "first\\last@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Unquoted string must be an atom",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 155,
    address: "Abc\\@def@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Was incorrectly given as a valid address in the original RFC 3696",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 156,
    address: "Fred\\ Bloggs@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Was incorrectly given as a valid address in the original RFC 3696",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 157,
    address: "Joe.\\\\Blow@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Was incorrectly given as a valid address in the original RFC 3696",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 158,
    address: "first.last@[IPv6:1111:2222:3333:4444:5555:6666:12.34.567.89]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv4 part contains an invalid octet",
    diagnosis: "ISEMAIL_RFC5322_IPV6_BADCHAR"
  },
  %{
    id: 159,
    address: "\"test\\␍␊ blah\"@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Folding white space can't appear within a quoted pair",
    diagnosis: "ISEMAIL_ERR_EXPECTING_QTEXT"
  },
  %{
    id: 160,
    address: "\"test␍␊ blah\"@iana.org",
    category: "ISEMAIL_CFWS",
    comment: "This is a valid quoted string with folding white space",
    diagnosis: "ISEMAIL_CFWS_FWS"
  },
  %{
    id: 161,
    address: "{^c\\@**Dog^}@cartoon.com",
    category: "ISEMAIL_ERR",
    comment: "This is a throwaway example from Doug Lovell's article. Actually it's not a valid address.",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 162,
    address: "(foo)cal(bar)@(baz)iamcal.com(quux)",
    category: "ISEMAIL_DEPREC",
    comment: "A valid address containing comments",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 163,
    address: "cal@iamcal(woo).(yay)com",
    category: "ISEMAIL_DEPREC",
    comment: "A valid address containing comments",
    diagnosis: "ISEMAIL_DEPREC_COMMENT"
  },
  %{
    id: 164,
    address: "\"foo\"(yay)@(hoopla)[1.2.3.4]",
    category: "ISEMAIL_DEPREC",
    comment: "Address literal can't be commented (RFC 5321)",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 165,
    address: "cal(woo(yay)hoopla)@iamcal.com",
    category: "ISEMAIL_DEPREC",
    comment: "A valid address containing comments",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 166,
    address: "cal(foo\\@bar)@iamcal.com",
    category: "ISEMAIL_DEPREC",
    comment: "A valid address containing comments",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 167,
    address: "cal(foo\\)bar)@iamcal.com",
    category: "ISEMAIL_DEPREC",
    comment: "A valid address containing comments and an escaped parenthesis",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 168,
    address: "cal(foo(bar)@iamcal.com",
    category: "ISEMAIL_ERR",
    comment: "Unclosed parenthesis in comment",
    diagnosis: "ISEMAIL_ERR_UNCLOSEDCOMMENT"
  },
  %{
    id: 169,
    address: "cal(foo)bar)@iamcal.com",
    category: "ISEMAIL_ERR",
    comment: "Too many closing parentheses",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_CFWS"
  },
  %{
    id: 170,
    address: "cal(foo\\)@iamcal.com",
    category: "ISEMAIL_ERR",
    comment: "Backslash at end of comment has nothing to escape",
    diagnosis: "ISEMAIL_ERR_UNCLOSEDCOMMENT"
  },
  %{
    id: 171,
    address: "first().last@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "A valid address containing an empty comment",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 172,
    address: "first.(␍␊ middle␍␊ )last@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Comment with folding white space",
    diagnosis: "ISEMAIL_DEPREC_COMMENT"
  },
  %{
    id: 173,
    address: "first(12345678901234567890123456789012345678901234567890)last@(1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890)iana.org",
    category: "ISEMAIL_ERR",
    comment: "Too long with comments, not too long without",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_CFWS"
  },
  %{
    id: 174,
    address: "first(Welcome to␍␊ the (\"wonderful\" (!)) world␍␊ of email)@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Silly example from my blog post",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 175,
    address: "pete(his account)@silly.test(his host)",
    category: "ISEMAIL_DEPREC",
    comment: "Canonical example from RFC 5322",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 176,
    address: "c@(Chris's host.)public.example",
    category: "ISEMAIL_DEPREC",
    comment: "Canonical example from RFC 5322",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 177,
    address: "jdoe@machine(comment).  example",
    category: "ISEMAIL_DEPREC",
    comment: "Canonical example from RFC 5322",
    diagnosis: "ISEMAIL_DEPREC_FWS"
  },
  %{
    id: 178,
    address: "1234   @   local(blah)  .machine .example",
    category: "ISEMAIL_DEPREC",
    comment: "Canonical example from RFC 5322",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 179,
    address: "first(middle)last@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Can't have a comment or white space except at an element boundary",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_CFWS"
  },
  %{
    id: 180,
    address: "first(abc.def).last@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Comment can contain a dot",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 181,
    address: "first(a\"bc.def).last@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Comment can contain double quote",
    diagnosis: "ISEMAIL_DEPREC_LOCALPART"
  },
  %{
    id: 182,
    address: "first.(\")middle.last(\")@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Comment can contain a quote",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 183,
    address: "first(abc(\"def\".ghi).mno)middle(abc(\"def\".ghi).mno).last@(abc(\"def\".ghi).mno)example(abc(\"def\".ghi).mno).(abc(\"def\".ghi).mno)com(abc(\"def\".ghi).mno)",
    category: "ISEMAIL_ERR",
    comment: "Can't have comments or white space except at an element boundary",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_CFWS"
  },
  %{
    id: 184,
    address: "first(abc\\(def)@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "Comment can contain quoted-pair",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 185,
    address: "first.last@iana(1234567890123456789012345678901234567890123456789012345678901234567890).org",
    category: "ISEMAIL_CFWS",
    comment: "Label is longer than 63 octets, but not with comment removed",
    diagnosis: "ISEMAIL_CFWS_COMMENT"
  },
  %{
    id: 186,
    address: "a(a(b(c)d(e(f))g)h(i)j)@iana.org",
    category: "ISEMAIL_DEPREC",
    comment: nil,
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 187,
    address: "a(a(b(c)d(e(f))g)(h(i)j)@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Braces are not properly matched",
    diagnosis: "ISEMAIL_ERR_UNCLOSEDCOMMENT"
  },
  %{
    id: 188,
    address: "name.lastname@domain.com",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{id: 189, address: ".@", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_DOT_START"},
  %{id: 190, address: "a@b", category: "ISEMAIL_RFC5321", comment: nil, diagnosis: "ISEMAIL_RFC5321_TLD"},
  %{id: 191, address: "@bar.com", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_NOLOCALPART"},
  %{id: 192, address: "@@bar.com", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_NOLOCALPART"},
  %{id: 193, address: "a@bar.com", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{id: 194, address: "aaa.com", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_NODOMAIN"},
  %{id: 195, address: "aaa@.com", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_DOT_START"},
  %{id: 196, address: "aaa@.123", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_DOT_START"},
  %{
    id: 197,
    address: "aaa@[123.123.123.123]",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 198,
    address: "aaa@[123.123.123.123]a",
    category: "ISEMAIL_ERR",
    comment: "extra data outside address-literal",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_DOMLIT"
  },
  %{
    id: 199,
    address: "aaa@[123.123.123.333]",
    category: "ISEMAIL_RFC5322",
    comment: "not a valid IP",
    diagnosis: "ISEMAIL_RFC5322_DOMAINLITERAL"
  },
  %{id: 200, address: "a@bar.com.", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_DOT_END"},
  %{id: 201, address: "a@bar", category: "ISEMAIL_RFC5321", comment: nil, diagnosis: "ISEMAIL_RFC5321_TLD"},
  %{id: 202, address: "a-b@bar.com", category: "ISEMAIL_VALID_CATEGORY", comment: nil, diagnosis: "ISEMAIL_VALID"},
  %{
    id: 203,
    address: "+@b.c",
    category: "ISEMAIL_DNSWARN",
    comment: "TLDs can be any length",
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{id: 204, address: "+@b.com", category: "ISEMAIL_DNSWARN", comment: nil, diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"},
  %{id: 205, address: "a@-b.com", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_DOMAINHYPHENSTART"},
  %{id: 206, address: "a@b-.com", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_DOMAINHYPHENEND"},
  %{id: 207, address: "-@..com", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_DOT_START"},
  %{id: 208, address: "-@a..com", category: "ISEMAIL_ERR", comment: nil, diagnosis: "ISEMAIL_ERR_CONSECUTIVEDOTS"},
  %{
    id: 209,
    address: "a@b.co-foo.uk",
    category: "ISEMAIL_DNSWARN",
    comment: nil,
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{
    id: 210,
    address: "\"hello my name is\"@stutter.com",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 211,
    address: "\"Test \\\"Fail\\\" Ing\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 212,
    address: "valid@about.museum",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{
    id: 213,
    address: "invalid@about.museum-",
    category: "ISEMAIL_ERR",
    comment: nil,
    diagnosis: "ISEMAIL_ERR_DOMAINHYPHENEND"
  },
  %{
    id: 214,
    address: "shaitan@my-domain.thisisminekthx",
    category: "ISEMAIL_DNSWARN",
    comment: "Disagree with Paul Gregg here",
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  },
  %{
    id: 215,
    address: "test@...........com",
    category: "ISEMAIL_ERR",
    comment: "......",
    diagnosis: "ISEMAIL_ERR_DOT_START"
  },
  %{
    id: 216,
    address: "foobar@192.168.0.1",
    category: "ISEMAIL_RFC5321",
    comment: "ip need to be []",
    diagnosis: "ISEMAIL_RFC5321_TLDNUMERIC"
  },
  %{
    id: 217,
    address: "\"Joe\\\\Blow\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 218,
    address: "Invalid \\␊ Folding \\␊ Whitespace@iana.org",
    category: "ISEMAIL_ERR",
    comment: "Even obs-local-part doesn't allow CFWS in the middle of an atom",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_CFWS"
  },
  %{
    id: 219,
    address: "HM2Kinsists@(that comments are allowed)this.is.ok",
    category: "ISEMAIL_DEPREC",
    comment: nil,
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 220,
    address: "user%uucp!path@berkeley.edu",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: nil,
    diagnosis: "ISEMAIL_VALID"
  },
  %{
    id: 221,
    address: "\"first(last)\"@iana.org",
    category: "ISEMAIL_RFC5321",
    comment: nil,
    diagnosis: "ISEMAIL_RFC5321_QUOTEDSTRING"
  },
  %{
    id: 222,
    address: "␍␊ (␍␊ x ␍␊ ) ␍␊ first␍␊ ( ␍␊ x␍␊ ) ␍␊ .␍␊ ( ␍␊ x) ␍␊ last ␍␊ (  x ␍␊ ) ␍␊ @iana.org",
    category: "ISEMAIL_DEPREC",
    comment: nil,
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 223,
    address: "first.last @iana.org",
    category: "ISEMAIL_DEPREC",
    comment: "FWS is allowed after local part (this is similar to #152 but is the test proposed by John Kloor)",
    diagnosis: "ISEMAIL_DEPREC_CFWS_NEAR_AT"
  },
  %{
    id: 224,
    address: "test. ␍␊ ␍␊ obs@syntax.com",
    category: "ISEMAIL_DEPREC",
    comment: "obs-fws allows multiple lines (test 2: space before break)",
    diagnosis: "ISEMAIL_DEPREC_FWS"
  },
  %{
    id: 225,
    address: "test.␍␊␍␊ obs@syntax.com",
    category: "ISEMAIL_ERR",
    comment: "obs-fws must have at least one WSP per line",
    diagnosis: "ISEMAIL_ERR_FWS_CRLF_X2"
  },
  %{
    id: 226,
    address: "\"Unicode NULL \\␀\"@char.com",
    category: "ISEMAIL_DEPREC",
    comment: "Can have escaped Unicode Character 'NULL' (U+0000)",
    diagnosis: "ISEMAIL_DEPREC_QP"
  },
  %{
    id: 227,
    address: "\"Unicode NULL ␀\"@char.com",
    category: "ISEMAIL_ERR",
    comment: "Cannot have unescaped Unicode Character 'NULL' (U+0000)",
    diagnosis: "ISEMAIL_ERR_EXPECTING_QTEXT"
  },
  %{
    id: 228,
    address: "Unicode NULL \\␀@char.com",
    category: "ISEMAIL_ERR",
    comment: "Escaped Unicode Character 'NULL' (U+0000) must be in quoted string",
    diagnosis: "ISEMAIL_ERR_ATEXT_AFTER_CFWS"
  },
  %{
    id: 229,
    address: "cdburgess+!#$%&'*-/=?+_{}|~test@gmail.com",
    category: "ISEMAIL_VALID_CATEGORY",
    comment: "Example given in comments",
    diagnosis: "ISEMAIL_VALID"
  },
  %{
    id: 230,
    address: "first.last@[IPv6:::a2:a3:a4:b1:b2:b3:b4]",
    category: "ISEMAIL_RFC5321",
    comment: ":: only elides one zero group (IPv6 authority is RFC 4291)",
    diagnosis: "ISEMAIL_RFC5321_IPV6DEPRECATED"
  },
  %{
    id: 231,
    address: "first.last@[IPv6:a1:a2:a3:a4:b1:b2:b3::]",
    category: "ISEMAIL_RFC5321",
    comment: ":: only elides one zero group (IPv6 authority is RFC 4291)",
    diagnosis: "ISEMAIL_RFC5321_IPV6DEPRECATED"
  },
  %{
    id: 232,
    address: "first.last@[IPv6::]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONSTRT"
  },
  %{
    id: 233,
    address: "first.last@[IPv6:::]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 234,
    address: "first.last@[IPv6::::]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 235,
    address: "first.last@[IPv6::b4]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONSTRT"
  },
  %{
    id: 236,
    address: "first.last@[IPv6:::b4]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 237,
    address: "first.last@[IPv6::::b4]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 238,
    address: "first.last@[IPv6::b3:b4]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONSTRT"
  },
  %{
    id: 239,
    address: "first.last@[IPv6:::b3:b4]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 240,
    address: "first.last@[IPv6::::b3:b4]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 241,
    address: "first.last@[IPv6:a1::b4]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 242,
    address: "first.last@[IPv6:a1:::b4]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 243,
    address: "first.last@[IPv6:a1:]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONEND"
  },
  %{
    id: 244,
    address: "first.last@[IPv6:a1::]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 245,
    address: "first.last@[IPv6:a1:::]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 246,
    address: "first.last@[IPv6:a1:a2:]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONEND"
  },
  %{
    id: 247,
    address: "first.last@[IPv6:a1:a2::]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 248,
    address: "first.last@[IPv6:a1:a2:::]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 249,
    address: "first.last@[IPv6:0123:4567:89ab:cdef::]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 250,
    address: "first.last@[IPv6:0123:4567:89ab:CDEF::]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 251,
    address: "first.last@[IPv6:::a3:a4:b1:ffff:11.22.33.44]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 252,
    address: "first.last@[IPv6:::a2:a3:a4:b1:ffff:11.22.33.44]",
    category: "ISEMAIL_RFC5321",
    comment: ":: only elides one zero group (IPv6 authority is RFC 4291)",
    diagnosis: "ISEMAIL_RFC5321_IPV6DEPRECATED"
  },
  %{
    id: 253,
    address: "first.last@[IPv6:a1:a2:a3:a4::11.22.33.44]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 254,
    address: "first.last@[IPv6:a1:a2:a3:a4:b1::11.22.33.44]",
    category: "ISEMAIL_RFC5321",
    comment: ":: only elides one zero group (IPv6 authority is RFC 4291)",
    diagnosis: "ISEMAIL_RFC5321_IPV6DEPRECATED"
  },
  %{
    id: 255,
    address: "first.last@[IPv6::11.22.33.44]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONSTRT"
  },
  %{
    id: 256,
    address: "first.last@[IPv6::::11.22.33.44]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 257,
    address: "first.last@[IPv6:a1:11.22.33.44]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_GRPCOUNT"
  },
  %{
    id: 258,
    address: "first.last@[IPv6:a1::11.22.33.44]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 259,
    address: "first.last@[IPv6:a1:::11.22.33.44]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 260,
    address: "first.last@[IPv6:a1:a2::11.22.33.44]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 261,
    address: "first.last@[IPv6:a1:a2:::11.22.33.44]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 262,
    address: "first.last@[IPv6:0123:4567:89ab:cdef::11.22.33.44]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 263,
    address: "first.last@[IPv6:0123:4567:89ab:cdef::11.22.33.xx]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_BADCHAR"
  },
  %{
    id: 264,
    address: "first.last@[IPv6:0123:4567:89ab:CDEF::11.22.33.44]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 265,
    address: "first.last@[IPv6:0123:4567:89ab:CDEFF::11.22.33.44]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_BADCHAR"
  },
  %{
    id: 266,
    address: "first.last@[IPv6:a1::a4:b1::b4:11.22.33.44]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 267,
    address: "first.last@[IPv6:a1::11.22.33]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_BADCHAR"
  },
  %{
    id: 268,
    address: "first.last@[IPv6:a1::11.22.33.44.55]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_BADCHAR"
  },
  %{
    id: 269,
    address: "first.last@[IPv6:a1::b211.22.33.44]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_BADCHAR"
  },
  %{
    id: 270,
    address: "first.last@[IPv6:a1::b2:11.22.33.44]",
    category: "ISEMAIL_RFC5321",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5321_ADDRESSLITERAL"
  },
  %{
    id: 271,
    address: "first.last@[IPv6:a1::b2::11.22.33.44]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_2X2XCOLON"
  },
  %{
    id: 272,
    address: "first.last@[IPv6:a1::b3:]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONEND"
  },
  %{
    id: 273,
    address: "first.last@[IPv6::a2::b4]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONSTRT"
  },
  %{
    id: 274,
    address: "first.last@[IPv6:a1:a2:a3:a4:b1:b2:b3:]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONEND"
  },
  %{
    id: 275,
    address: "first.last@[IPv6::a2:a3:a4:b1:b2:b3:b4]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_COLONSTRT"
  },
  %{
    id: 276,
    address: "first.last@[IPv6:a1:a2:a3:a4::b1:b2:b3:b4]",
    category: "ISEMAIL_RFC5322",
    comment: "IPv6 authority is RFC 4291",
    diagnosis: "ISEMAIL_RFC5322_IPV6_MAXGRPS"
  },
  %{
    id: 277,
    address: "test@test.com",
    category: "ISEMAIL_DNSWARN",
    comment: "test.com has an A-record but not an MX-record",
    diagnosis: "ISEMAIL_DNSWARN_NO_MX_RECORD"
  },
  %{
    id: 278,
    address: "test@example.com␊",
    category: "ISEMAIL_ERR",
    comment: "Address has a newline at the end",
    diagnosis: "ISEMAIL_ERR_EXPECTING_ATEXT"
  },
  %{
    id: 279,
    address: "test@xn--example.com",
    category: "ISEMAIL_DNSWARN",
    comment: "Address is at an Internationalized Domain Name (Punycode)",
    diagnosis: "ISEMAIL_DNSWARN_NO_RECORD"
  }
]