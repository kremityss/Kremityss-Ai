/// Public Krem|Ai links and build-time payment configuration.
/// Payment URLs are intended for the one-time lifetime key only.
class DevHubLinks {
  static const siteUrl = 'https://kremcheats.com';
  static const portalUrl = 'https://portal.kremcheats.com';
  static const freeKeyUrl = '$siteUrl/api/free-key';

  /// First-party KremCheats validation proxy. The app never contains a seller key.
  static const licenseValidationUrl = String.fromEnvironment(
    'LICENSE_VALIDATION_URL',
    defaultValue: '$siteUrl/api/devhub/validate-key',
  );
  static const productId = String.fromEnvironment(
    'LICENSE_PRODUCT_ID',
    defaultValue: 'Krem|Ai',
  );

  static const premiumUrl = String.fromEnvironment(
    'PREMIUM_URL',
    defaultValue: '$siteUrl/#lifetime',
  );
  static const cashAppUrl = String.fromEnvironment(
    'CASHAPP_URL',
    defaultValue: 'https://cash.app/\$DevHubAi',
  );
  static const paypalUrl = String.fromEnvironment(
    'PAYPAL_URL',
    defaultValue: '',
  );
  static const bitcoinUrl = String.fromEnvironment(
    'BITCOIN_URL',
    defaultValue:
        'bitcoin:bc1qvx6dwtplwkvtqqpktyzgezxxxrfve7leq050nf',
  );

  static String paymentUrl(String configuredUrl) =>
      configuredUrl.isNotEmpty ? configuredUrl : premiumUrl;
}
