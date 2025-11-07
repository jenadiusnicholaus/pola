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
      "type": "hub",
    },
    {
      'key': 'talk_to_lawyers',
      'label_eng': 'Talk to Lawyers',
      'label_sw': 'Ongea na Mwanasheria',
      "type": "service",
    },
    {
      'key': 'ask_a_legal_question',
      'label_eng': 'Ask a Legal Question',
      'label_sw': 'Uliza Swali la Kisheria',
      "type": "service",
    },
    {
      'key': 'forum',
      'label_eng': 'Community Forum',
      'label_sw': 'Jukwaa la Jamii',
      "type": "hub",
    },
    {
      'key': 'legal_templates',
      'label_eng': 'Legal Templates',
      'label_sw': 'Nyaraka za Kisheria',
      "type": "service",
    },
    {
      'key': 'tanzania_statutes_laws',
      'label_eng': 'Tanzania Statutes and Laws',
      'label_sw': 'Sheria ya nchi ya Tanzania',
      "type": "service",
    },
    {
      'key': 'advocates',
      'label_eng': 'Advocates Hub',
      'label_sw': 'Jukwaa la Mawakili',
      "type": "hub",
    },
    {
      'key': 'students',
      'label_eng': 'Students and Lecturers Hub',
      'label_sw': 'Jukwaa la Wanafunzi/Wakufunzi  wa Sheria',
      "type": "hub",
    },
    {
      'key': 'search_nearby_lawyers',
      'label_eng': 'Search Nearby Lawyers',
      'label_sw': 'Tafuta Mawakili Karibu',
      "type": "service",
    },
  ];
}
