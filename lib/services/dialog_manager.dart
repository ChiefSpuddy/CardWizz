import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/price_update_dialog.dart';  // Add this import

class DialogManager {
  static final DialogManager instance = DialogManager._();
  DialogManager._();

  BuildContext? _context;
  bool _isDialogVisible = false;
  Widget? _dialogContent;
  final _dialogUpdateController = StreamController<void>.broadcast();

  void init(BuildContext context) {
    _context = context;
  }

  BuildContext? get context => _context;
  bool get isDialogVisible => _isDialogVisible;
  Stream<void> get dialogUpdates => _dialogUpdateController.stream;

  void showCustomDialog(Widget dialog) {
    if (_context == null || _isDialogVisible) return;

    _isDialogVisible = true;
    _dialogContent = dialog;
    showDialog(
      context: _context!,
      barrierDismissible: false,  // Changed to false for better UX during updates
      builder: (context) => WillPopScope(
        onWillPop: () async {
          if (_dialogContent is PriceUpdateDialog) {  // Add type check
            final updateDialog = _dialogContent as PriceUpdateDialog;
            return updateDialog.current >= updateDialog.total;  // Only allow dismissal if complete
          }
          return true;  // Allow dismissal for other dialog types
        },
        child: StreamBuilder<void>(
          stream: _dialogUpdateController.stream,
          builder: (context, snapshot) {
            return _dialogContent!;
          },
        ),
      ),
    );
  }

  void updateDialog(Widget dialog) {
    if (_context == null || !_isDialogVisible) return;
    
    if (_context!.mounted) {
      _dialogContent = dialog;
      _dialogUpdateController.add(null);
    }
  }

  void hideDialog() {
    if (_context == null || !_isDialogVisible) return;

    _isDialogVisible = false;
    if (_context!.mounted) {
      Navigator.of(_context!, rootNavigator: true).pop();
    }
  }

  void dispose() {
    _dialogUpdateController.close();
  }
}
