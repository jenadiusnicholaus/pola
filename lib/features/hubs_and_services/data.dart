class HubsAndServicesData {
  // HUB_TYPES = [
  //     ('advocates', 'Advocates Hub'),
  //     ('students', 'Students Hub'),
  //     ('forum', 'Forum'),
  //     ('legal_ed', 'Legal Education'),

  // services
  //     ('talk_to_lawyers', 'Talk to Lawyers'),
  //     ('document_scanner', 'Document Scanner'),
  //     ('legal_templates', 'Legal Templates'),
  //     ('search_nearby_lawyers', 'Search Nearby Lawyers'),

  static const List<Map<String, String>> hubAndServices = [
    {
      'key': 'legal_ed',
      'label_eng': 'Legal Education',
      'label_sw': 'Elimu ya Kisheria',
      'subtitle_eng': 'Learn the law step by step',
      'subtitle_sw': 'Jifunze sheria hatua kwa hatua',
      "type": "hub",
    },
    {
      'key': 'talk_to_lawyers',
      'label_eng': 'Talk to Lawyers',
      'label_sw': 'Ongea na Mwanasheria',
      'subtitle_eng': 'Chat with verified advocates',
      'subtitle_sw': 'Ongea na mawakili walioidhinishwa',
      "type": "service",
    },
    {
      'key': 'ask_a_legal_question',
      'label_eng': 'Ask a Legal Question',
      'label_sw': 'Uliza Swali la Kisheria',
      'subtitle_eng': 'Get answers to your questions',
      'subtitle_sw': 'Pata majibu ya maswali yako',
      "type": "service",
    },
    {
      'key': 'forum',
      'label_eng': 'Community Forum',
      'label_sw': 'Jukwaa la Jamii',
      'subtitle_eng': 'Discuss with the community',
      'subtitle_sw': 'Jadiliana na jamii',
      "type": "hub",
    },
    {
      'key': 'legal_templates',
      'label_eng': 'Legal Templates',
      'label_sw': 'Nyaraka za Kisheria',
      'subtitle_eng': 'Ready-made legal documents',
      'subtitle_sw': 'Hati za kisheria tayari',
      "type": "service",
    },
    {
      'key': 'tanzania_statutes_laws',
      'label_eng': 'Tanzania Statutes and Laws',
      'label_sw': 'Sheria ya nchi ya Tanzania',
      'subtitle_eng': 'Browse national legislation',
      'subtitle_sw': 'Vinjari sheria za nchi',
      "type": "service",
    },
    {
      'key': 'advocates',
      'label_eng': 'Advocates Hub',
      'label_sw': 'Jukwaa la Mawakili',
      'subtitle_eng': 'Tools for practicing lawyers',
      'subtitle_sw': 'Zana kwa mawakili',
      "type": "hub",
    },
    {
      'key': 'students',
      'label_eng': 'Students and Lecturers Hub',
      'label_sw': 'Jukwaa la Wanafunzi/Wakufunzi  wa Sheria',
      'subtitle_eng': 'Resources for law students',
      'subtitle_sw': 'Rasilimali kwa wanafunzi wa sheria',
      "type": "hub",
    },
    {
      'key': 'search_nearby_lawyers',
      'label_eng': 'Search Nearby Lawyers',
      'label_sw': 'Tafuta Mawakili Karibu',
      'subtitle_eng': 'Find lawyers near you',
      'subtitle_sw': 'Tafuta mawakili karibu nawe',
      "type": "service",
    },
  ];
}
