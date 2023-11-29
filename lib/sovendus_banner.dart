import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SovendusCustomerData {
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
}

class SovendusBanner extends StatefulWidget {
  late final WebViewController? _controller;
  late final double initialWebViewHeight;

  final Widget? customProgressIndicator;

  SovendusBanner({
    super.key,
    required int trafficSourceNumber,
    int? trafficMediumNumberVoucherNetwork,
    int? trafficMediumNumberCheckoutBenefits,
    required int orderUnixTime,
    required String sessionId,
    required String orderId,
    required double netOrderValue,
    required String currencyCode,
    required String usedCouponCode,
    SovendusCustomerData? customerData,
    this.customProgressIndicator,
  }) {
    if (isMobile()) {
      String sovendusHtml = '''
        <!DOCTYPE html>
        <html>
            <head>
              <meta name="viewport" content="initial-scale=1" />
            </head>
            <body id="body">
                <div id="sovendus-voucher-banner"></div>
                <div id="sovendus-checkout-benefits-banner"></div>
                <script type="text/javascript">
                    const _body = document.getElementById("body");
                    new ResizeObserver(() => {
                        console.log("height" + _body.clientHeight)
                    }).observe(_body);
                    window.sovIframes = [];
                    if ("$trafficMediumNumberVoucherNetwork"){
                      window.sovIframes.push({
                          trafficSourceNumber: "$trafficSourceNumber",
                          trafficMediumNumber: "$trafficMediumNumberVoucherNetwork",
                          iframeContainerId: "sovendus-voucher-banner",
                          timestamp: "$orderUnixTime",
                          sessionId: "$sessionId",
                          orderId: "$orderId",
                          orderValue: "$netOrderValue",
                          orderCurrency: "$currencyCode",
                          usedCouponCode: "$usedCouponCode"
                      });
                    }
                    if ("$trafficMediumNumberCheckoutBenefits"){
                      window.sovIframes.push({
                          trafficSourceNumber: "$trafficSourceNumber",
                          trafficMediumNumber: "$trafficMediumNumberCheckoutBenefits",
                          iframeContainerId: "sovendus-checkout-benefits-banner",
                      });
                    }
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
      double _initialWebViewHeight = 0;
      if (trafficMediumNumberVoucherNetwork is int) {
        _initialWebViewHeight += 348;
      }
      if (trafficMediumNumberCheckoutBenefits is int) {
        _initialWebViewHeight += 500;
      }
      initialWebViewHeight = _initialWebViewHeight;
      final WebViewController controller = WebViewController();
      controller.loadHtmlString(sovendusHtml);
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.enableZoom(false);
      controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            Uri uri = Uri.parse(request.url);
            if (isNotBlacklistedUrl(uri)) {
              launchUrl(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
      _controller = controller;
    }
  }

  static isNotBlacklistedUrl(Uri uri) {
    return uri.path != "/banner/api/banner" &&
        !uri.path.startsWith("/app-list/") &&
        uri.path != "blank";
  }

  @override
  State<SovendusBanner> createState() => _SovendusBanner();

  static bool isMobile() {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isIOS || Platform.isAndroid;
    }
  }

  static bool isAndroid() {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isAndroid;
    }
  }
}

class _SovendusBanner extends State<SovendusBanner> {
  double webViewHeight = 0;
  bool loadingDone = false;

  @override
  Widget build(BuildContext context) {
    if (SovendusBanner.isMobile()) {
      widget._controller?.setOnConsoleMessage(
        (JavaScriptConsoleMessage message) {
          updateHeight(message.message);
        },
      );
      double finalWebViewHeight = webViewHeight;
      if (webViewHeight < 20) {
        finalWebViewHeight = widget.initialWebViewHeight;
      }

      return SizedBox(
        height: finalWebViewHeight,
        child: (loadingDone || !SovendusBanner.isAndroid())
            ? WebViewWidget(
                controller: widget._controller ?? WebViewController(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                    widget.customProgressIndicator ??
                        const CircularProgressIndicator()
                  ]),
      );
    }
    return const SizedBox.shrink();
  }

  void updateHeight(String windowHeight) async {
    if (windowHeight.startsWith("height")) {
      double height = double.parse(windowHeight.replaceAll("height", ""));
      if (webViewHeight != height && height > 20) {
        setState(() {
          webViewHeight = height;
          loadingDone = true;
        });
      }
    }
  }
}
