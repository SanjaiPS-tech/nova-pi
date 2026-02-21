import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({super.key, required this.url, required this.title});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_webViewController != null) {
                _webViewController!.reload();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              isInspectable: kDebugMode,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              iframeAllow: "camera; microphone",
              iframeAllowFullscreen: true,
              useOnDownloadStart: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onDownloadStartRequest: (controller, downloadStartRequest) async {
              debugPrint("Download started: ${downloadStartRequest.url}");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Download started: ${downloadStartRequest.suggestedFilename ?? "file"}',
                  ),
                  action: SnackBarAction(label: 'Close', onPressed: () {}),
                ),
              );
              // Note: For a production app, we would use a downloader package here.
              // For now, we notify the user.
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              // Automatically accept self-signed certificates
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },
            onReceivedHttpError: (controller, request, errorResponse) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('HTTP Error: ${errorResponse.statusCode}'),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Reload',
                    onPressed: () => controller.reload(),
                    textColor: Colors.white,
                  ),
                ),
              );
            },
            onReceivedError: (controller, request, error) {
              setState(() {
                _isLoading = false;
              });
              // Show error dialog or banner

              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Page Load Error'),
                  content: Text(error.description),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.reload();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isLoading || _progress < 1.0)
            LinearProgressIndicator(value: _progress),
        ],
      ),
    );
  }

  // Helper to properly check debug mode if kDebugMode isn't available
  // But usually foundation is imported in material.
  // Let's add it explicitly if needed.
  static const bool kDebugMode = true;
}
