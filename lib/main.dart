import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter JavaScript Bridge',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter JavaScript Bridge Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildBody(context),
        floatingActionButton: Wrap(
            //will break to another line on overflow
            direction: Axis.horizontal, //use vertical to show  on vertical axis
            children: <Widget>[
              _fab(Icons.email,
                  "{ \"from\" : \"Flutter\", \"data\" : \"Email\" }"),
              _fab(Icons.phone,
                  "{ \"from\" : \"Flutter\", \"data\" : \"Phone\" }"),
              _fab(Icons.person,
                  "{ \"from\" : \"Flutter\", \"data\" : \"Profile\" }")
            ]));
  }

  Widget _fab(
      [IconData? icon = Icons.plus_one,
      String message = "Hello from Flutter"]) {
    return Container(
        margin: const EdgeInsets.all(10),
        child: FloatingActionButton(
          child: Icon(icon),
          onPressed: () async {
            // _controller.runJavascript("sendFromFlutter('$message')");
            var result = await _controller.runJavascriptReturningResult("sendFromFlutter('$message')");
            debugPrint("result from web is $result");
          },
        ));
  }

  Widget _buildBody(BuildContext context) {
    return WebView(
      initialUrl: 'about:blank',
      javascriptMode: JavascriptMode.unrestricted,
      zoomEnabled: true,
      javascriptChannels: {
        JavascriptChannel(
            name: 'flutterMessageHandler',
            onMessageReceived: (JavascriptMessage message) {
              debugPrint("message : $message");
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(message.message)));
              // _controller.runJavascript('fromFlutter("Echo : $message")');
            })
      },
      onWebViewCreated: (WebViewController webviewController) {
        _controller = webviewController;
        _loadHtmlFromAssets();
      },
    );
  }

  _loadHtmlFromAssets() async {
    String file = await rootBundle.loadString('assets/index.html');
    _controller.loadUrl(Uri.dataFromString(file,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }
}
