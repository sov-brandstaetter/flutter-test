import 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'dart:html' as html;
// import 'dart:ui' as ui;
// import 'dart:ui_web' as ui;

class SovendusCustomerData {
  SovendusCustomerData({
    this.salutation,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.yearOfBirth,
    this.dateOfBirth,
    this.street,
    this.streetNumber,
    this.zipcode,
    this.city,
    this.country,
  });
  String? salutation;
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  int? yearOfBirth;
  String? dateOfBirth;
  String? street;
  String? streetNumber;
  String? zipcode;
  String? city;
  String? country;
}

class SovendusBanner extends StatefulWidget {
  SovendusBanner({
    super.key,
    required int trafficSourceNumber,
    required int trafficMediumNumber,
    int orderUnixTime = 0,
    String sessionId = "",
    String orderId = "",
    double netOrderValue = 0,
    String currencyCode = "",
    String usedCouponCode = "",
    SovendusCustomerData? customerData,
    this.customProgressIndicator,
    double padding = 0,
    String backgroundColor = "#fff",
  }) {
    // update with component version number
    String versionNumber = "1.3.0";

    String paddingString = "$padding" "px";
    bool isAndroid = false; // TODO Platform.isAndroid - doesnt work on web
    String resizeObserver = isAndroid
        ? '''
          const interval = 250;
          const totalDuration = 5000;
          const maxChecks = totalDuration / interval;

          let checkCount = 0;
          let intervalCheckDone = false;
          const checkInterval = setInterval(() => {
            checkCount++;
            if (document.body.scrollHeight > 800 || checkCount >= maxChecks) {
              clearInterval(checkInterval);
              intervalCheckDone = true;
              window.top.postMessage({height: document.body.scrollHeight}, "${Uri.base.origin}");
            }
          }, interval);
          new ResizeObserver(() => {
            if (intervalCheckDone) {
              window.top.postMessage({height: document.body.scrollHeight}, "${Uri.base.origin}");
            }
          }).observe(document.body);
      '''
        : '''
        new ResizeObserver(() => {
          window.top.postMessage({height: document.body.scrollHeight}, "${Uri.base.origin}");
        }).observe(document.body);
      ''';

    sovendusHtml = '''
        <!DOCTYPE html>
        <html>
            <head>
              <meta name="viewport" content="initial-scale=1" />
            </head>
            <body id="body" style="padding-bottom: 0; margin: 0; padding-top: $paddingString; padding-left: $paddingString; padding-right: $paddingString; background-color: $backgroundColor">
                <div id="sovendus-voucher-banner"></div>
                <script type="text/javascript">
                    $resizeObserver
                    window.sovApi = "v1";
                    window.addEventListener("message", (event) => {
                      if (event.data.channel === "sovendus:integration") {
                        window.top.postMessage({$openUrl: event.data.payload.url}, "${Uri.base.origin}");
                      }
                    });
                    window.sovIframes = [];
                    window.sovIframes.push({
                        trafficSourceNumber: "$trafficSourceNumber",
                        trafficMediumNumber: "$trafficMediumNumber",
                        iframeContainerId: "sovendus-voucher-banner",
                        timestamp: "$orderUnixTime",
                        sessionId: "$sessionId",
                        orderId: "$orderId",
                        orderValue: "$netOrderValue",
                        orderCurrency: "$currencyCode",
                        usedCouponCode: "$usedCouponCode",
                        integrationType: "flutter-$versionNumber",
                    });
                    window.sovConsumer = {
                        consumerSalutation: "${customerData?.salutation ?? ""}",
                        consumerFirstName: "${customerData?.firstName ?? ""}",
                        consumerLastName: "${customerData?.lastName ?? ""}",
                        consumerEmail: "${customerData?.email ?? ""}",
                        consumerPhone : "${customerData?.phone ?? ""}",   
                        consumerYearOfBirth  : "${customerData?.yearOfBirth ?? ""}",   
                        consumerDateOfBirth  : "${customerData?.dateOfBirth ?? ""}",   
                        consumerStreet: "${customerData?.street ?? ""}",
                        consumerStreetNumber: "${customerData?.streetNumber ?? ""}",
                        consumerZipcode: "${customerData?.zipcode ?? ""}",
                        consumerCity: "${customerData?.city ?? ""}",
                        consumerCountry: "${customerData?.country ?? ""}",
                    };
                </script>
                <script type="text/javascript" src="https://api.sovendus.com/sovabo/common/js/flexibleIframe.js" async=true></script>
            </body>
        </html>
    ''';
    initialWebViewHeight = 348;
  }
  late final String sovendusHtml;
  late final double initialWebViewHeight;
  final Widget? customProgressIndicator;
  final String openUrl = "openUrl";

