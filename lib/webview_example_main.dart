// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MaterialApp(home: WebViewExample()));

const String kNavigationExamplePage = '''
<!DOCTYPE html><html>
<head><title>Navigation Delegate Example</title></head>
<body>
<p>
The navigation delegate is set to block navigation to the youtube website.
</p>
<ul>
<ul><a href="https://www.youtube.com/">https://www.youtube.com/</a></ul>
<ul><a href="https://www.google.com/">https://www.google.com/</a></ul>
</ul>
</body>
</html>
''';

const String kLocalExamplePage = '''
<!DOCTYPE html>
<html lang="en">
<head>
<title>Load file or HTML string example</title>
</head>
<body>

<h1>Local demo page</h1>
<p>
  This is an example page used to demonstrate how to load a local file or HTML 
  string using the <a href="https://pub.dev/packages/webview_flutter">Flutter 
  webview</a> plugin.
</p>

</body>
</html>
''';

const String kTransparentBackgroundPage = '''
  <!DOCTYPE html>
  <html>
  <head>
    <title>Transparent background test</title>
  </head>
  <style type="text/css">
    body { background: transparent; margin: 0; padding: 0; }
    #container { position: relative; margin: 0; padding: 0; width: 100vw; height: 100vh; }
    #shape { background: red; width: 200px; height: 200px; margin: 0; padding: 0; position: absolute; top: calc(50% - 100px); left: calc(50% - 100px); }
    p { text-align: center; }
  </style>
  <body>
    <div id="container">
      <p>Transparent background test</p>
      <div id="shape"></div>
    </div>
  </body>
  </html>
''';

class WebViewExample extends StatefulWidget {
  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: const Text('Flutter WebView example'),
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        actions: <Widget>[
          NavigationControls(_controller.future),
          SampleMenu(_controller.future),
        ],
      ),
      // We're using a Builder here so we have a context that is below the Scaffold
      // to allow calling Scaffold.of(context) so we can show a snackbar.
      body: Builder(builder: (BuildContext context) {
        return WebView(
          initialUrl: 'https://afc-dev.appvantage.co/POR/SG/login',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
          onProgress: (int progress) {
            print('WebView is loading (progress : $progress%)');
          },
          javascriptChannels: <JavascriptChannel>{
            _toasterJavascriptChannel(context),
          },
          navigationDelegate: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              print('blocking navigation to $request}');
              return NavigationDecision.prevent;
            }
            print('allowing navigation to $request');
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            
            
          },
          gestureNavigationEnabled: true,
          backgroundColor: const Color(0x00000000),
        );
      }),
      floatingActionButton: favoriteButton(),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          debugPrint("_toasterJavascriptChannel, message : ${message.message}");
          // ignore: deprecated_member_use
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  Widget favoriteButton() {
    return FutureBuilder<WebViewController>(
        future: _controller.future,
        builder: (BuildContext context,
            AsyncSnapshot<WebViewController> controller) {
          if (controller.hasData) {
            return FloatingActionButton(
              onPressed: () async {
                final String url = (await controller.data!.currentUrl())!;
                // ignore: deprecated_member_use
                Scaffold.of(context).showSnackBar(
                  SnackBar(content: Text('Favorited $url')),
                );
              },
              child: const Icon(Icons.favorite),
            );
          }
          return Container();
        });
  }
}

enum MenuOptions {
  showUserAgent,
  listCookies,
  clearCookies,
  addToCache,
  listCache,
  clearCache,
  navigationDelegate,
  doPostRequest,
  loadLocalFile,
  loadFlutterAsset,
  loadHtmlString,
  transparentBackground,
  setCookie,
}

class SampleMenu extends StatelessWidget {
  SampleMenu(this.controller);

