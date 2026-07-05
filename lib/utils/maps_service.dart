/// External-intent helper that launches Google Maps with a route to a
/// saved spot.
///
/// Uses the universal Google Maps URL so the native app opens when
/// installed, otherwise the device browser is used as a fallback.
library;

import 'package:url_launcher/url_launcher.dart';

class MapsService {
  MapsService._();
  static final MapsService instance = MapsService._();

  /// Opens Google Maps directions to [lat], [lng].
  ///
  /// The URL omits the origin so Maps uses the device's current location
  /// automatically.
  Future<bool> openDirections(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    return _launch(uri);
  }

  /// Opens an arbitrary maps URL (manually pasted by the user).
  Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!uri.hasScheme) {
      return _launch(Uri.parse('https://www.google.com/maps/dir/?api=1'));
    }
    return _launch(uri);
  }

  Future<bool> _launch(Uri uri) async {
    try {
      // Try the native app first (mode prefersExternalApplication).
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // Fall back to in-app browser.
      return launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      return false;
    }
  }
}
