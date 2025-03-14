import '../services/logging_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';  // Add this for StreamSubscription

typedef PurchaseStatusCallback = void Function(bool isPurchaseInProgress);

class PurchaseService extends ChangeNotifier {
  static const _kProductId = '1Month';  // Updated product ID
  static const kDisplayPrice = '\$0.99'; // Updated from $1.99 to $0.99
  static const kDisplayPriceGBP = '£0.99'; // Updated from £1.99 to £0.99
  static bool debugForcePremium = false;  // Add this flag
  
  final _inAppPurchase = InAppPurchase.instance;
  bool _isLoading = false;
  String? _error;
  bool _isPremium = false;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool _isPurchaseInProgress = false;
  final List<PurchaseStatusCallback> _purchaseListeners = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium {
    if (kDebugMode && debugForcePremium) {
      return true;
    }
    return _isPremium;
  }

  bool get isPurchaseInProgress => _isPurchaseInProgress;

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
        LoggingService.debug('Store is available');
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

  // Improved handler for purchase updates with explicit purchase in progress state management
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoading = true;
        _isPurchaseInProgress = true;
        _notifyPurchaseListeners();
        notifyListeners();
      } else {
        // Purchase is no longer pending, clear states
        _isLoading = false;
        _isPurchaseInProgress = false;
        
        if (purchaseDetails.status == PurchaseStatus.error) {
          _error = purchaseDetails.error?.message ?? 'Purchase failed';
          LoggingService.debug('Purchase error: ${_error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
          // Verify purchase
          final valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _isPremium = true;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_premium', true);
            LoggingService.debug('Premium status activated: $_isPremium');
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          LoggingService.debug('Purchase was canceled by user');
        }
        
        // Always complete purchases to avoid orphaned transactions
        if (purchaseDetails.pendingCompletePurchase) {
          try {
            await _inAppPurchase.completePurchase(purchaseDetails);
            LoggingService.debug('Purchase completed: ${purchaseDetails.productID}');
          } catch (e) {
            LoggingService.debug('Error completing purchase: $e');
          }
        }
        
        _notifyPurchaseListeners();
        notifyListeners();
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Add your purchase verification logic here
    // For now, we'll just verify the productID
    return purchaseDetails.productID == _kProductId;
  }

  // Merged the two purchasePremium methods into one implementation
  Future<bool?> purchasePremium() async {
    if (_isLoading) return false;

    try {
      _isLoading = true;
      _error = null;
      _isPurchaseInProgress = true;
      _notifyPurchaseListeners();
      notifyListeners();

      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        throw 'Store not available';
      }

      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails({_kProductId});
      
      if (response.productDetails.isEmpty) {
        throw 'Product not found';
      }

      final productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      // Use buyNonConsumable for subscriptions
      final bool purchaseStarted = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!purchaseStarted) {
        // Update purchase status when purchase fails to start
        _isPurchaseInProgress = false;
        _notifyPurchaseListeners();
        throw 'Purchase failed to initialize';
      }
      
      // Add a timeout to automatically clear purchase in progress state after a few seconds
      // This helps handle cases where the purchase stream doesn't emit an event
      Timer(const Duration(seconds: 30), () {
        if (_isPurchaseInProgress) {
          _isPurchaseInProgress = false;
          _isLoading = false;
          _notifyPurchaseListeners();
          notifyListeners();
          LoggingService.debug('Purchase in progress state automatically cleared after timeout');
        }
      });
      
      // Return null for now - actual success/failure will be determined by the purchase stream
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isPurchaseInProgress = false;
      _notifyPurchaseListeners();
      notifyListeners();
      return false;
    }
  }

  void _notifyPurchaseListeners() {
    for (final listener in _purchaseListeners) {
      listener(_isPurchaseInProgress);
    }
  }

  void addPurchaseListener(PurchaseStatusCallback listener) {
    _purchaseListeners.add(listener);
  }

  void removePurchaseListener(PurchaseStatusCallback listener) {
    _purchaseListeners.remove(listener);
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

  // Add debug methods
  void enableTestMode() {
    if (kDebugMode) {
      debugForcePremium = true;
      notifyListeners();
      LoggingService.debug('DEBUG: Premium test mode enabled');
    }
  }

  void disableTestMode() {
    if (kDebugMode) {
      debugForcePremium = false;
      notifyListeners();
      LoggingService.debug('DEBUG: Premium test mode disabled');
    }
  }
}
