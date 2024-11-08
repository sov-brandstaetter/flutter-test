import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ResizableWebView extends StatefulWidget {
  @override
  State<ResizableWebView> createState() => _ResizableWebView();
}

class _ResizableWebView extends State<ResizableWebView> {
  double webViewHeight = 200;
  late WebViewWidget webViewWidget;

  @override
  void initState() {
    super.initState();
    WebViewController _controller = WebViewController();
    _controller.setOnConsoleMessage(
      (JavaScriptConsoleMessage message) {
        // Process height data received from webview
        print(message);
        final height = double.parse(message.message.replaceAll('height', ''));
        setState(() {
          webViewHeight = height;
        });
      },
    );
    String html = '''
        <!DOCTYPE html>
        <html>
            <head>
              <meta name="viewport" content="initial-scale=1" />
            </head>
            <body id="body">
              <div id="test">
                <h1> Bsdfsdfsdfsdfsdf<h1>
                <h1> Bsdfsdfsdfsdfsdf<h1>
                <h1> Bsdfsdfsdfsdfsdf<h1>
              </div>
              <script type="text/javascript">
                let heightIncrement = 200;
                const testDiv = document.getElementById("test");
                setInterval(() => {
                    let currentHeight = parseInt(window.getComputedStyle(testDiv).height);
                    testDiv.style.height = (currentHeight + 400) + 'px';
                    console.log("height" + (currentHeight + 400));
                    // Communicate the height back to Flutter
                    if (window.flutter_inappwebview) {
                      window.flutter_inappwebview.callHandler('height', currentHeight + 400);
                    }
                }, 2000);
              </script>
            </body>
        </html>
    ''';
    _controller.loadHtmlString(html);
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.enableZoom(false);
    webViewWidget = WebViewWidget(
      controller: _controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: webViewHeight, child: webViewWidget);
  }
}
