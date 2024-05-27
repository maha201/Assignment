import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

final proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

print('Proxy server listening on ws://localhost:${proxyServer.port}');

await for (HttpRequest request in proxyServer) {
final uri = Uri.parse(request.uri.toString());
final targetUrl = Uri.parse('https://post-api-omega.vercel.app${uri.path}');

final targetRequest = http.Request(request.method, targetUrl);
targetRequest.headers.addAll(request.headers);

if (request.method == 'POST' || request.method == 'PUT') {
targetRequest.body = await request.transform(utf8.decoder).join();
}

final targetResponse = await http.Client().send(targetRequest);

targetResponse.headers.forEach((name, values) {
for (final value in values) {
request.response.headers.add(name, value);
}
});

request.response.statusCode = targetResponse.statusCode;

await targetResponse.stream.transform(utf8.decoder).pipe(request.response);
await request.response.close();
}