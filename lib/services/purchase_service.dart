import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';  // Add this for StreamSubscription

class PurchaseService extends ChangeNotifier {
  static const _kProductId = 'com.sammay.cardwizz.premium_monthly';
  
  final _inAppPurchase = InAppPurchase.instance;
  bool _isLoading = false;
  String? _error;
  bool _isPremium = false;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _isPremium;

  Future<void> initialize() async {
    try {
      // Load premium status from storage first
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('is_premium') ?? false;

      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        _error = 'Store not available';
        notifyListeners();
        return;
      }

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );

      // For development/testing
      if (kDebugMode) {
        print('Store is available');
        // Uncomment to test premium features
        // _isPremium = true;
        // notifyListeners();
      }

      // Restore purchases on initialization
      await restorePurchases();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _error = 'Failed to restore purchases: $e';
      notifyListeners();
    }
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoading = true;
        notifyListeners();
      } else {
        _isLoading = false;
        if (purchaseDetails.status == PurchaseStatus.error) {
          _error = purchaseDetails.error?.message ?? 'Purchase failed';
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          // Verify purchase
          final valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _isPremium = true;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_premium', true);
          }
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        
        notifyListeners();
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Add your purchase verification logic here
    // For now, we'll just verify the productID
    return purchaseDetails.productID == _kProductId;
  }

  Future<void> purchasePremium() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if store is available
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        throw 'Store not available';
      }

      // Query product details first
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails({_kProductId});
      
      if (response.productDetails.isEmpty) {
        throw 'Product not found';
      }

      final PurchaseParam purchaseParam = 
          PurchaseParam(productDetails: response.productDetails.first);
      
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw _error!;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  // Add method to clear premium status (for testing)
  Future<void> clearPremiumStatus() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_premium');
      _isPremium = false;
      notifyListeners();
    }
  }
}
