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
    required int orderUnixTime,
    required String sessionId,
    required String orderId,
    required double netOrderValue,
    required String currencyCode,
    required String usedCouponCode,
    SovendusCustomerData? customerData,
    this.customProgressIndicator,
    double padding = 0,
    String backgroundColor = "#fff",
  }) {
    if (isMobile) {
      String paddingString = "$padding" "px";
      sovendusHtml = '''
        <!DOCTYPE html>
        <html>
            <head>
              <meta name="viewport" content="initial-scale=1" />
            </head>
            <body id="body" style="padding-bottom: 0; margin: 0; padding-top: $paddingString; padding-left: $paddingString; padding-right: $paddingString; background-color: $backgroundColor">
                <div id="sovendus-voucher-banner"></div>
                <div id="sovendus-checkout-benefits-banner"></div>
                <script type="text/javascript">
                    const _body = document.getElementById("body");
                    new ResizeObserver(() => {
                        console.log("height" + _body.clientHeight)
                    }).observe(_body);
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
                    });
                    window.sovConsumer = {
                        consumerSalutation: "${customerData?.salutation ?? ""}",
                        consumerFirstName: "${customerData?.firstName ?? ""}",
                        consumerLastName: "${customerData?.lastName ?? ""}",
                        consumerEmail: "${customerData?.email ?? ""}",
                        consumerPhone : "${customerData?.phone ?? ""}",   
                        consumerYearOfBirth  : "${customerData?.yearOfBirth ?? ""}",   
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
          updateHeight(consoleMessage.message);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          if (navigationAction.request.url != null &&
              SovendusBanner.isNotBlacklistedUrl(
                navigationAction.request.url!,
              )) {
            launchUrl(navigationAction.request.url!);
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
        // onWebViewCreated: (controller) {
        //   // controller.loadData(data: widget.sovendusHtml);
        // },
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
                        height: webViewHeight,
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

  Future<void> updateHeight(String consoleMessage) async {
    if (consoleMessage.startsWith('height')) {
      final height = double.parse(consoleMessage.replaceAll('height', ''));
      if (webViewHeight != height && height > 100) {
        setState(() {
          webViewHeight = height;
          doneLoading = true;
        });
      }
    }
  }
}
