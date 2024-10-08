typedef void MyFunction(int);
typedef void MyFunction2(String);

///
class Const {
  /// encoding types used in samsaadhanii tools
  static String UNICODE_DEVANAGARI = "Unicode-Devanagari";
  static String WX_ALPHABETIC = "WX-Alphabetic";
  static String ITRANS_5_3 = "Itrans-5.3";
  static String VELTHUIS = "Velthuis";
  static String SLP1 = "SLP1";
  static String KYOTO_HARVARD_KH = "Kyoto-Harvard(KH)";
  static String IAST_ROMAN_DIACRITIC = "IAST(Roman Diacritic)";

  /// input and output encoding lists
  static List<String> inputEncodingList = [
    UNICODE_DEVANAGARI,
    WX_ALPHABETIC,
    ITRANS_5_3,
    VELTHUIS,
    SLP1,
    KYOTO_HARVARD_KH,
    IAST_ROMAN_DIACRITIC,
  ];

  ///
  static List<String> outputEncodingList = [
    IAST_ROMAN_DIACRITIC,
    UNICODE_DEVANAGARI,
  ];

  /// encoding abbreviation for the encoding list
  static String encodingAbbreviation(String type) {
    if (type == UNICODE_DEVANAGARI) {
      return 'Unicode';
    } else if (type == WX_ALPHABETIC) {
      return 'WX';
    } else if (type == ITRANS_5_3) {
      return 'Itrans';
    } else if (type == KYOTO_HARVARD_KH) {
      return 'VH';
    } else if (type == SLP1) {
      return 'SLP';
    } else if (type == IAST_ROMAN_DIACRITIC) {
      return 'IAST';
    } else {
      return 'Unicode';
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

  /// verb encoding list
  static List<String> verbEncodingList = [
    IAST_ROMAN_DIACRITIC,
    UNICODE_DEVANAGARI,
    WX_ALPHABETIC,
  ];

  /// verb encoding abbreviation
  static String verbEncodingAbbreviation(String type) {
    if (type == IAST_ROMAN_DIACRITIC) {
      return 'rom';
    } else if (type == UNICODE_DEVANAGARI) {
      return 'dev';
    } else if (type == WX_ALPHABETIC) {
      return 'wx';
    } else {
      return 'dev';
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

  /// verb out encoding abbreviation list
  static String verbAPIOutEncodingAbbreviation(String type) {
    if (type == IAST_ROMAN_DIACRITIC) {
      return 'IAST';
    } else {
      return 'Devanagari';
    }
  }

  /// morph out encoding abbreviation list
  static String morphOutEncodingAbbreviation(String type) {
    if (type == IAST_ROMAN_DIACRITIC) {
      return 'IAST';
    } else {
      return 'DEV';
    }
  }

  /// encoding list for prefix
  static List<String> prefixEncodingList = [
    IAST_ROMAN_DIACRITIC,
    UNICODE_DEVANAGARI,
  ];

  /// prefix encoding abbreviation
  static String prefixEncodingAbbreviation(String type) {
    // Specific to Prefix in verb generator
    // The prefix list is in 'wx' amd 'dev' formats
    // but wee should display them in 'roman' and 'dev'
    // so convert 'wx' to 'roman'
    if (type == IAST_ROMAN_DIACRITIC) {
      return 'wx';
    } else if (type == UNICODE_DEVANAGARI) {
      return 'dev';
    } else {
      return 'dev';
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

  /// headings for the verb table
  static List<String> headings(String type) {
    if (type == UNICODE_DEVANAGARI) {
      return ['एकवचनम्', 'द्विवचनम्', 'बहुवचनम्'];
    } else {
      return ['ekavacanam', 'dvivacanam', 'bahuvacanam'];
    }
  }

  /// headings for the verb table
  static String CAT_NAMA = "नाम (nāma)";
  static String CAT_SARVANAMA = "सर्वनाम (sarvanāma)";
  static String CAT_NUMERAL = "सङ्ख्या (Numeral)";
  static String CAT_CARDINAL = "सङ्ख्येय (cardinal)";
  static String CAT_ORDINAL = "पूरण (ordinal)";

  /// category list for the morphological analysis
  static List<String> categoryList = [
    CAT_NAMA,
    CAT_SARVANAMA,
    CAT_NUMERAL,
    CAT_CARDINAL,
    CAT_ORDINAL,
  ];

  /// category abbreviation for the morphological analysis
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

  /// category name for the morphological analysis
  static String GEN_MASC = "पुंलिङ्गम् (masc)";
  static String GEN_NEUTER = "नपुंसकलिङ्गम् (neuter)";
  static String GEN_FEMININE = "स्त्रीलिङ्गम् (feminine)";
  static String GEN_FOR = "-(For अस्मद्, युष्मद्)";

  /// gender list for the morphological analysis
  static List<String> genderList = [
    GEN_MASC,
    GEN_NEUTER,
    GEN_FEMININE,
    GEN_FOR,
  ];

  /// gender abbreviation for the morphological analysis
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

  /// gender name for the morphological analysis
  static String genderName(String type, String encode) {
    if (encode == UNICODE_DEVANAGARI) {
      if (type == GEN_MASC) {
        return 'पुं';
      } else if (type == GEN_NEUTER) {
        return 'नपुंसक';
      } else if (type == GEN_FEMININE) {
        return 'स्त्री';
      } else {
        return 'अ';
      }
    } else {
      if (type == GEN_MASC) {
        return 'puM';
      } else if (type == GEN_NEUTER) {
        return 'napuṃsaka';
      } else if (type == GEN_FEMININE) {
        return 'strī';
      } else {
        return 'a';
      }
    }
  }

  /// list of vibhakti for the IAST encoding
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

  /// list of vibhakti for the WX encoding
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

  /// list of vibhakti for the Devanagari encoding
  static List<String> sandhiTableHeadings(String type) {
    if (type == UNICODE_DEVANAGARI) {
      return [
        'प्रथमपदम्:  ',
        'द्वितीयपदम्:  ',
        'संहितपदम्:  ',
        'सन्धिः  ',
        'सूत्रम्/वार्तिकम्:  ',
      ];
    } else {
      return [
        'prathamapadam:  ',
        'dvitīyapadam:  ',
        'saṃhitapadam:  ',
        'sandhiḥ:  ',
        'sūtram/vārtikam:  ',
      ];
    }
  }

  static const String SENTENCE = "Sentence";
  static const String WORD = "Word";

  static List<String> textTypeList = [SENTENCE, WORD];

  /// text type abbreviation
  static String textTypeAbbreviation(String type) {
    if (type == SENTENCE) {
      return 'sent';
    } else {
      return 'word';
    }
  }

  /// output encoding abbreviation
  static String outEncodingAbbreviation(String type) {
    if (type == UNICODE_DEVANAGARI) {
      return 'D';
    } else {
      return 'I';
    }
  }

  /// list of padi for the verb generation
  static const String PARASMAIPADI = "Parasmaipadi";
  static const String ATMANEPADI = "Atmanepadi";

  static List<String> padiList = [ATMANEPADI, PARASMAIPADI];
}

enum LearnerLevel { basic, intermediate, advanced }

/// Global variables used to store the input and output encodings
/// to be used throughout the app
String inputEncodingStr = Const.inputEncodingList[0];
String outputEncodingStr = Const.outputEncodingList[0];
