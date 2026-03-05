import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

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

              // Register a JavaScript handler to receive focus events
              controller.addJavaScriptHandler(
                handlerName: 'onInputFocus',
                callback: (args) {
                  // Only show if we actually have credentials to show
                  final settings = Provider.of<SettingsService>(
                    context,
                    listen: false,
                  );
                  if (settings.credentials.isNotEmpty && mounted) {
                    _showCredentialsBottomSheet(context);
                  }
                },
              );
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) async {
              setState(() {
                _isLoading = false;
              });

              // Inject JavaScript to listen for focus events on input fields
              await controller.evaluateJavascript(
                source: """
                document.addEventListener('focusin', function(e) {
                  if (e.target && e.target.tagName === 'INPUT') {
                    var type = e.target.type.toLowerCase();
                    if (type === 'text' || type === 'password' || type === 'email' || type === 'search' || type === '') {
                       // Tell Flutter that an input was focused
                       window.flutter_inappwebview.callHandler('onInputFocus');
                    }
                  }
                });
              """,
              );
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
            onDownloadStartRequest: (controller, downloadStartRequest) async {
              final url = downloadStartRequest.url;
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not download from $url')),
                  );
                }
              }
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

  void _showCredentialsBottomSheet(BuildContext context) {
    final settings = Provider.of<SettingsService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Auto-fill with Credential',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: settings.credentials.length,
                  itemBuilder: (ctx, index) {
                    final cred = settings.credentials[index];
                    return ListTile(
                      leading: const Icon(Icons.security),
                      title: Text(cred.title),
                      subtitle: Text(cred.uid),
                      onTap: () {
                        Navigator.pop(ctx);
                        _fillCredentials(cred);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _fillCredentials(SavedCredential cred) async {
    if (_webViewController == null) return;

    // Inject JS to fill the active/nearest input fields
    // This is a generic heuristic:
    // 1. If the currently focused element is a text input, assume it's username/uid.
    // 2. Find the next/nearest password input and fill the password.
    // This handles most standard login forms like Webmin and Pi-hole.

    final source =
        """
      (function() {
         var uid = "${cred.uid.replaceAll('"', '\\"')}";
         var pwd = "${cred.password.replaceAll('"', '\\"')}";
         
         var active = document.activeElement;
         if (active && active.tagName === 'INPUT') {
           if (active.type === 'text' || active.type === 'email' || active.type === '') {
             active.value = uid;
             // Dispatch input event to trigger any JS watchers
             active.dispatchEvent(new Event('input', { bubbles: true }));
             active.dispatchEvent(new Event('change', { bubbles: true }));
             
             // Now look for a password field in the same form, or just globally
             var form = active.closest('form');
             var pwds = form ? form.querySelectorAll('input[type="password"]') : document.querySelectorAll('input[type="password"]');
             if (pwds.length > 0) {
                pwds[0].value = pwd;
                pwds[0].dispatchEvent(new Event('input', { bubbles: true }));
                pwds[0].dispatchEvent(new Event('change', { bubbles: true }));
             }
           } else if (active.type === 'password') {
             // If they clicked the password box first, fill the password and try to find a username box
             active.value = pwd;
             active.dispatchEvent(new Event('input', { bubbles: true }));
             active.dispatchEvent(new Event('change', { bubbles: true }));
             
             var form = active.closest('form');
             var texts = form ? form.querySelectorAll('input[type="text"], input[type="email"]') : document.querySelectorAll('input[type="text"], input[type="email"]');
             if (texts.length > 0) {
                texts[0].value = uid;
                texts[0].dispatchEvent(new Event('input', { bubbles: true }));
                texts[0].dispatchEvent(new Event('change', { bubbles: true }));
             }
           }
         }
      })();
    """;

    await _webViewController!.evaluateJavascript(source: source);
  }
}