  final Future<WebViewController> controller;
  final CookieManager cookieManager = CookieManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        return PopupMenuButton<MenuOptions>(
          key: const ValueKey<String>('ShowPopupMenu'),
          onSelected: (MenuOptions value) {
            switch (value) {
              case MenuOptions.showUserAgent:
                _onShowUserAgent(controller.data!, context);
                break;
              case MenuOptions.listCookies:
                _onListCookies(controller.data!, context);
                break;
              case MenuOptions.clearCookies:
                _onClearCookies(context);
                break;
              case MenuOptions.addToCache:
                _onAddToCache(controller.data!, context);
                break;
              case MenuOptions.listCache:
                _onListCache(controller.data!, context);
                break;
              case MenuOptions.clearCache:
                _onClearCache(controller.data!, context);
                break;
              case MenuOptions.navigationDelegate:
                _onNavigationDelegateExample(controller.data!, context);
                break;
              case MenuOptions.doPostRequest:
                _onDoPostRequest(controller.data!, context);
                break;
              case MenuOptions.loadLocalFile:
                _onLoadLocalFileExample(controller.data!, context);
                break;
              case MenuOptions.loadFlutterAsset:
                _onLoadFlutterAssetExample(controller.data!, context);
                break;
              case MenuOptions.loadHtmlString:
                _onLoadHtmlStringExample(controller.data!, context);
                break;
              case MenuOptions.transparentBackground:
                _onTransparentBackground(controller.data!, context);
                break;
              case MenuOptions.setCookie:
                _onSetCookie(controller.data!, context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.showUserAgent,
              child: const Text('Show user agent'),
              enabled: controller.hasData,
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCookies,
              child: Text('List cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCookies,
              child: Text('Clear cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.addToCache,
              child: Text('Add to cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCache,
              child: Text('List cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCache,
              child: Text('Clear cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.navigationDelegate,
              child: Text('Navigation Delegate example'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.doPostRequest,
              child: Text('Post Request'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.loadHtmlString,
              child: Text('Load HTML string'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.loadLocalFile,
              child: Text('Load local file'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.loadFlutterAsset,
              child: Text('Load Flutter Asset'),
            ),
            const PopupMenuItem<MenuOptions>(
              key: ValueKey<String>('ShowTransparentBackgroundExample'),
              value: MenuOptions.transparentBackground,
              child: Text('Transparent background example'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.setCookie,
              child: Text('Set cookie'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onShowUserAgent(
      WebViewController controller, BuildContext context) async {
    // Send a message with the user agent string to the Toaster JavaScript channel we registered
    // with the WebView.
    await controller.runJavascript(
        'Toaster.postMessage("User Agent: " + navigator.userAgent);');
  }

  Future<void> _onListCookies(
      WebViewController controller, BuildContext context) async {
    final String cookies =
        await controller.runJavascriptReturningResult('document.cookie');
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Cookies:'),
          _getCookieList(cookies),
        ],
      ),
    ));
  }

  Future<void> _onAddToCache(
      WebViewController controller, BuildContext context) async {
    await controller.runJavascript(
        'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Added a test entry to cache.'),
    ));
  }

  // Future<void> _onListCache(
  //     WebViewController controller, BuildContext context) async {
  //   await controller.runJavascript('caches.keys()'
  //       '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
  //       '.then((caches) => Toaster.postMessage(caches))');
  // }

  Future<void> _onListCache(
      WebViewController controller, BuildContext context) async {

        await controller.runJavascript('sessionStorage.setItem("context", JSON.stringify($contextValue))');
        
        await controller.runJavascript('sessionStorage.setItem("authorization", JSON.stringify({ "accessToken" : "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzZXNzaW9uSWQiOiI2MjAxMDQzZGE5NTgxZTAwMWIwMjIwNGYiLCJ1c2VySWQiOiI1ZjcxZTBmNzlmOGM2YjAwMWRhMmQzNDIiLCJjb21wYW55SWQiOiI1ZjdiZDNlNWEyOGJmODAwMWJmNTFkMDUiLCJjb3VudHJ5SWQiOiI1ZjdjMTQzZGEyOGJmODAwMWJmNTFkMTAiLCJ6b25lSWQiOiI1ZjdjMTQ3NmEyOGJmODAwMWJmNTFkMTEiLCJkZWFsZXJJZCI6bnVsbCwibG9naW5UeXBlIjoiQ0kiLCJpYXQiOjE2NDQyMzM3ODksImV4cCI6MTY0NDIzNzM4OX0.8BMtrtxazbz_2ynh5bv6Bz71tizNnqLixDcf4cWJdXI"}))');

        await controller.runJavascript(
        'Toaster.postMessage("Sessiong Storage (authorization): " + sessionStorage.getItem("authorization"));');
        
        await controller.loadUrl('https://afc-dev.appvantage.co/POR/SG/new');
  }
  
  Future<void> _onClearCache(
      WebViewController controller, BuildContext context) async {
    await controller.clearCache();
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Cache cleared.'),
    ));
  }

  Future<void> _onClearCookies(BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, they are gone!';
    if (!hadCookies) {
      message = 'There are no cookies.';
    }
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future<void> _onNavigationDelegateExample(
      WebViewController controller, BuildContext context) async {
    final String contentBase64 =
        base64Encode(const Utf8Encoder().convert(kNavigationExamplePage));
    await controller.loadUrl('data:text/html;base64,$contentBase64');
  }

  Future<void> _onSetCookie(
      WebViewController controller, BuildContext context) async {
    await CookieManager().setCookie(
      const WebViewCookie(
          name: 'foo', value: 'bar', domain: 'httpbin.org', path: '/anything'),
    );
    await controller.loadUrl('https://httpbin.org/anything');
  }

  Future<void> _onDoPostRequest(
      WebViewController controller, BuildContext context) async {
    final WebViewRequest request = WebViewRequest(
      uri: Uri.parse('https://httpbin.org/post'),
      method: WebViewRequestMethod.post,
      headers: <String, String>{'foo': 'bar', 'Content-Type': 'text/plain'},
      body: Uint8List.fromList('Test Body'.codeUnits),
    );
    await controller.loadRequest(request);
  }

  Future<void> _onLoadLocalFileExample(
      WebViewController controller, BuildContext context) async {
    final String pathToIndex = await _prepareLocalFile();

    await controller.loadFile(pathToIndex);
  }

  Future<void> _onLoadFlutterAssetExample(
      WebViewController controller, BuildContext context) async {
    await controller.loadFlutterAsset('assets/www/index.html');
  }

  Future<void> _onLoadHtmlStringExample(
      WebViewController controller, BuildContext context) async {
    await controller.loadHtmlString(kLocalExamplePage);
  }

  Future<void> _onTransparentBackground(
      WebViewController controller, BuildContext context) async {
    await controller.loadHtmlString(kTransparentBackgroundPage);
  }

  Widget _getCookieList(String cookies) {
    if (cookies == null || cookies == '""') {
      return Container();
    }
    final List<String> cookieList = cookies.split(';');
    final Iterable<Text> cookieWidgets =
        cookieList.map((String cookie) => Text(cookie));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: cookieWidgets.toList(),
    );
  }

  static Future<String> _prepareLocalFile() async {
    final String tmpDir = (await getTemporaryDirectory()).path;
    final File indexFile = File(
        <String>{tmpDir, 'www', 'index.html'}.join(Platform.pathSeparator));

    await indexFile.create(recursive: true);
    await indexFile.writeAsString(kLocalExamplePage);

    return indexFile.path;
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture)
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController? controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                      if (await controller!.canGoBack()) {
                        await controller.goBack();
                      } else {
                        // ignore: deprecated_member_use
                        Scaffold.of(context).showSnackBar(
                          const SnackBar(content: Text('No back history item')),
                        );
                        return;
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                      if (await controller!.canGoForward()) {
                        await controller.goForward();
                      } else {
                        // ignore: deprecated_member_use
                        Scaffold.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('No forward history item')),
                        );
                        return;
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: !webViewReady
                  ? null
                  : () {
                      controller!.reload();
                    },
            ),
          ],
        );
      },
    );
  }
}

const String contextValue = r"""
{"companyCode":"POR","countryCode":"SG","zoneCode":"SG","dealerId":"61766372a7b8b5001b2cc0a4","company":{"__typename":"Company","id":"5f7bd3e5a28bf8001bf51d05","code":"POR","name":"Porsche","description":"Porsche Financial Services\n\nWhy should you set limits on your dreams?\n\nStraightforward. Tailored. Personal. Based on this simple, yet clear premise, we have been providing our customers with individual solution to enable them to fulfill their sports car dream for over 30 years. ","copyright":"Porsche Services Singapore","color":"#D5001C","font":{"__typename":"Attachment","url":"https://afc-next.s3.amazonaws.com/company/font/5f7bd3e5a28bf8001bf51d05.ttf"},"logo":{"__typename":"Attachment","url":"https://afc-next.s3.amazonaws.com/company/logo/5f7bd3e5a28bf8001bf51d05.png"}},"user":{"id":"5f71e0f79f8c6b001da2d342","username":"apvadmin","name":"Appvantage Admin","email":"chenjun@appvantage.co","phonePrefix":"+262","phone":"","isSuperUser":true,"image":{"url":"https://afc-next.s3.amazonaws.com/user/profile/5f71e0f79f8c6b001da2d342.png","__typename":"Attachment"},"permissions":[],"availableCompanies":[{"id":"5f7bd3e5a28bf8001bf51d05","name":"Porsche","code":"POR","countries":[{"id":"5f7c143da28bf8001bf51d10","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":true,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":true,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":2000,"provider":{"type":"Porsche","__typename":"PorschePaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":"The calculation is based on the total price plus an estimated COE of <<COE>> SGD. The loan is arranged with Hong Leong Finance Ltd and subject to its approval, terms and conditions apply. Porsche Center Singapore","chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":true,"allowTradeIn":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":2500,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":false,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":4000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"priceDisclaimer":"","__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":true,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61766372a7b8b5001b2cc0a4","name":"Porsche Centre Singapore","identifier":"Porsche Centre Singapore","__typename":"AvailableDealerForAuthentication"},{"id":"617924bc4d06bc001bf82814","name":"Porsche Pre-owned Car Centre Singapore","identifier":"Porsche Pre-owned Car Centre Singapore","__typename":"AvailableDealerForAuthentication"},{"id":"61aec574b5f64a001bcc9178","name":"Porsche Dealer 3","identifier":"Porsche Dealer 3","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"5f7c1476a28bf8001bf51d11","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"},{"id":"5f856206153b19001e89f0d1","name":"Tuas Jurong","code":"TUA","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"5f8412ad3d2815001b592dea","name":"Australia","code":"AU","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b55168b","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"5f8412ad3d2815001b592deb","name":"New South Wales","code":"NSW","__typename":"AvailableZoneForAuthentication"},{"id":"5f8413b03d2815001b592dee","name":"Victoria","code":"VIC","__typename":"AvailableZoneForAuthentication"},{"id":"6020f9723b4e30001b90ef6c","name":"Perth","code":"PER","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"60892f107da739001bdd6e49","name":"China","code":"CN","channelSetting":{"new":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b551694","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"60892f107da739001bdd6e4a","name":"China","code":"CN","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"61026f5a458fb0001bc1a6b0","name":"Thailand","code":"TH","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516a6","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"61026f5a458fb0001bc1a6b1","name":"Thailand","code":"TH","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"6130830e471a79001b25b6e9","name":"Malaysia","code":"MY","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":"price disclaimer in POR/MY, placeholder <<COE>>","chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":"price disclaimer in POR/MY, placeholder <<COE>>","__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"6165373b4dd201001b37ab8e","name":"Porsche Centre Ara Damansara​","identifier":"Porsche Centre Ara Damansara​","__typename":"AvailableDealerForAuthentication"},{"id":"616537484dd201001b37ab93","name":"Porsche Centre Johor Bahru ​","identifier":"Porsche Centre Johor Bahru ​","__typename":"AvailableDealerForAuthentication"},{"id":"61762cb5a7b8b5001b2cc039","name":"Porsche Centre Sungai Besi","identifier":"Porsche Centre Sungai Besi","__typename":"AvailableDealerForAuthentication"},{"id":"61762ceaa7b8b5001b2cc03a","name":"Porsche Centre Penang","identifier":"Porsche Centre Penang","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6130830e471a79001b25b6ea","name":"Malaysia","code":"MY","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"615e732e93f573001b149419","name":"New Zealand","code":"NZ","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":true,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":"The calculation is based on the total price plus PPSR of <<ppsr>> NZD and Establishment of <<establishment>> NZD. ","chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":false,"allowTradeIn":true,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":true,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":"The calculation is based on the total price plus PPSR of <<ppsr>> NZD and Establishment of <<establishment>> NZD. ","__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516ac","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"615e732e93f573001b14941a","name":"New Zealand","code":"NZ","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"61728c41d26d8d001b2d58da","name":"United Arab Emirates","code":"AE","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"6194cc6413ad13001b6c2cb2","name":"Appvantage Admin","identifier":"Appvantage Admin","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"61728c41d26d8d001b2d58db","name":"United Arab Emirates","code":"AE","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"61764ee4a7b8b5001b2cc09f","name":"Afghanistan","code":"AF","channelSetting":{"new":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516a7","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"61764ee4a7b8b5001b2cc0a0","name":"Afghanistan","code":"AF","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"6194e61513ad13001b6c2ccd","name":"Myanmar","code":"MM","channelSetting":{"new":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516b2","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6194e61513ad13001b6c2cce","name":"Myanmar","code":"MM","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"619672aa98f701001b610380","name":"Saudi Arabia","code":"SA","channelSetting":{"new":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516b0","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"619672aa98f701001b610381","name":"Saudi Arabia","code":"SA","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"5f91932e46bbfc001b496297","name":"BMW","code":"BMW","countries":[{"id":"6080da409434d2001bad2e35","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":"This is COE Disclaimer","chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":"This is COE Disclaimer","__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61a0fb3f60da20001b2f0627","name":"Sime Darby Performance Centre","identifier":"Sime Darby Performance Centre","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6080da409434d2001bad2e36","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"603a5147adc4ad001b2df6ba","name":"Volkswagen","code":"VW","countries":[{"id":"603a54e2adc4ad001b2df6bb","name":"Myanmar","code":"MM","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b55168e","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"603a54e2adc4ad001b2df6bc","name":"Yangon","code":"YGN","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"6172325dd26d8d001b2d5521","name":"United Arab Emirates","code":"AE","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":5000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516ae","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6172325dd26d8d001b2d5522","name":"United Arab Emirates","code":"AE","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"6041aaa60695ef001d652487","name":"Mercedes","code":"M","countries":[{"id":"6041c4600695ef001d6524c9","name":"United States of America","code":"US","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":false,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":false,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":false,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b551693","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6041c4600695ef001d6524ca","name":"Chicago","code":"Ch","__typename":"AvailableZoneForAuthentication"},{"id":"6041c4e80695ef001d6524ce","name":"New York","code":"NY","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"607fc072fd8a5c001b17c475","name":"Audi","code":"AD","countries":[{"id":"607fc0e4fd8a5c001b17c47a","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":"This is COE Disclaimer","chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":"This is COE Disclaimer","__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b551690","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"607fc0e4fd8a5c001b17c47b","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"609b8f07765c3b001be77165","name":"Malaysia","code":"MY","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b55169c","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"609b8f07765c3b001be77166","name":"Malaysia","code":"MY","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"609108906b614a001b780e38","name":"Skoda","code":"SKO","countries":[{"id":"6093943ee98f0e001c11377d","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":2000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b551697","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6093943ee98f0e001c11377e","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"60924fc0c50683001b1759dd","name":"Urban Motors","code":"UM","countries":[{"id":"609253bec50683001b1759e2","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b551695","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"609253bec50683001b1759e3","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"6092c43c6930d5001b98bbe4","name":"Tesla","code":"TSLA","countries":[{"id":"6092c5056930d5001b98bbe7","name":"United States of America","code":"US","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b551696","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6092c5056930d5001b98bbe8","name":"Usa","code":"US","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"609398dce98f0e001c113786","name":"Aston Martin","code":"AM","countries":[{"id":"60939a1de98f0e001c11378c","name":"United Kingdom","code":"GB","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":2000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"612deaf59df4f6001b508200","name":"ABC ","identifier":"ABC ","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"60939a1de98f0e001c11378d","name":"United Kingdom","code":"UK","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"6098a5c41922cd001b53cee8","name":"Honda","code":"HND","countries":[{"id":"6098a6841922cd001b53ceeb","name":"United States of America","code":"US","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":1000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":true,"allowTradeIn":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b55169a","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6098a6841922cd001b53ceec","name":"Usa","code":"US","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"61889fcdc1fa69001c5a051d","name":"Ghana","code":"GH","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":true,"allowTradeIn":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"6188adbfc1fa69001c5a0574","name":"Dealer 01","identifier":"Dealer 01","__typename":"AvailableDealerForAuthentication"},{"id":"6188d3aa29d5d8001ba1bc53","name":"Dealer 001","identifier":"Dealer 001","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"61889fcdc1fa69001c5a051e","name":"Ghana","code":"GH","__typename":"AvailableZoneForAuthentication"},{"id":"6188a3a6c1fa69001c5a0533","name":"Kumasi","code":"KMA","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"60af936ee83f31001bbe8e5c","name":"Appvantage","code":"APV","countries":[{"id":"60af93b0e83f31001bbe8e5f","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":1000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":"COE Disclaimer","chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":1000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":"COE Disclaimer","__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b551699","name":"Dealer A","identifier":"Dealer A","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"60af93b0e83f31001bbe8e60","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"60b5e6db14c875001be83206","name":"Daimler","code":"DA","countries":[{"id":"60b70d1731751a001b9a9a0b","name":"United States of America","code":"US","channelSetting":{"new":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516a0","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"60b70d1731751a001b9a9a0c","name":"United States of America","code":"US","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"60b7362731751a001b9a9a23","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":1500,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":false,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":"This is COE Disclaimer.","chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":true,"allowTradeIn":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":1000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":false,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":1000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":false,"allowProceedWithCustomerDevice":true,"priceDisclaimer":"This is COE Disclaimer.","__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516a1","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"60b7362731751a001b9a9a24","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"60b7511d31751a001b9a9a50","name":"China","code":"CN","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":true,"allowTradeIn":true,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516a3","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"60b7511d31751a001b9a9a51","name":"China","code":"CN","__typename":"AvailableZoneForAuthentication"},{"id":"60e5205f0fd8c1001b72f96b","name":"China","code":"CN","__typename":"AvailableZoneForAuthentication"},{"id":"60e520920fd8c1001b72f96c","name":"Hong Kong","code":"HK","__typename":"AvailableZoneForAuthentication"},{"id":"60e520b00fd8c1001b72f96d","name":"Macau","code":"MO","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"60f8d9e9b3ae17001bf30da6","name":"PFS","code":"PFS","countries":[{"id":"60f8da95b3ae17001bf30daa","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516a5","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"60f8da95b3ae17001bf30dab","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"6102d9e8458fb0001bc1a89f","name":"Tai Huat Credit","code":"THC","countries":[{"id":"6102da63458fb0001bc1a8a3","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516a8","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6102da63458fb0001bc1a8a4","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"61081045f223e0001bac2b62","name":"Hyundai","code":"HYD","countries":[{"id":"6108116af223e0001bac2b66","name":"Korea South","code":"KR","channelSetting":{"new":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516a4","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6108116af223e0001bac2b67","name":"Korea South","code":"KR","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"61082082f223e0001bac2b74","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":"The calculation is based on the total price plus estimated COE of 20000 SGD. Loan can be arranged with DBS LTD and subject to its approval, terms and condition apply.","chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":true,"allowTradeIn":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":"The calculation is based on the total price plus estimated COE of 20000 SGD. Loan can be arranged with DBS LTD and subject to its approval, terms and condition apply.","__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516aa","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"61082082f223e0001bac2b75","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"611beec00f1a66001bc89db1","name":"Toyota","code":"TY","countries":[{"id":"611cc3d3ada099001b2a4ff2","name":"India","code":"IN","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516ab","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"611cc3d3ada099001b2a4ff3","name":"India","code":"IN","__typename":"AvailableZoneForAuthentication"},{"id":"611dc4c5ada099001b2a50f1","name":"North Central Railway","code":"NCR","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"6188d2b429d5d8001ba1bc4d","name":"Lamborghini","code":"LBG","countries":[{"id":"6188d31a29d5d8001ba1bc4f","name":"Ghana","code":"GH","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":true,"allowTradeIn":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"6188d40329d5d8001ba1bc55","name":"Dealer 001","identifier":"Dealer 001","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6188d31a29d5d8001ba1bc50","name":"Ghana","code":"GH","__typename":"AvailableZoneForAuthentication"},{"id":"6188d50a29d5d8001ba1bc58","name":"Kumasi","code":"KMA","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"6189e82bb4c40c001b5427d0","name":"Sisi for Training ","code":"SI","countries":[{"id":"6189eb6ab4c40c001b5427e8","name":"Thailand","code":"TH","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":100000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":10000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":false,"allowProceedWithCustomerDevice":true,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61a5cf2960da20001b2f09c7","name":"Test AE21-68","identifier":"Test AE21-68","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"6189eb6ab4c40c001b5427e9","name":"Thailand","code":"TH","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"61a5ccb260da20001b2f09c2","name":"SISI1","code":"SISI1","countries":[{"id":"61a5e4c060da20001b2f09e1","name":"Thailand","code":"TH","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61ae38b074bacc001b5516b1","name":"Default","identifier":"Default","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"61a5e4c060da20001b2f09e2","name":"Thailand","code":"TH","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"61f21595d824d9001b1c7131","name":"RAJ CARS","code":"RAJ CARS","countries":[{"id":"61f2194ad824d9001b1c7136","name":"India","code":"IN","channelSetting":{"new":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":true,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":50000,"provider":{"type":"Porsche","__typename":"PorschePaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":true,"allowReverseCalculator":true,"allowTestDrive":true,"allowTradeIn":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":true,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":10000,"provider":{"type":"Porsche","__typename":"PorschePaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":50000,"provider":{"type":"Porsche","__typename":"PorschePaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":true,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61f2194ad824d9001b1c7138","name":"RAJ CARS India","identifier":"RAJ CARS India","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"61f2194ad824d9001b1c7137","name":"India","code":"IN","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"},{"id":"61f3647c772114001b940717","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"allowOptions":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":false,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":false,"isDepositPaymentMandatory":false,"alwaysShowPromoCode":false,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61f3647c772114001b940719","name":"RAJ CARS Singapore","identifier":"RAJ CARS Singapore","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"61f3647c772114001b940718","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"},{"id":"61f8c6d55ffb3a001be86509","name":"Raja Test","code":"Raja Test","countries":[{"id":"61f8c7325ffb3a001be8650a","name":"Singapore","code":"SG","channelSetting":{"new":{"isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":2000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":null,"chatbot":null,"__typename":"NewChannel"},"used":{"isActive":false,"allowReverseCalculator":false,"allowTestDrive":false,"allowTradeIn":false,"isPromoCodeEnabled":false,"alwaysShowPromoCode":false,"allowSharing":false,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":false,"bookingPayment":null,"allowFinanceApplication":false,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":false,"isChatbotEnabled":false,"chatbot":null,"__typename":"UsedChannel"},"express":{"isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":true,"bookingPayment":{"amount":4000,"provider":{"type":"Adyen","__typename":"AdyenPaymentProvider"},"__typename":"BookingPayment"},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"priceDisclaimer":null,"__typename":"ExpressChannel"},"event":{"isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":true,"__typename":"EventChannel"},"__typename":"ChannelSetting"},"dealers":[{"id":"61f8c7325ffb3a001be8650c","name":"Raja Test Singapore","identifier":"Raja Test Singapore","__typename":"AvailableDealerForAuthentication"}],"zones":[{"id":"61f8c7325ffb3a001be8650b","name":"Singapore","code":"SG","__typename":"AvailableZoneForAuthentication"}],"__typename":"AvailableCountriesForAuthentication"}],"__typename":"AvailableCompanyForAuthentication"}],"version":{"updatedAt":"2022-01-19T10:51:13.612Z","updatedBy":null,"__typename":"SimpleVersion"},"__typename":"User"},"country":{"__typename":"Country","id":"5f7c143da28bf8001bf51d10","code":"SG","name":"Singapore","currency":"SGD","matchExistingCustomer":true,"languages":["en","zh","th"],"sendCustomerConfirmationEmail":true,"mask":{"__typename":"Mask","direction":"NONE","count":0},"rounding":{"__typename":"Rounding","amount":{"__typename":"RoundingDetail","count":0},"percentage":{"__typename":"RoundingDetail","count":0}},"googleTagManager":{"__typename":"GoogleTagManager","id":""},"phoneSettings":{"__typename":"CountryPhoneAppOption","pattern":"^([\\+]?65[- ]?)?[89][0-9]{7}$","minDigits":8,"maxDigits":8,"code":65},"maintenance":{"__typename":"Maintenance","start":"2021-12-14T10:30:00.000Z","end":"2021-12-14T10:30:00.000Z","warningBefore":86400,"title":"MAINTENANCE IN PROGRESS","description":"THE PAGE IS UNDER MAINTENANCE FOR JR ZONE ONLY.\nPLEASE CHECK LATER.test","isActive":false,"startTimeZone":"Asia/Singapore","endTimeZone":"Asia/Singapore","image":{"__typename":"Attachment","url":"https://afc-next.s3.amazonaws.com/country/maintenance/5f7c143da28bf8001bf51d10.png"}},"coe":{"__typename":"Coe","amount":10000,"editable":true},"ppsr":{"__typename":"Ppsr","amount":0,"editable":false},"establishment":{"__typename":"Establishment","amount":0,"editable":false},"channelSetting":{"__typename":"ChannelSetting","new":{"__typename":"NewChannel","isActive":true,"isCoeEnabled":true,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"allowOptions":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":true,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":true,"isDepositPaymentMandatory":true,"bookingPayment":{"__typename":"BookingPayment","amount":2000,"provider":{"__typename":"PorschePaymentProvider","type":"Porsche"}},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":false,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"priceDisclaimer":"The calculation is based on the total price plus an estimated COE of <<COE>> SGD. The loan is arranged with Hong Leong Finance Ltd and subject to its approval, terms and conditions apply. Porsche Center Singapore","chatbot":null},"used":{"__typename":"UsedChannel","isActive":true,"allowReverseCalculator":true,"allowTestDrive":true,"allowTradeIn":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"allowSharing":true,"allowPrivateAccess":true,"allowPublicAccess":false,"isDepositPaymentMandatory":true,"bookingPayment":{"__typename":"BookingPayment","amount":2500,"provider":{"__typename":"AdyenPaymentProvider","type":"Adyen"}},"allowFinanceApplication":true,"isFinanceApplicationMandatory":false,"allowProceedWithCustomerDevice":true,"filterByMonthlyInstalment":true,"isChatbotEnabled":false,"chatbot":null},"express":{"__typename":"ExpressChannel","isActive":true,"isCoeEnabled":false,"isPpsrAndEstablishmentEnabled":false,"allowReverseCalculator":true,"isPromoCodeEnabled":true,"alwaysShowPromoCode":false,"isDepositPaymentMandatory":true,"bookingPayment":{"__typename":"BookingPayment","amount":4000,"provider":{"__typename":"AdyenPaymentProvider","type":"Adyen"}},"allowFinanceApplication":true,"isFinanceApplicationMandatory":true,"allowProceedWithCustomerDevice":true,"priceDisclaimer":""},"event":{"__typename":"EventChannel","isActive":true,"isDepositPaymentMandatory":true,"alwaysShowPromoCode":true}},"sessionTimeout":5},"zone":{"__typename":"Zone","id":"5f7c1476a28bf8001bf51d11","code":"SG","name":"Singapore","hasConsents":true,"timezone":"Asia/Singapore","consentsAndDeclarations":[{"__typename":"ConsentOrDeclaration","id":"5fbf63a147308d001bc502e2","name":"C&D for Porsche Singapore","order":199,"hasCheckbox":true,"isMandatory":true,"description":"This is the C&D for Porsche Singapore","legalMarkup":null,"dataFieldName":"DataProcessing","owner":{"__typename":"ConsentOrDeclarationOwner","type":"Country"}}]}}""";