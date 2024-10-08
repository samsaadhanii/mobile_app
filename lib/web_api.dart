import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'Constants/constants.dart';

/// The WebAPI class is used to make API requests to the server
/// The server is hosted at the University of Hyderabad
/// The server is used to generate the following:
/// 1. Noun forms
/// 2. Verb forms
/// 3. Sandhi
/// 4. Sandhi Splitter
/// 5. Krt forms
/// 6. Morphological Analyser
/// 7. Dictionary
/// 8. Transliteration
/// 9. Ashtadhyayi Simulator
/// 10. Verb Generator
/// 11. Krt Generator
///
class WebAPI with ChangeNotifier {
  static String base = "https://scl.samsaadhanii.in";
  static String base1 = "https://sanskrit.uohyd.ac.in";
  static String CGI_BIN = "$base/cgi-bin";
  static String scl = "$CGI_BIN/scl";

  // noun generator
  static String noun_gen = "$scl/skt_gen/noun/noun_gen.cgi?";
  static String transliterator =
      "http://45.9.190.177/transliteration/trans.php";
  static String ashtadhyayi_simulator =
      "$scl/ashtadhyayi_simulator/simulation.cgi?";
  static String dictionary = "$scl/MT/dict_help_json.cgi?word=";
  static String sandhiAPI = "$scl/sandhi/sandhi_json.cgi?";
  static String sandhiSplitterAPI =
      "$scl/MT/prog/sandhi_splitter/sandhi_splitter.cgi?";
  static String verb_genAPI = "$scl/skt_gen/verb/verb_gen.cgi?";

  // static Future<http.Response> nounGenRequest() async {
  //   var url = '$noun_gen rt=vana&gen=puM&jAwi=nA&level=1';
  //   http.Response response = await http.get(Uri.parse(url));
  //   // _responseBody = jsonDecode(responseBody);
  //   // print(_responseBody);
  //   return response;
  // }

