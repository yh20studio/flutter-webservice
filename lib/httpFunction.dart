import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'class.dart';
import 'setting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

Future getJWT() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getString('accessToken')!;
}

Future<String> authenticationUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  DateTime now = DateTime.now();
  if (prefs.getInt('refreshTokenExpiresIn') == null) {
    return 'fail';
  } else {
    DateTime refreshTokenExpiresIn = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('refreshTokenExpiresIn')!);
    if (refreshTokenExpiresIn.isAfter(now)) {
      try {
        var httpPostReissue = await postReissue(
            prefs.getString('grantType'),
            prefs.getString('accessToken'),
            prefs.getInt('accessTokenExpiresIn'),
            prefs.getString('refreshToken'));

        prefs.setString('grantType', jsonDecode(httpPostReissue)['grantType']);
        prefs.setString(
            'accessToken', jsonDecode(httpPostReissue)['accessToken']);
        prefs.setInt('accessTokenExpiresIn',
            jsonDecode(httpPostReissue)['accessTokenExpiresIn']);
        prefs.setString(
            'refreshToken', jsonDecode(httpPostReissue)['refreshToken']);
        prefs.setInt('refreshTokenExpiresIn',
            jsonDecode(httpPostReissue)['refreshTokenExpiresIn']);

        return 'success';
      } catch (e) {
        print(e);
        return 'fail';
      }
    } else {
      return 'fail';
    }
  }
}
//GET METHOD

Future<List<Archives>> getArchives() async {
  String jwt = await getJWT();
  http.Response response = await http.get(
    Uri.parse(serverIP + 'archives'),
    headers: {
      HttpHeaders.authorizationHeader: "Bearer $jwt",
      HttpHeaders.contentTypeHeader: "application/json; charset=UTF-8"
    },
  );
  if (response.statusCode == 200) {
    return compute(parseArchives, response.body);
  } else {
    throw Exception("error: status code ${response.statusCode}");
  }
}

Future<Member> getMyInfo() async {
  String jwt = await getJWT();
  http.Response response = await http.get(
    Uri.parse(serverIP + 'user/info'),
    headers: {
      HttpHeaders.authorizationHeader: "Bearer $jwt",
      HttpHeaders.contentTypeHeader: "application/json; charset=UTF-8"
    },
  );
  if (response.statusCode == 200) {
    return compute(parseMember, response.body);
  } else {
    throw Exception("error: status code ${response.statusCode}");
  }
}

List<Archives> parseArchives(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Archives>((json) => Archives.fromJson(json)).toList();
}

Archives parseArchive(String responseBody) {
  final parsed = jsonDecode(responseBody);
  return Archives.fromJson(parsed);
}

Member parseMember(String responseBody) {
  final parsed = jsonDecode(responseBody);
  return Member.fromJson(parsed);
}

//POST METHOD

Future postArchives(Archives archives) async {
  String jwt = await getJWT();
  http.Response response = await http.post(
    Uri.parse(serverIP + 'archives'),
    headers: {
      HttpHeaders.authorizationHeader: "Bearer $jwt",
      HttpHeaders.contentTypeHeader: "application/json; charset=UTF-8",
      HttpHeaders.acceptHeader: "application/json; charset=UTF-8"
    },
    body: jsonEncode(
      {
        "title": archives.title,
        "content": archives.content,
        "url": archives.url
      },
    ),
  );
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception("error: status code ${response.statusCode}");
  }
}

Future postSignUp(String email, String password, String name) async {
  http.Response response = await http.post(
    Uri.parse(serverIP + 'auth/signup'),
    headers: {
      HttpHeaders.contentTypeHeader: "application/json; charset=UTF-8",
      HttpHeaders.acceptHeader: "application/json; charset=UTF-8"
    },
    body: jsonEncode(
      {"email": email, "password": password, "name": name},
    ),
  );
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception("error: status code ${response.statusCode}");
  }
}

Future postLogin(String email, String password) async {
  http.Response response = await http.post(
    Uri.parse(serverIP + 'auth/login'),
    headers: {
      HttpHeaders.contentTypeHeader: "application/json; charset=UTF-8",
      HttpHeaders.acceptHeader: "application/json; charset=UTF-8"
    },
    body: jsonEncode(
      {"email": email, "password": password},
    ),
  );
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception(jsonDecode(response.body)["message"]);
  }
}

Future postLogout(String? grantType, String? accessToken,
    int? accessTokenExpiresIn, String? refreshToken) async {
  String jwt = await getJWT();
  http.Response response = await http.post(
    Uri.parse(serverIP + 'auth/logout'),
    headers: {
      HttpHeaders.authorizationHeader: "Bearer $jwt",
      HttpHeaders.contentTypeHeader: "application/json; charset=UTF-8",
      HttpHeaders.acceptHeader: "application/json; charset=UTF-8"
    },
    body: jsonEncode(
      {
        "grantType": grantType,
        "accessToken": accessToken,
        "accessTokenExpiresIn": accessTokenExpiresIn,
        "refreshToken": refreshToken,
      },
    ),
  );
  if (response.statusCode == 200) {
    return response;
  } else {
    throw Exception("error: status code ${response.statusCode}");
  }
}

Future postReissue(String? grantType, String? accessToken,
    int? accessTokenExpiresIn, String? refreshToken) async {
  http.Response response = await http.post(
    Uri.parse(serverIP + 'auth/reissue'),
    headers: {
      HttpHeaders.contentTypeHeader: "application/json; charset=UTF-8",
      HttpHeaders.acceptHeader: "application/json; charset=UTF-8"
    },
    body: jsonEncode(
      {
        "grantType": grantType,
        "accessToken": accessToken,
        "accessTokenExpiresIn": accessTokenExpiresIn,
        "refreshToken": refreshToken,
      },
    ),
  );
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception("error: status code ${response.statusCode}");
  }
}

//Delete

Future<String> deleteArchives(Archives archives) async {
  String jwt = await getJWT();
  final url = Uri.parse(serverIP + 'archives/${archives.id}');
  final request = http.Request("DELETE", url);
  request.headers.addAll(<String, String>{
    HttpHeaders.authorizationHeader: "Bearer $jwt",
    HttpHeaders.contentTypeHeader: "application/json; charset=UTF-8",
  });

  final response = await request.send();
  if (response.statusCode == 200) {
    return await response.stream.bytesToString();
  } else {
    throw Exception("error: status code ${response.statusCode}");
  }
}

//PUT

Future<Archives> updateArchives(Archives archives) async {
  String jwt = await getJWT();
  http.Response response = await http.put(
    Uri.parse(serverIP + 'archives/${archives.id}'),
    headers: {
      HttpHeaders.authorizationHeader: "Bearer $jwt",
      HttpHeaders.contentTypeHeader: "application/json; charset=UTF-8",
    },
    body: jsonEncode({
      "title": archives.title,
      "content": archives.content,
      "url": archives.url,
    }),
  );
  if (response.statusCode == 200) {
    return compute(parseArchive, response.body);
  } else {
    throw Exception("error: status code ${response.statusCode}");
  }
}
