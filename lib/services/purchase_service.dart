import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  static const _kProductId = 'com.sammay.cardwizz.premium_monthly';
  
  final _inAppPurchase = InAppPurchase.instance;

  Future<bool> isPremium() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return false;
    }

    final purchases = await _inAppPurchase.queryProductDetails({_kProductId});
    // Check subscription status
    return false; // TODO: Implement proper check
  }

  Future<void> purchasePremium() async {
    final ProductDetailsResponse response = 
        await _inAppPurchase.queryProductDetails({_kProductId});
    
    if (response.productDetails.isEmpty) {
      throw 'Product not found';
    }

    final PurchaseParam purchaseParam = 
        PurchaseParam(productDetails: response.productDetails.first);
    
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }
}
