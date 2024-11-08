// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:material_3_demo/get_web_sovendus_html.dart';
import 'package:sovendus_voucher_network_and_checkout_benefits/sovendus_voucher_network_and_checkout_benefits.dart';

class WebSovendusBanner extends StatefulWidget {
  const WebSovendusBanner({
    super.key,
    required this.trafficSourceNumber,
    required this.trafficMediumNumber,
    required this.orderUnixTime,
    required this.sessionId,
    required this.orderId,
    required this.netOrderValue,
    required this.currencyCode,
    required this.usedCouponCode,
    required this.customerData,
    required this.maxHeight,
    this.padding = 0,
    this.backgroundColor = '#fff',
  });

  final int trafficSourceNumber;
  final int trafficMediumNumber;
  final int orderUnixTime;
  final String sessionId;
  final String orderId;
  final double netOrderValue;
  final String currencyCode;
  final String usedCouponCode;
  final SovendusCustomerData customerData;
  final double padding;
  final String backgroundColor;
  final double maxHeight;

  @override
  State<WebSovendusBanner> createState() => _WebSovendusBannerState();
}

class _WebSovendusBannerState extends State<WebSovendusBanner> {
  double _webViewHeight = 348;

  String get _sovendusHtml => getWebSovendusHtml(
        padding: widget.padding,
        backgroundColor: widget.backgroundColor,
        customerData: widget.customerData,
        trafficSourceNumber: widget.trafficSourceNumber,
        trafficMediumNumber: widget.trafficMediumNumber,
        orderUnixTime: widget.orderUnixTime,
        sessionId: widget.sessionId,
        orderId: widget.orderId,
        netOrderValue: widget.netOrderValue,
        currencyCode: widget.currencyCode,
        usedCouponCode: widget.usedCouponCode,
      );

  @override
  void initState() {
    // Used for fetching full height from the iFrame
    window.addEventListener(
      'message',
      (event) {
        if (event is MessageEvent) {
          final height = double.tryParse(
            (event.data as Map)['height'].toString(),
          );

          if (height != null && mounted) {
            _updateHeight(height);
          }
        }
      },
    );
    super.initState();
  }

  void _updateHeight(double height) {
    if (_webViewHeight != height && height > 100) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _webViewHeight =
              height < widget.maxHeight ? height : widget.maxHeight;
        });
      });
    }
  }

  bool _isNotBlacklistedUrl(Uri uri) {
    return uri.path != '/banner/api/banner' &&
        !uri.path.startsWith('/app-list/') &&
        uri.path != 'blank';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _webViewHeight,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(data: _sovendusHtml),
        initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          supportZoom: false,
        )),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          if (navigationAction.request.url != null &&
              _isNotBlacklistedUrl(
                navigationAction.request.url!,
              )) {
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