  static Future<List> nounGenRequest({
    String inputString = '',
    String gender = 'puM',
    String category = 'nA',
    String inEncoding = 'WX',
    String outEncoding = 'Unicode',
  }) async {
    var url =
        '${noun_gen}rt=$inputString&gen=$gender&jAwi=$category&level=1&mode=json&encoding=$inEncoding&outencoding=$outEncoding';
    print('noun gen req: $url');
    List<dynamic> responseData = [];

    try {
      http.Response resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        if (kDebugMode) print(responseData);
        responseData = json.decode(utf8.decode(resp.bodyBytes));
        // responseData = json.decode(resp.body);
      }
    } catch (e) {}
    return responseData;
  }

  static Future<String> transLiterateWord({
    required String input,
    String src = 'Devanagari',
    String tar = 'WX',
  }) async {
    var body = jsonEncode({'text': input});
    var url = '$transliterator?src=$src&tar=$tar';
    print('transLiterateWord url: $url');
    http.Response resp = await http.post(Uri.parse(url), body: body);
    String outputStr = '';
    if (resp.statusCode == 200) {
      final responseData = json.decode(resp.body);
      // if (kDebugMode) print('output: $responseData');
      outputStr = responseData['text'];

      /// TODO:- check for empty string and post a snackBar message
    }
    return outputStr;
  }

  static Future<List<dynamic>> transLiterateData({
    required var body,
    String src = 'WX',
    String tar = 'IAST',
  }) async {
    var url = '$transliterator?src=$src&tar=$tar';
    print('transLiterateData url: $url');
    http.Response resp =
        await http.post(Uri.parse(url), body: jsonEncode(body));
    List<dynamic> outputList = [];
    if (resp.statusCode == 200) {
      final responseData = json.decode(resp.body);
      if (kDebugMode) print('Transliterated data: $responseData');
      outputList = responseData;

      /// TODO:- check for empty string and post a snackBar message
    }
    return outputList;
  }

  static Future<String> simulation({
    required String inputWrod,
    String encoding = 'IAST',
    String vibhakti = 'praWamA',
    String linga = 'puM',
    String vacana = 'ekavacana',
  }) async {
    var url = '$ashtadhyayi_simulator'
        'encoding=$encoding'
        '&praatipadika=$inputWrod'
        '&vibhakti=$vibhakti'
        '&linga=$linga'
        '&vacana=$vacana';
    print('Ashtadhyayi simulator url: $url');
    String outputStr = '';

    try {
      http.Response resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final responseData = (utf8.decode(resp.bodyBytes));
        if (kDebugMode) print('Simulation data: $responseData');
        outputStr = responseData;

        /// TODO:- check for empty string and post a snackBar message
      }
    } catch (e) {}
    return outputStr;
  }

  static Future<String> getDictionary({required String inputWord}) async {
    var url = '$dictionary$inputWord';
    print('Dictionary url : $url');
    http.Response resp = await http.get(Uri.parse(url));
    String outputStr = '';
    if (resp.statusCode == 200) {
      final responseData = (utf8.decode(resp.bodyBytes));
      if (kDebugMode) print('Dictionary data: $responseData');
      outputStr = responseData;

      /// TODO:- check for empty string and post a snackBar message
    }
    return outputStr;
  }

  static Future<List> sandhiRequest({
    String input1 = '',
    String input2 = '',
    String inEncoding = 'WX',
    String outEncoding = 'Unicode',
  }) async {
    var url = '$sandhiAPI'
        'word1=$input1'
        '&word2=$input2'
        '&encoding=$inEncoding'
        '&outencoding=$outEncoding';
    print('Sandhi req: $url');
    List<dynamic> responseData = [];

    try {
      http.Response resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        responseData = json.decode(utf8.decode(resp.bodyBytes));
        // if (kDebugMode) print(responseData);
      }
    } catch (e) {}
    return responseData;
  }

  static Future<Map> sandhiSplitter({
    String input1 = '',
    String textType = Const.SENTENCE,
    String inEncoding = 'WX',
    String outEncoding = 'Unicode',
  }) async {
    var url = '$sandhiSplitterAPI'
        'word=$input1'
        '&encoding=$inEncoding'
        '&outencoding=$outEncoding'
        '&mode=$textType'
        '&disp_mode=json';
    print('Sandhi splitter req: $url');
    Map responseData = <String, dynamic>{};

    try {
      http.Response resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        print(utf8.decode(resp.bodyBytes));
        responseData = json.decode(utf8.decode(resp.bodyBytes));
        // if (kDebugMode) print(responseData);
      }
    } catch (e) {}
    return responseData;
  }

  static Future<List> verbRequest({
    String input1 = 'gam1_gamLz_BvAxiH_gawO',
    String input2 = 'karwari-uBayapaxI',
    String input3 = '-',
    String inEncoding = 'WX',
    String outEncoding = 'Devanagari',
  }) async {
    var url = '$verb_genAPI'
        'vb=$input1'
        '&prayoga_paxI=$input2'
        '&upasarga=$input3'
        '&encoding=$inEncoding'
        '&outencoding=$outEncoding'
        '&mode=json';
    List<dynamic> responseData = [];
    print('verb Request req: $url');
    try {
      http.Response resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        String withCTRLCharacter = utf8.decode(resp.bodyBytes);

        ///\n gives error when parsing json in flutter
        var withoutCTRLCharacter = withCTRLCharacter.replaceAll('\n', '\\n');
        responseData = json.decode(withoutCTRLCharacter);

        // if (kDebugMode) print(responseData);
      }
    } catch (e) {}
    return responseData;
  }

  ///***************************************************************************
  ///Krt Generator
  ///The API link for Krt generator is the following:
  /// #Usage:
  /// #https://sanskrit.uohyd.ac.in/cgi-bin/scl/skt_gen/kqw/kqw_gen.cgi?vb=gam1_gamLz_BvAxiH_gawO&upasarga=-&encoding=WX&outencoding=Devanagari&mode=json
  /// # the values of upasarga and vb are the same as those in the verb generator.
  /// ************************
  static Future<List> krtRequest({
    String input1 = 'rAmaH',
    String input3 = '-',
    String inEncoding = 'WX',
    String outEncoding = 'Devanagari',
  }) async {
    var url = '$scl/skt_gen/kqw/kqw_gen.cgi?'
        'vb=$input1'
        '&upasarga=$input3'
        '&encoding=$inEncoding'
        '&outencoding=$outEncoding'
        '&mode=json';
    print('Krt generator req: $url');
    List<dynamic> responseData = [];

    try {
      http.Response resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        String withCTRLCharacter = utf8.decode(resp.bodyBytes);

        ///\n gives error when parsing json in flutter
        var withoutCTRLCharacter = withCTRLCharacter.replaceAll('\n', '\\n');
        responseData = json.decode(withoutCTRLCharacter);

        if (kDebugMode) print(responseData);
      }
    } catch (e) {}
    return responseData;
  }

  ///*****
  /// Morphological Analyser
  /// The API link for morph analyser is here:
  /// #Usage:
  /// #https://sanskrit.uohyd.ac.in/cgi-bin/scl/morph/morph.cgi?morfword=rAmaH&encoding=WX&outencoding=DEV&mode=json
  ///
  /// #Outencoding: IAST/DEV
  /// ******************************************************************************
  static Future<List> morphAnalyser({
    String input1 = 'rAmaH',
    String inEncoding = 'WX',
    String outEncoding = 'Devanagari',
  }) async {
    var url = '$scl/MT/prog/morph/morph.cgi?'
        'morfword=$input1'
        '&encoding=$inEncoding'
        '&outencoding=$outEncoding'
        '&mode=json';
    print('Morph analyser req: $url');
    List<dynamic> responseData = [];

    try {
      http.Response resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        /// \n gives error when try to Json.decode a  List data into a Map in flutter
        responseData = json.decode(utf8.decode(resp.bodyBytes));
        if (kDebugMode) print(responseData);
      }
    } catch (e) {}
    return responseData;
  }
}
