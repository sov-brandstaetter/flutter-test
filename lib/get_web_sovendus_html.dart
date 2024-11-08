import 'package:sovendus_voucher_network_and_checkout_benefits/sovendus_voucher_network_and_checkout_benefits.dart';

String getWebSovendusHtml({
  required double padding,
  required String backgroundColor,
  required SovendusCustomerData customerData,
  required int trafficSourceNumber,
  required int trafficMediumNumber,
  required int orderUnixTime,
  required String sessionId,
  required String orderId,
  required double netOrderValue,
  required String currencyCode,
  required String usedCouponCode,
}) {
  // update with component version number
  const versionNumber = '1.2.4';

  final paddingString = '$padding' 'px';
  return '''
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
                        window.top.postMessage({height: _body.clientHeight}, "${Uri.base.origin}");              
                      }).observe(_body);
                    
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
                        consumerSalutation: "${customerData.salutation ?? ""}",
                        consumerFirstName: "${customerData.firstName ?? ""}",
                        consumerLastName: "${customerData.lastName ?? ""}",
                        consumerEmail: "${customerData.email ?? ""}",
                        consumerPhone : "${customerData.phone ?? ""}",   
                        consumerYearOfBirth  : "${customerData.yearOfBirth ?? ""}",   
                        consumerStreet: "${customerData.street ?? ""}",
                        consumerStreetNumber: "${customerData.streetNumber ?? ""}",
                        consumerZipcode: "${customerData.zipcode ?? ""}",
                        consumerCity: "${customerData.city ?? ""}",
                        consumerCountry: "${customerData.country ?? ""}",
                    };
                </script>
                <script type="text/javascript" src="https://api.sovendus.com/sovabo/common/js/flexibleIframe.js" async=true></script>
            </body>
        </html>
    ''';
}
