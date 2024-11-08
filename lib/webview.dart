import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ResizableWebView extends StatefulWidget {
  @override
  State<ResizableWebView> createState() => _ResizableWebView();
}

class _ResizableWebView extends State<ResizableWebView> {
  double webViewHeight = 200;
  late final InAppWebView webViewWidget;

  @override
  void initState() {
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
                }, 2000);
              </script>
            </body>
        </html>
    ''';
    webViewWidget = InAppWebView(
      initialData: InAppWebViewInitialData(data: html),
      // initialOptions: InAppWebViewGroupOptions(
      //   crossPlatform: InAppWebViewOptions(supportZoom: false),
      // ),
      onConsoleMessage: (controller, consoleMessage) {
        processConsoleMessage(consoleMessage.message);
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: webViewHeight, child: webViewWidget);
  }

  Future<void> processConsoleMessage(String consoleMessage) async {
    final height = double.parse(consoleMessage.replaceAll('height', ''));
    if (consoleMessage.startsWith('height')) {
      setState(() {
        webViewHeight = height;
      });
    }
  }
}
