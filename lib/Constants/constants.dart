class Const {
  static String UNICODE_DEVANAGARI = "Unicode-Devanagari";
  static String WX_ALPHABETIC = "WX-Alphabetic";
  static String ITRANS_5_3 = "Itrans-5.3";
  static String VELTHUIS = "Velthuis";
  static String SLP1 = "SLP1";
  static String KYOTO_HARVARD_KH = "Kyoto-Harvard(KH)";
  static String IAST_ROMAN_DIACRITIC = "IAST(Roman Diacritic)";

  static List<String> inputEncodingList = [
    UNICODE_DEVANAGARI,
    WX_ALPHABETIC,
    ITRANS_5_3,
    VELTHUIS,
    SLP1,
    KYOTO_HARVARD_KH,
    IAST_ROMAN_DIACRITIC,
  ];

  static List<String> outputEncodingList = [
    IAST_ROMAN_DIACRITIC,
    UNICODE_DEVANAGARI,
  ];
  static String encodingAbbreviation(String type) {
    if (type == UNICODE_DEVANAGARI) {
      return 'Devanagari';
    } else if (type == WX_ALPHABETIC) {
      return 'WX';
    } else if (type == ITRANS_5_3) {
      return 'Itrans';
    } else if (type == KYOTO_HARVARD_KH) {
      return 'HK';
    } else if (type == SLP1) {
      return 'SLP1';
    } else if (type == IAST_ROMAN_DIACRITIC) {
      return 'IAST';
    } else {
      return 'Devanagari';
    }
    /*
    * Roman (Harvard-Kyoto)	HK
Roman (IAST)	IAST

Roman (ITRANS)	Itrans
Roman (SLP1)	SLP1
Roman (WX)	WX
Devanagari	Devanagari
    * */
  }

  static List<String> headings(String type) {
    if (type == UNICODE_DEVANAGARI) {
      return ['एकवचनम्', 'द्विवचनम्', 'बहुवचनम्'];
    } else {
      return ['ekavacanam', 'dvivacanam', 'bahuvacanam'];
    }
  }

  static List<String> categoryList = [
    'नाम (nāma)',
    'सर्वनाम (sarvanāma)',
    'सङ्ख्या (Numeral)',
    'सङ्ख्येय (cardinal)',
    'पूरण (ordinal)',
  ];
  static List<String> genderList = [
    'पुंलिङ्गम् (masc)',
    'नपुंसकलिङ्गम् (neuter)',
    'स्त्रीलिङ्गम् (feminine)',
    '-(For अस्मद्, युष्मद्)',
  ];

  static List<String> vibList = [
    'prathamā',
    'dvitīyā',
    'tṛtīyā',
    'pañcamī',
    'ṣaṣṭhī',
    'saptamī',
    'saṃ.pra',
  ];
}
