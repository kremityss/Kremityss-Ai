# DevHub KeyAuth and payment integration

The Flutter app keeps KeyAuth secrets on the website. It sends a premium key to the configured validation URL and never calls KeyAuth directly.

## Validation endpoint

Build the app with:

```bash
flutter build apk --release \
  --dart-define=KEYAUTH_VALIDATION_URL=https://kremcheats.com/api/devhub/validate-key \
  --dart-define=KEYAUTH_PRODUCT_ID=devhub-premium
```

The website endpoint must accept a JSON `POST` body:

```json
{"key":"USER_KEY","product":"devhub-premium"}
```

It should validate the key server-side with KeyAuth and return JSON. A successful response is:

```json
{"valid":true,"premium":true,"status":"active","message":"Premium active"}
```

An invalid response should be HTTP 200 or 4xx with:

```json
{"valid":false,"premium":false,"message":"Invalid or expired key"}
```

The endpoint should apply HTTPS, rate limiting, input validation, and origin-independent authentication rules. Do not place a KeyAuth application secret in the Flutter app.

## Public links and lifetime-key payment buttons

Cash App Pay, PayPal, and Bitcoin are intended only for a **one-time lifetime DevHub Premium key**. Do not attach these payment methods to subscriptions, recurring billing, or free-key issuance. After confirmed payment, the website should issue one lifetime KeyAuth entitlement for the purchased product.

The app includes the free-key page:

`https://kremcheats.com/free-key/complete`

The current 24-hour offer is served by LootDest/LootLabs at `https://lootdest.org/s?xcf9pE8g`. If it shows a white page or “Please disable your Adblocker,” that is the offer provider’s anti-bot check. The user must open it in a normal browser, temporarily disable ad-blocking or strict tracking protection for LootDest/LootLabs, avoid a VPN or blocked network, and press the page’s refresh link. The app cannot bypass that provider-side check or generate the provider’s key locally.

Payment buttons use the premium site by default. Set direct payment links when they are available:

```bash
--dart-define=PREMIUM_URL=https://kremcheats.com/premium
--dart-define=CASHAPP_URL=https://cash.app/$YOUR_CASHAPP_TAG
--dart-define=PAYPAL_URL=https://paypal.me/YOUR_PAYPAL_NAME
--dart-define=BITCOIN_URL=https://kremcheats.com/pay/bitcoin
```

The Bitcoin button should point to a website checkout page or invoice flow rather than embedding a wallet address in the app. This lets the site record payment and issue a KeyAuth entitlement. If your payment processor supports webhooks, the website should verify the payment server-side before activating the key.

The current app defaults supplied for lifetime-key payments are Cash App `$DevHubAi` and Bitcoin address `bc1qvx6dwtplwkvtqqpktyzgezxxxrfve7leq050nf`. A Lightning invoice was also provided and is available through the Lightning button. Lightning invoices commonly expire or are single-use, so replace the build-time `LIGHTNING_URL` value with a fresh invoice or a server-generated invoice page before distributing a production build.

If a direct method URL is not configured, its button safely falls back to `PREMIUM_URL`, so no fake Cash App handle, PayPal account, or Bitcoin address is shipped.

## PayPal Hosted Button

The supplied PayPal Hosted Button is saved as [`docs/paypal-hosted-button.html`](paypal-hosted-button.html). Place that snippet on the premium checkout page at `PREMIUM_URL`. It uses hosted button ID `4HHSUDHYXBVWE`, USD currency, and Venmo funding. The app's PayPal button should link to that checkout page rather than embedding PayPal credentials in the mobile binary.

## Automatic 24-hour free-key flow

The app and website now use `https://kremcheats.com/api/free-key`. The backend creates a one-task LootLabs content-locker link, attaches a private claim token, and redirects the user to the offer. After LootLabs calls the configured postback, the backend creates a one-day KeyAuth license using the private Seller Key and stores the result in Cloudflare KV for the claim status endpoint.

To enable the final provider callback, configure LootLabs Advanced > Postback URL as:

`https://kremcheats.com/api/lootlabs/postback?click_id={CLICK_ID}&ip={IP}&unique_id={UNIQUE_ID}`

The postback setting is controlled in the LootLabs creator panel and cannot be configured through the public link-creation API. Until it is enabled, users can complete the offer but the claim remains pending. The backend rejects missing or duplicate postbacks and keeps API credentials server-side.
