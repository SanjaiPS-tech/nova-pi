import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../utils/theme.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String? secondaryUrl;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    this.secondaryUrl,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;
  bool _hasAttemptedSecondary = false;

  bool get _isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.computer_rounded,
                size: 64,
                color: Colors.white24,
              ),
              const SizedBox(height: 16),
              const Text(
                'WebView is only supported on Android/iOS',
                style: TextStyle(color: NovaTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(widget.url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Open in Browser'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCredentialRecommendation(),
          Expanded(
            child: Stack(
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
                    controller.addJavaScriptHandler(
                      handlerName: 'onInputFocus',
                      callback: (args) {
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
                  onLoadStart: (controller, url) =>
                      setState(() => _isLoading = true),
                  onLoadStop: (controller, url) async {
                    setState(() => _isLoading = false);
                    await controller.evaluateJavascript(
                      source: """
                document.addEventListener('focusin', function(e) {
                  if (e.target && e.target.tagName === 'INPUT') {
                    var type = e.target.type.toLowerCase();
                    if (['text', 'password', 'email', 'search', ''].includes(type)) {
                       window.flutter_inappwebview.callHandler('onInputFocus');
                    }
                  }
                });
              """,
                    );
                  },
                  onProgressChanged: (controller, progress) =>
                      setState(() => _progress = progress / 100),
                  onReceivedServerTrustAuthRequest:
                      (controller, challenge) async {
                        return ServerTrustAuthResponse(
                          action: ServerTrustAuthResponseAction.PROCEED,
                        );
                      },
                  onReceivedHttpError: (controller, request, errorResponse) {
                    if (request.isForMainFrame ?? false) {
                      _handleError(controller);
                    }
                  },
                  onReceivedError: (controller, request, error) {
                    if (request.isForMainFrame ?? false) {
                      _handleError(controller);
                    }
                  },
                  onDownloadStartRequest: (controller, req) async {
                    if (await canLaunchUrl(req.url)) {
                      await launchUrl(
                        req.url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
                if (_isLoading || _progress < 1.0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(
                        NovaTheme.primary,
                      ),
                      minHeight: 3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleError(InAppWebViewController controller) {
    setState(() => _isLoading = false);
    if (!_hasAttemptedSecondary &&
        widget.secondaryUrl != null &&
        widget.secondaryUrl!.isNotEmpty) {
      _hasAttemptedSecondary = true;
      controller.loadUrl(
        urlRequest: URLRequest(url: WebUri(widget.secondaryUrl!)),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primary URL failed. Trying secondary URL...'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to load page.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Reload',
            onPressed: () {
              _hasAttemptedSecondary = false;
              controller.loadUrl(
                urlRequest: URLRequest(url: WebUri(widget.url)),
              );
            },
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildCredentialRecommendation() {
    final settings = Provider.of<SettingsService>(context);
    if (settings.credentials.isEmpty) return const SizedBox.shrink();

    final cred = settings.credentials.first;
    return Container(
      width: double.infinity,
      color: NovaTheme.primary.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: NovaTheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Recommended Login: ${cred.uid}',
            style: const TextStyle(fontSize: 12, color: NovaTheme.primary),
          ),
        ],
      ),
    );
  }

  void _showCredentialsBottomSheet(BuildContext context) {
    final settings = Provider.of<SettingsService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: NovaTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Auto-fill Login',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: settings.credentials.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final cred = settings.credentials[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.key_rounded,
                          color: NovaTheme.primary,
                        ),
                        title: Text(
                          cred.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          cred.uid,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _fillCredentials(cred);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ).animate().slideY(
          begin: 1.0,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
      },
    );
  }

  void _fillCredentials(SavedCredential cred) async {
    if (_webViewController == null) return;
    final source =
        """
      (function() {
         var uid = "${cred.uid.replaceAll('"', '\\"')}";
         var pwd = "${cred.password.replaceAll('"', '\\"')}";
         var active = document.activeElement;
         if (active && active.tagName === 'INPUT') {
           if (['text', 'email', ''].includes(active.type)) {
             active.value = uid;
             active.dispatchEvent(new Event('input', { bubbles: true }));
             active.dispatchEvent(new Event('change', { bubbles: true }));
             var form = active.closest('form');
             var pwds = form ? form.querySelectorAll('input[type="password"]') : document.querySelectorAll('input[type="password"]');
             if (pwds.length > 0) {
                pwds[0].value = pwd;
                pwds[0].dispatchEvent(new Event('input', { bubbles: true }));
                pwds[0].dispatchEvent(new Event('change', { bubbles: true }));
             }
           } else if (active.type === 'password') {
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
