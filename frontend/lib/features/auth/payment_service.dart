import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';

class PaymentService {
  /// Initiates the Stripe checkout flow for upgrading to Nomad (Pro)
  static Future<bool> upgradePro(String userId) async {
    try {
      print('PaymentService: Creating checkout for user $userId');
      
      final response = await ApiClient.post('payments/create-checkout-session', {
        'user_id': userId,
      });

      if (response != null && response['checkoutUrl'] != null) {
        final checkoutUrl = response['checkoutUrl'] as String;
        print('PaymentService: Opening checkout URL: $checkoutUrl');
        
        final uri = Uri.parse(checkoutUrl);
        
        // Try to launch without checking canLaunchUrl first
        // canLaunchUrl often returns false for complex URLs on Android
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          
          if (!launched) {
            // Fallback: try with inAppWebView mode
            print('PaymentService: Trying inAppWebView mode');
            await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
            );
          }
          return true;
        } catch (e) {
          print('PaymentService: Launch error: $e');
          return false;
        }
      } else {
        print('PaymentService: No checkout URL in response');
        return false;
      }
    } catch (e) {
      print('PaymentService Error: $e');
      return false;
    }
  }
}

