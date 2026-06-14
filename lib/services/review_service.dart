import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  // call this after a user completes a positive action
  // like successfully making a call or sending a message
  static Future<void> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      // silently fail — never crash because of a review prompt
    }
  }

  // opens Play Store / App Store page directly
  static Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: 'YOUR_APP_STORE_ID', // add when you publish to App Store
      );
    } catch (e) {
      // silently fail
    }
  }
}