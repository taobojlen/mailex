[
  # Standard email fixtures (mail_test_1 through mail_test_18)
  %{
    id: "mail_test_1",
    file: "mail_test_1.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "письмо уведом-е",
      from: "служба ФНС Даниил Суворов <suvorov.s@nalg.ru>",
      content_type: {"multipart", "mixed"},
      parts_count: 3,
      attachments_count: 1
    }
  },
  %{
    id: "mail_test_2",
    file: "mail_test_2.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Bollettino Meteorologico del 29/11/2015",
      from: "<meteo@regione.vda.it>",
      content_type: {"multipart", "mixed"},
      parts_count: 2,
      attachments_count: 3
    }
  },
  %{
    id: "mail_test_3",
    file: "mail_test_3.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Hi there",
      from: "\"Ava Oneil\" <Oneil.844@randtelekom.com.tr>",
      content_type: {"multipart", "mixed"},
      parts_count: 2,
      attachments_count: 1
    }
  },
  %{
    id: "mail_test_4",
    file: "mail_test_4.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "PI",
      from: "\"Anabel Gonzalo\"<anabelgonzalo@fanox.com>",
      content_type: {"multipart", "mixed"},
      parts_count: 2,
      attachments_count: 2
    }
  },
  %{
    id: "mail_test_5",
    file: "mail_test_5.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Je prépare mon été zéro complexe !",
      from: "\"Marina de Carlance\" <contact@carlance.fr>",
      content_type: {"multipart", "alternative"},
      parts_count: 2,
      attachments_count: 5
    }
  },
  %{
    id: "mail_test_6",
    file: "mail_test_6.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Быстрее вкладывайте в золото!",
      from: "Время пришло <noreply@ggg.com>",
      content_type: {"multipart", "related"},
      parts_count: 5,
      attachments_count: 0
    }
  },
  %{
    id: "mail_test_7",
    file: "mail_test_7.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "I: Ordine",
      from: "Mariachiara Geronazzo <geronazzo@voidstudicom.it>",
      content_type: {"multipart", "mixed"},
      parts_count: 9,
      attachments_count: 8
    }
  },
  %{
    id: "mail_test_8",
    file: "mail_test_8.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Have you ever wanted to land on an Aircraft Carrier",
      from: "\"Helicopter_flight_simulator\" <Helicopter_flight_simulator@moneytrack.top>",
      content_type: {"multipart", "alternative"},
      parts_count: 2,
      attachments_count: 0
    }
  },
  %{
    id: "mail_test_9",
    file: "mail_test_9.eml",
    category: :standard,
    expect: %{
      result: :ok,
      # Subject is GB2312 encoded, not decoded to UTF-8
      from: "\"xwfcpggy\" <zyb@sgis.com.cn>",
      content_type: {"text", "html"},
      has_body: true
    }
  },
  %{
    id: "mail_test_10",
    file: "mail_test_10.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "*** ATTENZIONE *** - Modelli POWER7+ inclusi nella campagna Move To Eight",
      from: "Nicoletta Bernasconi <nicoletta_bernasconi@it.ibm.com>",
      content_type: {"multipart", "mixed"},
      parts_count: 2,
      attachments_count: 1
    }
  },
  %{
    id: "mail_test_11",
    file: "mail_test_11.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "письмо уведом-е",
      from: "служба ФНС Даниил Суворов <suvorov.s@nalg.ru>",
      content_type: {"multipart", "mixed"},
      parts_count: 3,
      attachments_count: 1
    }
  },
  %{
    id: "mail_test_12",
    file: "mail_test_12.eml",
    category: :standard,
    expect: %{
      result: :ok,
      # Subject and From are GB2312 encoded, not decoded to UTF-8
      content_type: {"text", "plain"},
      has_body: true
    }
  },
  %{
    id: "mail_test_13",
    file: "mail_test_13.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "New Webinar: So, You Have A Disaster... Now What?",
      from: "Continuity Insights <info@continuityinsights.com>",
      content_type: {"multipart", "alternative"},
      parts_count: 2,
      attachments_count: 0
    }
  },
  %{
    id: "mail_test_14",
    file: "mail_test_14.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Test",
      from: "example@example.com",
      content_type: {"multipart", "mixed"},
      parts_count: 3,
      attachments_count: 0
    }
  },
  %{
    id: "mail_test_15",
    file: "mail_test_15.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Urgent Request for Order Quotation",
      from: "purchasing@aquillaindustries.com <do-not-reply@ncs.gov.ng>",
      content_type: {"multipart", "mixed"},
      parts_count: 2,
      attachments_count: 1
    }
  },
  %{
    id: "mail_test_16",
    file: "mail_test_16.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Test spam mail (GTUBE)",
      from: "Sender <sender@example.net>",
      content_type: {"text", "plain"},
      has_body: true
    }
  },
  %{
    id: "mail_test_17",
    file: "mail_test_17.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Transferencia Interbancaria Banca en Línea",
      from: "notificaccion-clientes@bbva.mx\t<notificaccion-clientes@bbva.mx>",
      content_type: {"multipart", "mixed"},
      parts_count: 1,
      attachments_count: 0
    }
  },
  %{
    id: "mail_test_18",
    file: "mail_test_18.eml",
    category: :standard,
    expect: %{
      result: :ok,
      subject: "Test for Comma and Name Bugs",
      from: "LastßlName, FirstName <comma.name@example.com>",
      content_type: {"text", "plain"},
      has_body: true
    }
  },

  # Malformed email fixtures (mail_malformed_1 through mail_malformed_3)
  # These have various RFC violations but Mailex parses them leniently
  %{
    id: "mail_malformed_1",
    file: "mail_malformed_1.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "immagine",
      from: "<femucca@tin.it>",
      content_type: {"multipart", "mixed"},
      parts_count: 3
    }
  },
  %{
    id: "mail_malformed_2",
    file: "mail_malformed_2.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "Delivery failure (abh@netpar.com.br)",
      from: "postmaster@netpar.com.br",
      content_type: {"multipart", "report"},
      parts_count: 3,
      attachments_count: 1
    }
  },
  %{
    id: "mail_malformed_3",
    file: "mail_malformed_3.eml",
    category: :malformed,
    expect: %{
      result: :ok,
      subject: "Ahorre Dinero en su Recibo de Luz",
      from: "\"El Punto de los Frutos & Verdes\" <smgsiso@yahoo.com.mx>",
      content_type: {"multipart", "alternative"},
      parts_count: 0
    }
  }
]