  static bool isNotBlacklistedUrl(Uri uri) {
    return uri.path != '/banner/api/banner' &&
        !uri.path.startsWith('/app-list') &&
        uri.path != 'blank';
  }

  @override
  State<SovendusBanner> createState() => _SovendusBanner();
}

class _SovendusBanner extends State<SovendusBanner> {
  double webViewHeight = 0;
  bool doneLoading = false;
  bool isWeb = true;
  InAppWebView? webViewWidget;

  @override
  void initState() {
    // if (isWeb) {
    // } else {
    initMobile();
    // }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // if (isWeb) {
    //   initWeb();
    //   return Container(
    //     width: 300,
    //     height: 300,
    //     child: HtmlElementView(
    //       viewType: 'sovendus-html',
    //     ),
    //   );
    // }
    return SizedBox(
        height: webViewHeight,
        child: Column(children: [
          SizedBox(
              height: doneLoading ? webViewHeight : 1, child: webViewWidget),
          ...doneLoading
              ? []
              : [
                  SizedBox(
                      height: webViewHeight - 1,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            widget.customProgressIndicator ??
                                const CircularProgressIndicator()
                          ]))
                ]
        ]));
  }

  Future<void> initMobile() async {
    // Used for fetching full height from the iFrame
    window.addEventListener(
      'message',
      (event) {
        if (event is MessageEvent) {
          final height = double.tryParse(
            (event.data as Map)['height'].toString(),
          );
          if (height != null && mounted) {
            updateHeight(height);
          } else {
            Uri? url = Uri.tryParse((event.data as Map)[widget.openUrl]);
            if (url != null && mounted) {
              openUrlInNativeBrowser(url);
            }
          }
        }
      },
    );

    webViewHeight = widget.initialWebViewHeight;
    webViewWidget = InAppWebView(
      initialData: InAppWebViewInitialData(data: widget.sovendusHtml),
      initialOptions: InAppWebViewGroupOptions(
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
        ),
        android: AndroidInAppWebViewOptions(textZoom: 100),
        crossPlatform: InAppWebViewOptions(
            // mediaPlaybackRequiresUserGesture: false,
            // To prevent links from opening in external browser.
            useShouldOverrideUrlLoading: true,
            disableHorizontalScroll: true,
            disableVerticalScroll: true,
            supportZoom: false),
      ),
      onConsoleMessage: (controller, consoleMessage) {
        processConsoleMessage(consoleMessage.message);
      },
      onScrollChanged: (controller, x, y) => {},
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        if (navigationAction.request.url != null &&
            SovendusBanner.isNotBlacklistedUrl(
              navigationAction.request.url!,
            )) {
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  // Future<void> initWeb() async {
  //   ui.platformViewRegistry.registerViewFactory(
  //     'sovendus-html',
  //     (int viewId) {
  //       // Create an iframe element
  //       final html.IFrameElement iframe = html.IFrameElement()
  //         ..width = '100%'
  //         ..height = '300'
  //         ..style.border = 'none' // Remove default iframe border
  //         ..srcdoc = widget.sovendusHtml // Embed HTML content directly
  //         ..allowFullscreen = true;

  //       return iframe;
  //     },
  //   );
  // }

  Future<void> processConsoleMessage(String consoleMessage) async {
    // print("console mess");
    if (consoleMessage.startsWith('height')) {
      double height = double.parse(consoleMessage.replaceAll('height', ''));
      updateHeight(height);
    } else if (consoleMessage.startsWith('openUrl')) {
      Uri url = Uri.parse(consoleMessage.replaceAll('openUrl', ''));
      openUrlInNativeBrowser(url);
    }
  }

  openUrlInNativeBrowser(Uri url) {
    launchUrl(url);
  }

  updateHeight(double height) {
    // print("setting height");
    // print(height);
    if (webViewHeight != height && height > 100) {
      setState(() {
        webViewHeight = height;
        doneLoading = true;
      });
    }
  }
}
