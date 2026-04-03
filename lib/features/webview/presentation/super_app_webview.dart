import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path/path.dart' as p;

class SuperAppWebView extends StatefulWidget {
  /// The URL to load. If null, we'll load the local test_webapp asset.
  final String? url;
  /// Mock injected token for demonstration
  final String authToken;
  /// If provided, dynamically loads this web bundle from assets/mini_apps/
  final String? miniAppId;
  /// Optional product to add to cart on load
  final Map<String, dynamic>? pendingProductJson;
  /// An explicit absolute file path to a downloaded OTA mini-app bundle
  final String? localHtmlFilePath;
  /// Optional title override provided via routing
  final String? title;

  const SuperAppWebView({
    super.key,
    this.url,
    this.authToken = 'mock_jwt_token_123',
    this.miniAppId,
    this.pendingProductJson,
    this.localHtmlFilePath,
    this.title,
  });

  @override
  State<SuperAppWebView> createState() => _SuperAppWebViewState();
}

class _SuperAppWebViewState extends State<SuperAppWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  HttpServer? _localServer;

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
            _injectAuthToken();
          },
          onPageFinished: (String url) {
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
    _loadContent();
  }

  /// Determines how to load the content based on what was provided.
  Future<void> _loadContent() async {
    if (widget.url != null) {
      _controller.loadRequest(Uri.parse(widget.url!));
    } else if (widget.localHtmlFilePath != null) {
      // Start a local HTTP server to serve OTA-downloaded mini-app bundles.
      // Android WebView blocks file:// cross-origin requests (CORS),
      // so we must serve via http://localhost to load JS/CSS assets.
      await _startLocalServer(widget.localHtmlFilePath!);
    } else if (widget.miniAppId != null) {
      _controller.loadFlutterAsset('assets/mini_apps/${widget.miniAppId}/index.html');
    } else {
      _controller.loadFlutterAsset('assets/test_webapp/index.html');
    }
  }

  /// Spins up a local HTTP server that serves files from the mini-app directory.
  /// WebView then loads from http://localhost:PORT/ which avoids all CORS issues.
  Future<void> _startLocalServer(String indexHtmlPath) async {
    final bundleDir = Directory(p.dirname(indexHtmlPath));

    // Bind to a random available port on localhost
    _localServer = await HttpServer.bind('127.0.0.1', 0);
    final port = _localServer!.port;
    debugPrint('Local server started on port $port for ${bundleDir.path}');

    // Serve files from the bundle directory
    _localServer!.listen((HttpRequest request) async {
      try {
        var requestPath = request.uri.path;
        if (requestPath == '/') requestPath = '/index.html';

        final filePath = p.join(bundleDir.path, requestPath.substring(1));
        final file = File(filePath);

        if (await file.exists()) {
          final mimeType = _getMimeType(requestPath);
          request.response.headers.contentType = ContentType.parse(mimeType);
          
          // CRITICAL: Disable MIME sniffing. Modern browsers/WebViews block scripts 
          // if their type isn't explicitly declared correctly and 'nosniff' is set.
          request.response.headers.set('X-Content-Type-Options', 'nosniff');
          request.response.headers.set('Access-Control-Allow-Origin', '*');
          
          await request.response.addStream(file.openRead());
        } else {
          // Safe-404: Return correct MIME with empty body to avoid blocking subsequent scripts (ORB Fix)
          final mimeType = _getMimeType(requestPath);
          request.response.headers.contentType = ContentType.parse(mimeType);
          request.response.headers.set('X-Content-Type-Options', 'nosniff');
          request.response.statusCode = HttpStatus.notFound;
          debugPrint('[Server] 404: $requestPath (Served as $mimeType)');
        }
      } catch (e) {
        debugPrint('[Server] Error: $e');
        request.response.statusCode = HttpStatus.internalServerError;
      } finally {
        await request.response.close();
      }
    });

    // Load the mini-app from the local server
    final serverUrl = 'http://127.0.0.1:$port/';
    debugPrint('[Server] Loading: $serverUrl');
    await _controller.loadRequest(Uri.parse(serverUrl));
  }

  /// Returns the MIME type for common web file extensions.
  String _getMimeType(String requestPath) {
    final ext = p.extension(requestPath).toLowerCase();
    switch (ext) {
      case '.html': return 'text/html; charset=utf-8';
      case '.js':   return 'text/javascript; charset=utf-8';
      case '.css':  return 'text/css; charset=utf-8';
      case '.json': return 'application/json; charset=utf-8';
      case '.png':  return 'image/png';
      case '.jpg':
      case '.jpeg': return 'image/jpeg';
      case '.gif':  return 'image/gif';
      case '.svg':  return 'image/svg+xml';
      case '.woff': return 'font/woff';
      case '.woff2':return 'font/woff2';
      case '.ttf':  return 'font/ttf';
      case '.ico':  return 'image/x-icon';
      case '.webp': return 'image/webp';
      default:      return 'application/octet-stream';
    }
  }

  @override
  void dispose() {
    // Stop the local server when the WebView is disposed
    _localServer?.close(force: true);
    super.dispose();
  }

  /// Injects the auth token as a global Javascript variable
  void _injectAuthToken() {
    final jsCode = """
      window.superAppAuthToken = '${widget.authToken}'; 
      if (typeof window.receiveMessageFromNative === 'function') {
        window.receiveMessageFromNative('updateToken', '${widget.authToken}');
      }
    """;
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
           final responseData = {
              "id": 1,
              "name": "Super App User",
              "tier": "Premium",
              "isSessionValid": true,
           };
           _sendDataBackToWeb('userInfoResponse', responseData);
          break;
        case 'showDialog':
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
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title ?? (widget.miniAppId != null ? 'Mini App: ${widget.miniAppId}' : 'Mini App')),
      //   elevation: 0,
      // ),
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
