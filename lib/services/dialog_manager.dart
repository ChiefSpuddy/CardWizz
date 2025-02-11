import 'package:flutter/material.dart';

class DialogManager {
  static final DialogManager instance = DialogManager._();
  DialogManager._();
  
  BuildContext? _context;
  bool _isDialogVisible = false;

  // Add this getter
  BuildContext? get context => _context;

  void init(BuildContext context) {
    _context = context;
  }

  bool get isDialogVisible => _isDialogVisible;

  void showCustomDialog(Widget dialog) {
    if (_context == null) {
      print('Warning: DialogManager not initialized with context');
      return;  // Early return instead of null check
    }
    
    if (_isDialogVisible) {
      hideDialog();
    }

    _isDialogVisible = true;
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => dialog,
    );
  }

  Future<void> showProgressDialog(BuildContext context, Widget dialog) async {
    if (_isDialogVisible) {
      hideDialog();
    }

    _isDialogVisible = true;
    return showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        _context = dialogContext;
        return WillPopScope(
          onWillPop: () async => false,
          child: dialog,
        );
      },
    );
  }

  // Add method to update existing dialog
  void updateDialog(Widget dialog) {
    if (_isDialogVisible && _context != null) {
      Navigator.of(_context!, rootNavigator: true).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, _, __) => WillPopScope(
            onWillPop: () async => false,
            child: dialog,
          ),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  void hideDialog() {
    if (_isDialogVisible && _context != null) {
      Navigator.of(_context!, rootNavigator: true).pop();
      _isDialogVisible = false;
      _context = null;
    }
  }
}
