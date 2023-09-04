import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'Constants/constants.dart';

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
  static String sandhiSplitterAPI = "$scl/sandhi_splitter/sandhi_splitter.cgi?";
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
    print('transLiterateWord url$url');
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
    var url =
        '${ashtadhyayi_simulator}encoding=$encoding&praatipadika=$inputWrod&vibhakti=$vibhakti&linga=$linga&vacana=$vacana';
    print(url);
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
    print(url);
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
    var url =
        '${sandhiAPI}word1=$input1&word2=$input2&encoding=$inEncoding&outencoding=$outEncoding';
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
    var url =
        '${sandhiSplitterAPI}word=$input1&encoding=$inEncoding&outencoding=$outEncoding&mode=$textType&disp_mode=json';
    // print('Sandhi splitter req: $url');
    Map responseData = <String, dynamic>{};

    try {
      http.Response resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        responseData = json.decode(utf8.decode(resp.bodyBytes));
        // if (kDebugMode) print(responseData);
      }
    } catch (e) {}
    return responseData;
  }

  static Future<List> verbRequest({
    String input1 = 'gam1_gamLz_BvAxiH_gawO',
    String input2 = 'karwari-parasmEpaxI',
    String input3 = '-',
    String inEncoding = 'WX',
    String outEncoding = 'Unicode',
  }) async {
    var url =
        '${verb_genAPI}vb=$input1&prayoga_paxI=$input2&upasarga=$input3&encoding=$inEncoding&outencoding=$outEncoding&mode=json';
    print('verb req: $url');
    List<dynamic> responseData = [];

    try {
      http.Response resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        // responseData = json.decode(utf8.decode(resp.bodyBytes));
        responseData = json.decode(resp.body);
        print(resp.body);
        // if (kDebugMode) print(responseData);
      }
    } catch (e) {}
    return responseData;
  }
}
