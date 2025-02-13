import 'package:flutter/material.dart';

class DialogManager {
  static final DialogManager instance = DialogManager._();
  DialogManager._();

  BuildContext? _context;
  bool _isDialogVisible = false;

  void init(BuildContext context) {
    _context = context;
  }

  BuildContext? get context => _context;
  bool get isDialogVisible => _isDialogVisible;

  void showCustomDialog(Widget dialog) {
    if (_context == null || _isDialogVisible) return;

    _isDialogVisible = true;
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: dialog,
      ),
    );
  }

  void updateDialog(Widget dialog) {
    if (_context == null || !_isDialogVisible) return;
    
    hideDialog();
    showCustomDialog(dialog);
  }

  void hideDialog() {
    if (_context == null || !_isDialogVisible) return;

    _isDialogVisible = false;
    if (_context!.mounted) {
      Navigator.of(_context!, rootNavigator: true).pop();
    }
  }
}
