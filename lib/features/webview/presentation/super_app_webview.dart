import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SuperAppWebView extends StatefulWidget {
  /// The URL to load. If null, we'll load the local test_webapp asset.
  final String? url;
  /// Mock injected token for demonstration
  final String authToken;
  /// If true, load the React Web App cart
  final bool useWebApp;
  /// Optional product to add to cart on load
  final Map<String, dynamic>? pendingProductJson;

  const SuperAppWebView({
    super.key,
    this.url,
    this.authToken = 'mock_jwt_token_123',
    this.useWebApp = false,
    this.pendingProductJson,
  });

  @override
  State<SuperAppWebView> createState() => _SuperAppWebViewState();
}

class _SuperAppWebViewState extends State<SuperAppWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      
      // 2. Setup Navigation Delegate to handle loading state and injections
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            // Example: Injecting token early as soon as page starts.
            // On some platforms, it might be better to inject on load finish, 
            // but we try to do it ASAP so Javascript sees it.
            _injectAuthToken();
          },
          onPageFinished: (String url) {
             // Inject again just to be safe if it was a quick load
            _injectAuthToken();
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('SuperAppWebView Error: ${error.description}');
            setState(() {
               _isLoading = false;
            });
          },
        ),
      )
      
      // 3. Setup Javascript Bridge (The Super App communication channel)
      ..addJavaScriptChannel(
        'SuperAppBridge',
        onMessageReceived: _handleBridgeMessage,
      );

    // 4. Load Content
    if (widget.url != null) {
      _controller.loadRequest(Uri.parse(widget.url!));
    } else if (widget.useWebApp) {
      // Load React Web App from assets
      _controller.loadFlutterAsset('assets/web_app/index.html');
    } else {
      // Load local test HTML
      _controller.loadFlutterAsset('assets/test_webapp/index.html');
    }
  }

  /// Injects the auth token as a global Javascript variable
  void _injectAuthToken() {
    final jsCode = "window.superAppAuthToken = '${widget.authToken}'; window.receiveMessageFromNative('updateToken', '${widget.authToken}');";
    _controller.runJavaScript(jsCode);
  }

  /// Handles messages sent from Javascript via `window.SuperAppBridge.postMessage`
  void _handleBridgeMessage(JavaScriptMessage message) {
    debugPrint("Received from Bridge: ${message.message}");
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final action = data['action'] as String?;
      final payload = data['data'] as Map<String, dynamic>? ?? {};

      switch (action) {
        case 'reactAppReady':
           if (widget.pendingProductJson != null) {
              _sendDataBackToWeb('addToCart', widget.pendingProductJson!);
           }
          break;
        case 'getUserInfo':
           // Mock fetching API data that the native side has access to
           final responseData = {
              "id": 1,
              "name": "Super App User",
              "tier": "Premium",
              "isSessionValid": true,
           };
           _sendDataBackToWeb('userInfoResponse', responseData);
          break;
        case 'showDialog':
           // Native dialog triggered by Web App
           _showNativeDialog(
             payload['title'] ?? 'Native Dialog',
             payload['message'] ?? 'This was launched from the webview.',
           );
          break;
        case 'checkoutClicked':
           final total = payload['total'] ?? 0.0;
           _showNativeDialog('Secure Native Checkout', 'Processing payment for \$$total natively!');
          break;
        case 'close':
           // Close the Web App screen returning to native flutter
           if (Navigator.canPop(context)) {
             Navigator.pop(context);
           }
          break;
        default:
          debugPrint("Unknown bridge action: $action");
      }
    } catch (e) {
      debugPrint("Failed to parse bridge JSON: $e");
    }
  }

  /// Evaluates JS to execute a global function on the web passing data back
  void _sendDataBackToWeb(String action, dynamic data) {
    final encodedData = jsonEncode(data);
    final jsCode = "window.receiveMessageFromNative('$action', $encodedData);";
    _controller.runJavaScript(jsCode);
  }

  void _showNativeDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A core feature of a Super App webview is it should feel native.
    // We typically don't show an app bar, or we show a custom native one.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.useWebApp ? 'Shopping Cart' : 'Mini App'),
        elevation: 0,
         // We can intercept the back button to handle internal web history
         // if desired, for now we just pop the route.
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
