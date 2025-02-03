import 'package:flutter/material.dart';

class DialogManager {
  static DialogManager? _instance;
  bool _isDialogVisible = false;
  BuildContext? _dialogContext;

  static DialogManager get instance {
    _instance ??= DialogManager._();
    return _instance!;
  }

  DialogManager._();

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
        _dialogContext = dialogContext;
        return WillPopScope(
          onWillPop: () async => false,
          child: dialog,
        );
      },
    );
  }

  void hideDialog() {
    if (_isDialogVisible && _dialogContext != null) {
      Navigator.of(_dialogContext!, rootNavigator: true).pop();
      _isDialogVisible = false;
      _dialogContext = null;
    }
  }

  bool get isDialogVisible => _isDialogVisible;
}
