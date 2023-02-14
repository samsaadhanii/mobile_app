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

  static String CAT_NAMA = "नाम (nāma)";
  static String CAT_SARVANAMA = "सर्वनाम (sarvanāma)";
  static String CAT_NUMERAL = "सङ्ख्या (Numeral)";
  static String CAT_CARDINAL = "सङ्ख्येय (cardinal)";
  static String CAT_ORDINAL = "पूरण (ordinal)";

  static List<String> categoryList = [
    CAT_NAMA,
    CAT_SARVANAMA,
    CAT_NUMERAL,
    CAT_CARDINAL,
    CAT_ORDINAL,
  ];

  static String catAbbreviation(String type) {
    if (type == CAT_NAMA) {
      return 'nA';
    } else if (type == CAT_SARVANAMA) {
      return 'sarva';
    } else if (type == CAT_NUMERAL) {
      return 'saMKyA';
    } else if (type == CAT_CARDINAL) {
      return 'saMKyeyam';
    } else {
      return 'pUraNam';
    }
  }

  static String GEN_MASC = "पुंलिङ्गम् (masc)";
  static String GEN_NEUTER = "नपुंसकलिङ्गम् (neuter)";
  static String GEN_FEMININE = "स्त्रीलिङ्गम् (feminine)";
  static String GEN_FOR = "-(For अस्मद्, युष्मद्)";

  static List<String> genderList = [
    GEN_MASC,
    GEN_NEUTER,
    GEN_FEMININE,
    GEN_FOR,
  ];
  static String genderAbbreviation(String type) {
    if (type == GEN_MASC) {
      return 'puM';
    } else if (type == GEN_NEUTER) {
      return 'napuM';
    } else if (type == GEN_FEMININE) {
      return 'swrI';
    } else {
      return 'a';
    }
  }

  static List<String> vibList_IAST = [
    'prathamā',
    'dvitīyā',
    'tṛtīyā',
    'caturthī',
    'pañcamī',
    'ṣaṣṭhī',
    'saptamī',
    'saṃ.pra',
  ];

  static List<String> vibList_WX = [
    'praWamA',
    'xviwIyA',
    'wqwIyA',
    'cawurWI',
    'paFcamI',
    'RaRTI',
    'sapwamI',
    'samboXana',
    '',
  ];
}
