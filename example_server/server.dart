import 'dart:io' show HttpServer, HttpRequest, WebSocket, WebSocketTransformer;

import 'package:sync_layer/logger/index.dart';
import 'package:todo_app/sync/index.dart';

void main() async {
  final server = await HttpServer.bind('0.0.0.0', 8000);

  print('listen to 0.0.0.0:8000');

  final dao = SyncWrapper(0);

  server.listen((HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((WebSocket ws) {
      dao.protocol.registerConnection(ws);
    }, onError: (err) => logger.error('[!]Error -- ${err.toString()}'));
  }, onError: (err) => logger.error('[!]Error -- ${err.toString()}'));
}
