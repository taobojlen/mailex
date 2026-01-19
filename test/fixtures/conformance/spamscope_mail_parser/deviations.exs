%{
  # Document any intentional deviations from expected behavior here.
  # Format:
  # "test_id" => %{
  #   reason: "Explanation of why Mailex behaves differently",
  #   behavior: :expected_error | :different_output | :skip,
  #   tracking_issue: "optional link to issue"
  # }

  # mail_test_9 and mail_test_12 have GB2312 encoded headers that Mailex
  # does not decode to UTF-8. This is a known limitation.
  "mail_test_9" => %{
    reason: "GB2312 encoded subject not decoded to UTF-8",
    behavior: :different_output
  },
  "mail_test_12" => %{
    reason: "GB2312 encoded subject and from not decoded to UTF-8",
    behavior: :different_output
  },

  # mail_outlook_1.msg is a Microsoft Outlook .msg file (OLE/COM format),
  # not RFC 5322 email. Mailex only parses standard .eml format.
  "mail_outlook_1" => %{
    reason: "Outlook .msg format not supported (OLE/COM binary, not RFC 5322)",
    behavior: :skip
  }
}
