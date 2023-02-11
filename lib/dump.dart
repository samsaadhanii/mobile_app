//
// Future<List> makeRequest(
//     {String inputString = '',
//     String gender = 'puM',
//     String category = 'nA'}) async {
//   var url = WebAPI.noun_gen;
//   // 'http://scl.samsaadhanii.in/cgi-bin/scl/skt_gen/noun/noun_gen_json.cgi?rt=vana&gen=puM&jAwi=nA&level=1';
//   // print('hardcoded: $url');
//   // print(inputController.text);
//   url += 'rt=$inputString&gen=$gender&jAwi=$category&level=1';
//   // print('formed: ${WebAPI.noun_gen}');
//   // var httpClient = HttpClient();
//   // var request = await httpClient.getUrl(Uri.parse(url));
//   // var response = await request.close();
//   // var responseBody = await response.transform(utf8.decoder).join();
//   // _responseBody = jsonDecode(responseBody);
//   // if (kDebugMode) print(_responseBody);
//
//   http.Response resp = await http.get(Uri.parse(url));
//   List<dynamic> responseData = [];
//   if (resp.statusCode == 200) {
//     responseData = json.decode(utf8.decode(resp.bodyBytes));
//     if (kDebugMode) print(responseData);
//   }
//   return responseData;
// }
