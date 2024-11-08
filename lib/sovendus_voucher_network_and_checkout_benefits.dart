import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (isMobile) {
      // update with component version number
      String versionNumber = "1.2.9";

      String paddingString = "$padding" "px";

      String resizeObserver = Platform.isAndroid
          ? '''
          const interval = 250;
          const totalDuration = 5000;
          const maxChecks = totalDuration / interval;

          let checkCount = 0;
          let intervalCheckDone = false;
          const checkInterval = setInterval(() => {
            checkCount++;
            console.log(document.body.scrollHeight, checkCount);
            if (document.body.scrollHeight > 800 || checkCount >= maxChecks) {
              clearInterval(checkInterval);
              intervalCheckDone = true;
              console.log("height" + document.body.scrollHeight);
            }
          }, interval);
          new ResizeObserver(() => {
            if (intervalCheckDone) {
              console.log("height" + document.body.scrollHeight);
            }
          }).observe(document.body);
      '''
          : '''
        new ResizeObserver(() => {
          console.log("height" + document.body.scrollHeight);
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
                        console.log("openUrl"+event.data.payload.url);
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
  }
  late final String sovendusHtml;
  late final double initialWebViewHeight;
  final Widget? customProgressIndicator;
  final bool isMobile = isMobileCheck();

  static bool isNotBlacklistedUrl(Uri uri) {
    return uri.path != '/banner/api/banner' &&
        !uri.path.startsWith('/app-list') &&
        uri.path != 'blank';
  }

  @override
  State<SovendusBanner> createState() => _SovendusBanner();

  static bool isMobileCheck() {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isIOS || Platform.isAndroid;
    }
  }
}

class _SovendusBanner extends State<SovendusBanner> {
  double webViewHeight = 0;
  bool doneLoading = false;
  late final InAppWebView webViewWidget;

  @override
  void initState() {
    if (widget.isMobile) {
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
              supportZoom: false),
        ),
        onConsoleMessage: (controller, consoleMessage) {
          processConsoleMessage(consoleMessage.message);
        },
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
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
    return const SizedBox.shrink();
  }

  Future<void> processConsoleMessage(String consoleMessage) async {
    if (consoleMessage.startsWith('height')) {
      updateHeight(consoleMessage);
    } else if (consoleMessage.startsWith('openUrl')) {
      openUrlInNativeBrowser(consoleMessage);
    }
  }

  openUrlInNativeBrowser(String consoleMessage) {
    Uri url = Uri.parse(consoleMessage.replaceAll('openUrl', ''));
    launchUrl(url);
  }

  updateHeight(String consoleMessage) {
    final height = double.parse(consoleMessage.replaceAll('height', ''));
    if (webViewHeight != height && height > 100) {
      setState(() {
        webViewHeight = height;
        doneLoading = true;
      });
    }
  }
}
