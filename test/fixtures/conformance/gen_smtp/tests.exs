[
  # Plain text messages
  %{
    id: "plain_text_only",
    file: "Plain-text-only.eml",
    category: :plain,
    expect: %{
      result: :ok,
      subject: "Plain text only",
      from: "Micah Warren <micahw@fusedsolutions.com>",
      content_type: {"text", "plain"},
      has_body: true,
      parts_count: nil
    }
  },
  %{
    id: "plain_text_no_mime",
    file: "Plain-text-only-no-MIME.eml",
    category: :plain,
    expect: %{
      result: :ok,
      subject: "Plain text only",
      content_type: {"text", "plain"},
      has_body: true,
      parts_count: nil
    }
  },
  %{
    id: "plain_text_no_content_type",
    file: "Plain-text-only-no-content-type.eml",
    category: :plain,
    expect: %{
      result: :ok,
      subject: "Plain text only",
      has_body: true,
      parts_count: nil
    }
  },
  %{
    id: "plain_text_with_boundary_header",
    file: "Plain-text-only-with-boundary-header.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "Plain text only"
    }
  },
  %{
    id: "python_smtp_lib",
    file: "python-smtp-lib.eml",
    category: :plain,
    expect: %{
      result: :ok,
      subject: "A trame",
      has_body: true
    }
  },

  # Multipart alternative (HTML)
  %{
    id: "html",
    file: "html.eml",
    category: :multipart,
    expect: %{
      result: :ok,
      subject: "html",
      content_type: {"multipart", "alternative"},
      parts_count: 2
    }
  },
  %{
    id: "rich_text",
    file: "rich-text.eml",
    category: :multipart,
    expect: %{
      result: :ok,
      subject: "rich text only",
      content_type: {"multipart", "alternative"},
      parts_count: 2
    }
  },
  %{
    id: "outlook_2007",
    file: "outlook-2007.eml",
    category: :multipart,
    expect: %{
      result: :ok,
      subject: "outlook sending to http://jackcanty.com",
      content_type: {"multipart", "alternative"},
      parts_count: 2
    }
  },

  # Malformed boundary handling
  %{
    id: "rich_text_bad_boundary",
    file: "rich-text-bad-boundary.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "rich text only"
    }
  },
  %{
    id: "rich_text_no_boundary",
    file: "rich-text-no-boundary.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "rich text only"
    }
  },
  %{
    id: "rich_text_missing_first_boundary",
    file: "rich-text-missing-first-boundary.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "rich text only"
    }
  },
  %{
    id: "rich_text_missing_last_boundary",
    file: "rich-text-missing-last-boundary.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "rich text only"
    }
  },
  %{
    id: "rich_text_broken_last_boundary",
    file: "rich-text-broken-last-boundary.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "rich text only"
    }
  },
  %{
    id: "rich_text_no_text_contenttype",
    file: "rich-text-no-text-contenttype.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "rich text only",
      parts_count: 2
    }
  },
  %{
    id: "rich_text_no_mime",
    file: "rich-text-no-MIME.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "rich text only",
      parts_count: 2
    }
  },

  # Attachments
  %{
    id: "text_attachment_only",
    file: "text-attachment-only.eml",
    category: :attachment,
    expect: %{
      result: :ok,
      subject: "text attachment only",
      content_type: {"multipart", "mixed"},
      attachments_count: 1
    }
  },
  %{
    id: "image_attachment_only",
    file: "image-attachment-only.eml",
    category: :attachment,
    expect: %{
      result: :ok,
      subject: "image attachment only",
      content_type: {"multipart", "mixed"},
      attachments_count: 1
    }
  },
  %{
    id: "image_and_text_attachments",
    file: "image-and-text-attachments.eml",
    category: :attachment,
    expect: %{
      result: :ok,
      subject: "image and text attachments",
      content_type: {"multipart", "mixed"},
      attachments_count: 2
    }
  },
  %{
    id: "plain_text_and_two_identical_attachments",
    file: "plain-text-and-two-identical-attachments.eml",
    category: :attachment,
    expect: %{
      result: :ok,
      subject: "plain text and two identical attachments",
      content_type: {"multipart", "mixed"},
      attachments_count: 2
    }
  },

  # Complex structures (nested messages)
  %{
    id: "message_as_attachment",
    file: "message-as-attachment.eml",
    category: :nested,
    expect: %{
      result: :ok,
      subject: "message as attachment",
      content_type: {"multipart", "mixed"},
      has_message_rfc822_part: true
    }
  },
  %{
    id: "message_image_text_attachments",
    file: "message-image-text-attachments.eml",
    category: :nested,
    expect: %{
      result: :ok,
      subject: "message image text attachments",
      content_type: {"multipart", "mixed"},
      has_message_rfc822_part: true
    }
  },
  %{
    id: "message_text_html_attachment",
    file: "message-text-html-attachment.eml",
    category: :nested,
    expect: %{
      result: :ok,
      subject: "A message with text, html and a calendar attachment",
      content_type: {"multipart", "mixed"}
    }
  },
  %{
    id: "the_gamut",
    file: "the-gamut.eml",
    category: :nested,
    expect: %{
      result: :ok,
      subject: "The gamut",
      content_type: {"multipart", "alternative"}
    }
  },

  # Unicode / encoding
  %{
    id: "unicode_subject",
    file: "unicode-subject.eml",
    category: :unicode,
    expect: %{
      result: :ok,
      subject: "①⓫⅓㏨♳𝄞λ",
      has_body: true
    }
  },
  %{
    id: "unicode_body",
    file: "unicode-body.eml",
    category: :unicode,
    expect: %{
      result: :ok,
      subject: "unicode body",
      content_type: {"multipart", "alternative"},
      parts_count: 2
    }
  },
  %{
    id: "utf_attachment_name",
    file: "utf-attachment-name.eml",
    category: :unicode,
    expect: %{
      result: :ok,
      subject: "Hello",
      content_type: {"multipart", "mixed"},
      attachments_count: 1
    }
  },
  %{
    id: "malformed_folded_multibyte_header",
    file: "malformed-folded-multibyte-header.eml",
    category: :unicode,
    expect: %{
      result: :ok,
      has_body: true
    }
  }
]
