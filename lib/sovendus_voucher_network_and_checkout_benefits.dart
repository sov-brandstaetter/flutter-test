import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class SovendusCustomerData {
  const SovendusCustomerData({
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

  final String? salutation;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final int? yearOfBirth;
  final String? dateOfBirth;
  final String? street;
  final String? streetNumber;
  final String? zipcode;
  final String? city;
  final String? country;

  SovendusCustomerData sanitized() {
    return SovendusCustomerData(
      salutation: HtmlSanitizer.sanitizeNullable(salutation),
      firstName: HtmlSanitizer.sanitizeNullable(firstName),
      lastName: HtmlSanitizer.sanitizeNullable(lastName),
      email: HtmlSanitizer.sanitizeNullable(email),
      phone: HtmlSanitizer.sanitizeNullable(phone),
      yearOfBirth: yearOfBirth,
      dateOfBirth: HtmlSanitizer.sanitizeNullable(dateOfBirth),
      street: HtmlSanitizer.sanitizeNullable(street),
      streetNumber: HtmlSanitizer.sanitizeNullable(streetNumber),
      zipcode: HtmlSanitizer.sanitizeNullable(zipcode),
      city: HtmlSanitizer.sanitizeNullable(city),
      country: HtmlSanitizer.sanitizeNullable(country),
    );
  }
}

class SovendusBanner extends StatefulWidget {
  SovendusBanner({
    super.key,
    required this.trafficSourceNumber,
    required this.trafficMediumNumber,
    this.orderUnixTime = 0,
    this.sessionId = "",
    this.orderId = "",
    this.netOrderValue = 0,
    this.currencyCode = "",
    this.usedCouponCode = "",
    this.customerData,
    this.customProgressIndicator,
    this.padding = 0,
    this.backgroundColor = "#fff",
    this.disableAndroidWaitingForCheckoutBenefits = false,
    this.onError,
  });

  final int trafficSourceNumber;
  final int trafficMediumNumber;
  final int orderUnixTime;
  final String sessionId;
  final String orderId;
  final double netOrderValue;
  final String currencyCode;
  final String usedCouponCode;
  final SovendusCustomerData? customerData;
  final Widget? customProgressIndicator;
  final double padding;
  final String backgroundColor;
  final bool disableAndroidWaitingForCheckoutBenefits;
  final Function(String errorMessage, dynamic error)? onError;

  // update with component version number
  static const String versionNumber = "1.2.11";

  /// Generates the HTML content for the Sovendus banner
  String generateHtml() {
    if (!isMobileCheck) return '';

    try {
      final sanitizedSessionId = HtmlSanitizer.sanitize(sessionId);
      final sanitizedOrderId = HtmlSanitizer.sanitize(orderId);
      final sanitizedCurrencyCode = HtmlSanitizer.sanitize(currencyCode);
      final sanitizedUsedCouponCode = HtmlSanitizer.sanitize(usedCouponCode);
      final sanitizedBackgroundColor = HtmlSanitizer.sanitize(backgroundColor);

      // Create sanitized customer data using the sanitized() method
      final sanitizedCustomerData =
          customerData?.sanitized() ?? const SovendusCustomerData();

      String paddingString = "${padding}px";

      String resizeObserver =
          Platform.isAndroid && !disableAndroidWaitingForCheckoutBenefits
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

      return '''
        <!DOCTYPE html>
        <html>
            <head>
              <meta name="viewport" content="initial-scale=1" />
            </head>
            <body id="body" style="padding-bottom: 0; margin: 0; padding-top: $paddingString; padding-left: $paddingString; padding-right: $paddingString; background-color: $sanitizedBackgroundColor">
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
                        sessionId: "$sanitizedSessionId",
                        orderId: "$sanitizedOrderId",
                        orderValue: "$netOrderValue",
                        orderCurrency: "$sanitizedCurrencyCode",
                        usedCouponCode: "$sanitizedUsedCouponCode",
                        integrationType: "flutter-$versionNumber",
                    });
                    window.sovConsumer = {
                        consumerSalutation: "${sanitizedCustomerData.salutation ?? ""}",
                        consumerFirstName: "${sanitizedCustomerData.firstName ?? ""}",
                        consumerLastName: "${sanitizedCustomerData.lastName ?? ""}",
                        consumerEmail: "${sanitizedCustomerData.email ?? ""}",
                        consumerPhone : "${sanitizedCustomerData.phone ?? ""}",
                        consumerYearOfBirth: "${sanitizedCustomerData.yearOfBirth ?? ""}",
                        consumerDateOfBirth: "${sanitizedCustomerData.dateOfBirth ?? ""}",
                        consumerStreet: "${sanitizedCustomerData.street ?? ""}",
                        consumerStreetNumber: "${sanitizedCustomerData.streetNumber ?? ""}",
                        consumerZipcode: "${sanitizedCustomerData.zipcode ?? ""}",
                        consumerCity: "${sanitizedCustomerData.city ?? ""}",
                        consumerCountry: "${sanitizedCustomerData.country ?? ""}",
                    };
                </script>
                <script type="text/javascript" src="https://api.sovendus.com/sovabo/common/js/flexibleIframe.js" async=true></script>
            </body>
        </html>
      ''';
    } catch (e) {
      reportError(
        'Error generating Sovendus HTML',
        e,
        onError: onError,
        trafficSourceNumber: trafficSourceNumber,
        trafficMediumNumber: trafficMediumNumber,
      );
      return '';
    }
  }

  static double initialWebViewHeight = 348.0;

  /// Gets the generated HTML content for the banner
  String get sovendusHtml => generateHtml();

  static String errorApi = 'https://press-tracking-api.sovendus.com/error';
  static int errorCounter = 0;

  static bool isNotBlacklistedUrl(Uri uri) {
    return uri.path != '/banner/api/banner' &&
        !uri.path.startsWith('/app-list') &&
        uri.path != 'blank';
  }

  static Future<void> reportError(
    String errorMessage,
    dynamic error, {
    Function(String errorMessage, dynamic error)? onError,
    String? source,
    String? type,
    int? trafficSourceNumber,
    int? trafficMediumNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      errorCounter++;

      final errorData = {
        'source': source ?? 'flutter-script',
        'type': type ?? 'exception',
        'message': errorMessage,
        'counter': errorCounter,
        'trafficSource': trafficSourceNumber ?? "not_defined",
        'trafficMedium': trafficMediumNumber ?? "not_defined",
        'additionalData': jsonEncode({
          'appName': 'flutter-script',
          'error': error.toString(),
          ...?additionalData,
        }),
        'implementationType': 'flutter-$versionNumber',
      };

      await http.post(
        Uri.parse(errorApi),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(errorData),
      );
    } catch (apiError) {
      onError?.call("Failed to report error to API: $apiError", error);
    }
    onError?.call(errorMessage, error);
  }

  @override
  State<SovendusBanner> createState() => _SovendusBanner();
  static bool get isMobileCheck {
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
    if (SovendusBanner.isMobileCheck) {
      webViewHeight = SovendusBanner.initialWebViewHeight;
      webViewWidget = InAppWebView(
        initialData: InAppWebViewInitialData(data: widget.sovendusHtml),
        initialSettings: InAppWebViewSettings(
          allowsInlineMediaPlayback: true,
          textZoom: 100,
          mediaPlaybackRequiresUserGesture: false,
          // To prevent links from opening in external browser.
          useShouldOverrideUrlLoading: true,
          supportZoom: false,
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
    if (SovendusBanner.isMobileCheck) {
      return SizedBox(
        height: webViewHeight,
        child: Column(
          children: [
            SizedBox(
              // using a pixel intentionally as webview wont load with 0px
              height: doneLoading ? webViewHeight : 1,
              child: webViewWidget,
            ),
            ...doneLoading
                ? []
                : [
                    SizedBox(
                      height: webViewHeight - 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          widget.customProgressIndicator ??
                              const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  ],
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> processConsoleMessage(String consoleMessage) async {
    try {
      if (consoleMessage.startsWith('height')) {
        updateHeight(consoleMessage);
      } else if (consoleMessage.startsWith('openUrl')) {
        await openUrlInNativeBrowser(consoleMessage);
      } else {
        SovendusBanner.reportError(
          'Unknown console message',
          consoleMessage,
          onError: widget.onError,
          trafficSourceNumber: widget.trafficSourceNumber,
          trafficMediumNumber: widget.trafficMediumNumber,
        );
      }
    } catch (e) {
      SovendusBanner.reportError(
        'Error processing console message',
        e,
        onError: widget.onError,
        trafficSourceNumber: widget.trafficSourceNumber,
        trafficMediumNumber: widget.trafficMediumNumber,
      );
    }
  }

  Future<void> openUrlInNativeBrowser(String consoleMessage) async {
    try {
      final urlString = consoleMessage.replaceAll('openUrl', '');
      if (urlString.isNotEmpty) {
        final url = Uri.parse(urlString);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.inAppBrowserView);
        } else {
          SovendusBanner.reportError(
            'Cannot launch URL',
            urlString,
            onError: widget.onError,
            trafficSourceNumber: widget.trafficSourceNumber,
            trafficMediumNumber: widget.trafficMediumNumber,
          );
        }
      }
    } catch (e) {
      SovendusBanner.reportError(
        'Error opening URL',
        e,
        onError: widget.onError,
        trafficSourceNumber: widget.trafficSourceNumber,
        trafficMediumNumber: widget.trafficMediumNumber,
      );
    }
  }

  void updateHeight(String consoleMessage) {
    try {
      final heightString = consoleMessage.replaceAll('height', '');
      final height = double.tryParse(heightString);

      if (height != null && webViewHeight != height && height > 100) {
        setState(() {
          webViewHeight = height;
          doneLoading = true;
        });
      }
    } catch (e) {
      SovendusBanner.reportError(
        'Error updating height',
        e,
        onError: widget.onError,
        trafficSourceNumber: widget.trafficSourceNumber,
        trafficMediumNumber: widget.trafficMediumNumber,
      );
    }
  }
}

class HtmlSanitizer {
  static String sanitize(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .replaceAll('`', '&#96;')
        .replaceAll('=', '&#x3D;')
        .replaceAll('(', '&#40;')
        .replaceAll(')', '&#41;')
        .replaceAll('[', '&#91;')
        .replaceAll(']', '&#93;')
        .replaceAll('{', '&#123;')
        .replaceAll('}', '&#125;')
        .replaceAll(';', '&#59;')
        .replaceAll(':', '&#58;')
        .replaceAll(',', '&#44;')
        .replaceAll('\\', '&#92;')
        .replaceAll('\n', '&#10;')
        .replaceAll('\r', '&#13;')
        .replaceAll('\t', '&#9;');
  }

  static String? sanitizeNullable(String? input) {
    return input != null ? sanitize(input) : null;
  }
}
