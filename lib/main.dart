import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(MaterialApp(home: App()));
}

mixin WebViewOpener {
  void openWebView(BuildContext context, String url, {double heightFactor = 0.95}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => FractionallySizedBox(
        heightFactor: heightFactor,
        child: _WebViewModal(url: url),
      ),
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
    );
  }
}

class App extends StatelessWidget with WebViewOpener {
  @override
  Widget build(BuildContext context) {
    const url =
        "https://next2.colectivosvip.com/s5/1705/?sso_token=UtenteProva&sso_timestamp=1686650364953&sso_hash=646168e5c8daf216bc76d90206f443ed";

    return Scaffold(
      appBar: AppBar(title: const Text("Webbb")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Open!"),
          onPressed: () => openWebView(context, url),
        ),
      ),
    );
  }
}

class _WebViewModal extends StatefulWidget {
  final String url;

  _WebViewModal({super.key, required this.url});

  @override
  State<_WebViewModal> createState() => _WebViewModalState();
}

class _WebViewModalState extends State<_WebViewModal> with WebViewOpener {
  InAppWebViewSettings settings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
  );

  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          webViewController?.loadUrl(urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sono nel weeeeb"),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: settings,
        pullToRefreshController: pullToRefreshController,
        onWebViewCreated: (controller) {
          print("LOGGO: onWebViewCreated");

          webViewController = controller;
        },
        onLoadStart: (controller, url) {
          print("LOGGO: onLoadStart");
        },
        onPermissionRequest: (controller, request) async {
          print("LOGGO: onPermissionRequest");

//TODO grant solo se ho gli url che voglio io

          return PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          print("LOGGO: shouldOverrideUrlLoading");
          var uri = navigationAction.request.url!;

          if (uri.rawValue.contains('https://next2.colectivosvip.com/s5/1705/mobile/offer-details.action')) {
            openWebView(context, uri.rawValue, heightFactor: 0.9);
            return NavigationActionPolicy.CANCEL;
          }

          return NavigationActionPolicy.ALLOW;
        },
        onLoadStop: (controller, url) async {
          print("LOGGO: onLoadStop");
          pullToRefreshController?.endRefreshing();
        },
        onReceivedError: (controller, request, error) {
          print("LOGGO: onReceivedError");
          pullToRefreshController?.endRefreshing();
        },
        onProgressChanged: (controller, progress) {
          if (progress == 100) {
            pullToRefreshController?.endRefreshing();
          }
        },
        onUpdateVisitedHistory: (controller, url, androidIsReload) {
          print("LOGGO: onUpdateVisitedHistory");
        },
        onConsoleMessage: (controller, consoleMessage) {
          print("LOGGO: onConsoleMessage");
        },
      ),
    );
  }
}
