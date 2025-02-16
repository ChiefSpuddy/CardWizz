import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/price_update_dialog.dart';

class DialogManager {
  static final DialogManager instance = DialogManager._();
  DialogManager._();

  final _dialogController = StreamController<void>.broadcast();
  Stream<void> get dialogUpdates => _dialogController.stream;

  BuildContext? _context;
  bool _isDialogShowing = false;

  // Add context getter
  BuildContext? get context => _context;

  // Add initialization method
  void init(BuildContext context) {
    _context = context;
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  // Add method to update dialog
  void updateDialog(int current, int total) {
    if (_isDialogShowing) {
      _dialogController.add(null);
    } else {
      showPriceUpdateDialog(current, total);
    }
  }

  // Add generic custom dialog method
  Future<T?> showCustomDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) async {
    if (_context == null) return null;

    return showDialog<T>(
      context: _context!,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  void showPriceUpdateDialog(int current, int total) {
    if (_context == null) return;

    if (!_isDialogShowing) {
      _isDialogShowing = true;
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: PriceUpdateDialog(
            key: ValueKey('$current-$total'), // Add this line
            current: current,
            total: total,
          ),
        ),
      ).then((_) {
        _isDialogShowing = false;
      });
    } else {
      // Force dialog rebuild by replacing it
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!, rootNavigator: true).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, _, __) => WillPopScope(
              onWillPop: () async => false,
              child: PriceUpdateDialog(
                key: ValueKey('$current-$total'), // Add this line
                current: current,
                total: total,
              ),
            ),
            opaque: false,
          ),
        );
      }
    }
  }

  // Add this method to force dialog rebuild
  void forceUpdate() {
    if (_context != null && _isDialogShowing) {
      _dialogController.add(null);
    }
  }

  void updateProgress(int current, int total) {
    _dialogController.add(null);
  }

  void hideDialog() {
    if (_context != null && _isDialogShowing) {
      Navigator.of(_context!, rootNavigator: true).pop();
      _isDialogShowing = false;
    }
  }

  void dispose() {
    _dialogController.close();
  }
}
