import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

bool isUnreachable(Object error) {
  return error is SocketException ||
      error is HttpException ||
      error is HandshakeException ||
      error is TimeoutException ||
      error is http.ClientException;
}
