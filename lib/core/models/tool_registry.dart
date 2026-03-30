import 'tool_config.dart';

// Encoding option lists — mirrors Const.inputEncodingList / outputEncodingList
// kept here as const so ToolParam constructors stay const.
const _inputEncodings = [
  'Unicode-Devanagari',
  'WX-Alphabetic',
  'Itrans-5.3',
  'Velthuis',
  'SLP1',
  'Kyoto-Harvard(KH)',
  'IAST(Roman Diacritic)',
];

const _outputEncodings = [
  'IAST(Roman Diacritic)',
  'Unicode-Devanagari',
];

class ToolRegistry {
  static const List<ToolConfig> tools = [
    // ── Morphological analyser ──────────────────────────────────────────────
    // API: morfword=<word>&encoding=<enc>&outencoding=<enc>&mode=json
    ToolConfig(
      id: 'morph_analyser',
      nameEn: 'Morphological analyser',
      nameSa: 'शब्द-विश्लेषक',
      description: 'Gives all possible analyses of a Sanskrit word',
      category: ToolCategory.analysis,
      outputType: ToolOutputType.table,
      apiEndpoint: 'morph',
      params: [
        ToolParam(
          key: 'morfword',
          label: 'Input Word',
        ),
        ToolParam(
          key: 'encoding',
          label: 'Input Encoding',
          options: _inputEncodings,
        ),
        ToolParam(
          key: 'outencoding',
          label: 'Output Encoding',
          options: _outputEncodings,
        ),
      ],
    ),

    // ── Sandhi analyser ─────────────────────────────────────────────────────
    // API: word=<text>&encoding=<enc>&outencoding=<enc>&mode=<sent|word>&disp_mode=json
    ToolConfig(
      id: 'sandhi_analyser',
      nameEn: 'Sandhi analyser',
      nameSa: 'सन्धि-विश्लेषक',
      description: 'Shows all possible splittings of a Sanskrit string',
      category: ToolCategory.analysis,
      outputType: ToolOutputType.list,
      apiEndpoint: 'sandhi_split',
      params: [
        ToolParam(
          key: 'word',
          label: 'Input Text',
        ),
        ToolParam(
          key: 'mode',
          label: 'Text Type',
          options: ['Sentence', 'Word'],
        ),
        ToolParam(
          key: 'encoding',
          label: 'Input Encoding',
          options: _inputEncodings,
        ),
        ToolParam(
          key: 'outencoding',
          label: 'Output Encoding',
          options: _outputEncodings,
        ),
      ],
    ),

    // ── Sandhi joining ──────────────────────────────────────────────────────
    // API: word1=<w1>&word2=<w2>&encoding=<enc>&outencoding=<enc>
    ToolConfig(
      id: 'sandhi_joining',
      nameEn: 'Sandhi joining',
      nameSa: 'सन्धि-कारक',
      description: 'Joins two Sanskrit words following Paninian sutras',
      category: ToolCategory.analysis,
      outputType: ToolOutputType.list,
      apiEndpoint: 'sandhi',
      params: [
        ToolParam(
          key: 'word1',
          label: 'First Word',
        ),
        ToolParam(
          key: 'word2',
          label: 'Second Word',
        ),
        ToolParam(
          key: 'encoding',
          label: 'Input Encoding',
          options: _inputEncodings,
        ),
        ToolParam(
          key: 'outencoding',
          label: 'Output Encoding',
          options: _outputEncodings,
        ),
      ],
    ),

    // ── Noun generator ──────────────────────────────────────────────────────
    // API: rt=<stem>&gen=<gender>&jAwi=<category>&level=1&mode=json
    //      &encoding=<enc>&outencoding=<enc>
    ToolConfig(
      id: 'noun_generator',
      nameEn: 'Noun generator',
      nameSa: 'नामरूप-निष्पादिका',
      description: 'Shows inflectional forms of a given noun',
      category: ToolCategory.generation,
      outputType: ToolOutputType.table,
      apiEndpoint: 'noun_gen',
      params: [
        ToolParam(
          key: 'rt',
          label: 'Prātipadikam (Noun Stem)',
        ),
        ToolParam(
          key: 'gen',
          label: 'Gender (Liṅga)',
          options: [
            'पुंलिङ्गम् (masc)',
            'नपुंसकलिङ्गम् (neuter)',
            'स्त्रीलिङ्गम् (feminine)',
            '-(For अस्मद्, युष्मद्)',
          ],
        ),
        ToolParam(
          key: 'jAwi',
          label: 'Category (Jāti)',
          options: [
            'नाम (nāma)',
            'सर्वनाम (sarvanāma)',
            'सङ्ख्या (Numeral)',
            'सङ्ख्येय (cardinal)',
            'पूरण (ordinal)',
          ],
        ),
        ToolParam(
          key: 'encoding',
          label: 'Input Encoding',
          options: _inputEncodings,
        ),
        ToolParam(
          key: 'outencoding',
          label: 'Output Encoding',
          options: _outputEncodings,
        ),
      ],
    ),

    // ── Verb generator ──────────────────────────────────────────────────────
    // API: vb=<dhatu>&prayoga_paxI=karwari-uBayapaxI&upasarga=<prefix>
    //      &encoding=<enc>&outencoding=<enc>&mode=json
    // Note: prayoga_paxI is always sent as 'karwari-uBayapaxI' (both padi);
    // atmanepadi/parasmaipadi selection is a display-only filter in the UI.
    ToolConfig(
      id: 'verb_generator',
      nameEn: 'Verb generator',
      nameSa: 'क्रियारूप-निष्पादिका',
      description: 'Shows inflectional forms of a given verb',
      category: ToolCategory.generation,
      outputType: ToolOutputType.table,
      apiEndpoint: 'verb_gen',
      params: [
        ToolParam(
          key: 'vb',
          label: 'Verbal Root (Dhātu)',
        ),
        ToolParam(
          key: 'upasarga',
          label: 'Prefix (Upasarga)',
          isRequired: false,
        ),
        ToolParam(
          key: 'encoding',
          label: 'Input Encoding',
          options: _inputEncodings,
        ),
        ToolParam(
          key: 'outencoding',
          label: 'Output Encoding',
          options: _outputEncodings,
        ),
      ],
    ),

    // ── Kṛt generator ───────────────────────────────────────────────────────
    // API: vb=<dhatu>&upasarga=<prefix>&encoding=<enc>&outencoding=<enc>&mode=json
    ToolConfig(
      id: 'krt_generator',
      nameEn: 'Kṛt generator',
      nameSa: 'कृदन्त-निष्पादिका',
      description: 'Generates krit forms from a given dhatu',
      category: ToolCategory.generation,
      outputType: ToolOutputType.table,
      apiEndpoint: 'krt_gen',
      params: [
        ToolParam(
          key: 'vb',
          label: 'Verbal Root (Dhātu)',
        ),
        ToolParam(
          key: 'upasarga',
          label: 'Prefix (Upasarga)',
          isRequired: false,
        ),
        ToolParam(
          key: 'encoding',
          label: 'Input Encoding',
          options: _inputEncodings,
        ),
        ToolParam(
          key: 'outencoding',
          label: 'Output Encoding',
          options: _outputEncodings,
        ),
      ],
    ),

    // ── Dhātupāṭhaḥ (webview) ───────────────────────────────────────────────
    ToolConfig(
      id: 'dhatupatha',
      nameEn: 'Dhātupāṭhaḥ',
      nameSa: 'धातुपाठः',
      description: 'Reference list of Paninian verbal roots',
      category: ToolCategory.reference,
      outputType: ToolOutputType.webview,
      webviewUrl: 'https://samsaadhanii-dhatupatha.netlify.app/',
      params: [],
    ),
  ];

  // Helper — get tools by category
  static List<ToolConfig> byCategory(ToolCategory category) =>
      tools.where((t) => t.category == category).toList();

  // Helper — find a tool by id
  static ToolConfig? findById(String id) =>
      tools.cast<ToolConfig?>().firstWhere(
            (t) => t?.id == id,
            orElse: () => null,
          );
}
