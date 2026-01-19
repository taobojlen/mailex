[
  # Date header errors
  %{
    id: "bad_date_header",
    file: "bad_date_header.eml",
    category: :date_header,
    expect: %{
      result: :ok,
      subject: "You may_be Eligible for Legitimate_Cash from_GovAgencies!"
    }
  },
  %{
    id: "bad_date_header2",
    file: "bad_date_header2.eml",
    category: :date_header,
    expect: %{
      result: :ok,
      subject: "40% OFF holiday patterns and fabric!"
    }
  },

  # Subject encoding errors
  %{
    id: "bad_encoded_subject",
    file: "bad_encoded_subject.eml",
    category: :subject,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "bad_subject",
    file: "bad_subject.eml",
    category: :subject,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "invalid_subject_characters",
    file: "invalid_subject_characters.eml",
    category: :subject,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "trademark_character_in_subject",
    file: "trademark_character_in_subject.eml",
    category: :subject,
    expect: %{
      result: :ok
    }
  },

  # Addressing errors
  %{
    id: "cant_parse_from",
    file: "cant_parse_from.eml",
    category: :addressing,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "weird_to_header",
    file: "weird_to_header.eml",
    category: :addressing,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "new_line_in_to_header",
    file: "new_line_in_to_header.eml",
    category: :addressing,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "empty_group_lists",
    file: "empty_group_lists.eml",
    category: :addressing,
    expect: %{
      result: :ok
    }
  },

  # Content-Transfer-Encoding errors
  %{
    id: "cte_7_bit",
    file: "content_transfer_encoding_7-bit.eml",
    category: :cte,
    expect: %{
      result: :ok,
      content_type: {"multipart", "alternative"}
    }
  },
  %{
    id: "cte_empty",
    file: "content_transfer_encoding_empty.eml",
    category: :cte,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "cte_plain",
    file: "content_transfer_encoding_plain.eml",
    category: :cte,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "cte_qp_with_space",
    file: "content_transfer_encoding_qp_with_space.eml",
    category: :cte,
    expect: %{
      result: :ok,
      content_type: {"multipart", "alternative"}
    }
  },
  %{
    id: "cte_spam",
    file: "content_transfer_encoding_spam.eml",
    category: :cte,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "cte_text_html",
    file: "content_transfer_encoding_text-html.eml",
    category: :cte,
    expect: %{
      result: :ok,
      content_type: {"multipart", "alternative"}
    }
  },
  %{
    id: "cte_with_8bits",
    file: "content_transfer_encoding_with_8bits.eml",
    category: :cte,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "cte_with_semi_colon",
    file: "content_transfer_encoding_with_semi_colon.eml",
    category: :cte,
    expect: %{
      result: :ok,
      content_type: {"multipart", "alternative"}
    }
  },
  %{
    id: "cte_x_uuencode",
    file: "content_transfer_encoding_x_uuencode.eml",
    category: :cte,
    expect: %{
      result: :ok,
      content_type: {"multipart", "mixed"}
    }
  },

  # References/In-Reply-To errors
  %{
    id: "empty_in_reply_to",
    file: "empty_in_reply_to.eml",
    category: :references,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "multiple_references_with_one_invalid",
    file: "multiple_references_with_one_invalid.eml",
    category: :references,
    expect: %{
      result: :ok,
      content_type: {"multipart", "alternative"}
    }
  },

  # Encoding issues
  %{
    id: "encoding_madness",
    file: "encoding_madness.eml",
    category: :encoding,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "must_supply_encoding",
    file: "must_supply_encoding.eml",
    category: :encoding,
    expect: %{
      result: :ok,
      content_type: {"multipart", "alternative"}
    }
  },

  # Header issues
  %{
    id: "header_fields_with_empty_values",
    file: "header_fields_with_empty_values.eml",
    category: :headers,
    expect: %{
      result: :ok,
      subject: "Testmail"
    }
  },

  # Body/structure issues
  %{
    id: "missing_body",
    file: "missing_body.eml",
    category: :body,
    expect: %{
      result: :ok,
      subject: "REDACTED"
    }
  },

  # MIME/Content-Type/Disposition issues
  %{
    id: "missing_content_disposition",
    file: "missing_content_disposition.eml",
    category: :mime,
    expect: %{
      result: :ok,
      content_type: {"multipart", "related"}
    }
  },
  %{
    id: "multiple_content_types",
    file: "multiple_content_types.eml",
    category: :mime,
    expect: %{
      result: :ok
    }
  },
  %{
    id: "multiple_invalid_content_dispositions",
    file: "multiple_invalid_content_dispositions.eml",
    category: :mime,
    expect: %{
      result: :ok
    }
  }
]
