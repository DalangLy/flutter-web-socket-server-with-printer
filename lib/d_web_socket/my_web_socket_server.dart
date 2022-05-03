import 'dart:io';
import 'package:flutter/foundation.dart';

class MyWebSocketServer{
  late WebSocket _ws;
  MyWebSocketServer({required String currentIP, required Function(String data) onConnectedDevice, required Function(String ip) onDisconnected, required Function(dynamic data) onListener}){
    HttpServer.bind(currentIP, 8000).then((httpServer){
      httpServer.listen((httpRequest) {
        HttpConnectionInfo? httpConnectionInfo = httpRequest.connectionInfo;
        if(httpConnectionInfo != null){
          final String connectedIp = httpConnectionInfo.remoteAddress.host;
          onConnectedDevice(connectedIp);
        }

        WebSocketTransformer.upgrade(httpRequest).then((webSocket) {
          _ws = webSocket;
          webSocket.listen((data) {
            onListener(data);
          },
            onDone: (){
              if(httpConnectionInfo != null){
                final String disconnectedIp = httpConnectionInfo.remoteAddress.host;
                onDisconnected(disconnectedIp);
              }
            },
            cancelOnError: true,
          );
        },
          onError: (err){
            if (kDebugMode) {
              print('On WebSocket Listen Error $err');
            }
          },
        );

      },
        onError: (err){
          if (kDebugMode) {
            print('On Http Server Listen Error : $err');
          }
        },
        onDone: (){
          if (kDebugMode) {
            print('On Http Server Listen Done');
          }
        },
        cancelOnError: true,
      );
    },
      onError: (err){
        if (kDebugMode) {
          print('On Server Error $err');
        }
      },
    );
  }

  void sendData({required dynamic data,}){
    if (_ws.readyState == WebSocket.open) {
      _ws.add(data);
    }
  }
}