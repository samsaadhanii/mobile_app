import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WebAPI with ChangeNotifier {
  static String base = "http://scl.samsaadhanii.in";
  static String CGI_BIN = "$base/cgi-bin";
  static String scl = "$CGI_BIN/scl";

  // noun generator
  static String noun_gen = "$scl/skt_gen/noun/noun_gen_json.cgi?";
  static String transliterator =
      "http://45.9.190.177/transliteration/trans.php?src=Devanagari&tar=WX";

  static String transliterator2 =
      "http://45.9.190.177/transliteration/trans.php?src=WX&tar=IAST";

  // static Future<http.Response> nounGenRequest() async {
  //   var url = '$noun_gen rt=vana&gen=puM&jAwi=nA&level=1';
  //   http.Response response = await http.get(Uri.parse(url));
  //   // _responseBody = jsonDecode(responseBody);
  //   // print(_responseBody);
  //   return response;
  // }

  static Future<List> nounGenRequest(
      {String inputString = '',
      String gender = 'puM',
      String category = 'nA'}) async {
    var url = '${noun_gen}rt=$inputString&gen=$gender&jAwi=$category&level=1';
    http.Response resp = await http.get(Uri.parse(url));
    List<dynamic> responseData = [];
    if (resp.statusCode == 200) {
      responseData = json.decode(utf8.decode(resp.bodyBytes));
      if (kDebugMode) print(responseData);
    }
    return responseData;
  }

  static Future<String> transLiterate({required String input}) async {
    var body = jsonEncode({'text': input});
    http.Response resp = await http.post(Uri.parse(transliterator), body: body);
    String outputStr = '';
    if (resp.statusCode == 200) {
      final responseData = json.decode(resp.body);
      // if (kDebugMode) print('output: $responseData');
      outputStr = responseData['text'];

      /// TODO:- check for empty string and post a snackBar message
    }
    return outputStr;
  }

  static Future<List<dynamic>> transLiterateData({required var body}) async {
    // var body = jsonEncode({'text': input});
    http.Response resp =
        await http.post(Uri.parse(transliterator2), body: jsonEncode(body));
    List<dynamic> outputList = [];
    if (resp.statusCode == 200) {
      final responseData = json.decode(resp.body);
      if (kDebugMode) print('output: $responseData');
      outputList = responseData;

      /// TODO:- check for empty string and post a snackBar message
    }
    return outputList;
  }
}
