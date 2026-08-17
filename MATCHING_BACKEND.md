# Peleka Customer App – Backend Match

This customer app is matched to the updated Peleka Next.js backend.

## Backend base URL

Build with:

```bash
flutter run --dart-define=API_BASE_URL=https://peleka-server.vercel.app
```

## Matched API capabilities

- Email/password or phone/password authentication; phone OTP has been removed.
- Pickup location search through `GET /api/locations/search`.
- Current-location pickup through device GPS plus `GET /api/locations/reverse`.
- Delivery place search uses the same location service.
- Distance-only shipment quotes; the customer app no longer sends parcel weight for pricing.
- Standard customers are sent to Paypack payment after creating a shipment.
- Premier customers can create shipments without immediate payment.
- Premier shipment balances are visible through `GET /api/me/billing`.
- Premier shipment history is available in the Billing & shipment history screen.
- Premier shipments can be paid later from the shipment detail screen after delivery.

## Google Places configuration

The backend must have `GOOGLE_MAPS_API_KEY` (or `GOOGLE_PLACES_API_KEY`) configured. The customer app does not contain a Google API key; all Places and reverse-geocoding requests go through the authenticated Peleka backend.

## Device location permissions

The existing Flutter Android/iOS project must declare the normal Geolocator location permissions in its platform projects. This ZIP contains the provided `lib/` and `pubspec.yaml`, so Android/iOS platform files were not modified here.

## Payment provider

The customer app calls the backend Paypack payment endpoint. It does not perform Paypack authentication or expose Paypack credentials.
