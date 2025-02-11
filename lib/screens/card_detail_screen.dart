
Future<void> _showCreateBinderDialog(BuildContext context, String cardId) async {
  await showDialog<String>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true, // Add this line
    builder: (BuildContext context) => CreateBinderDialog(cardToAdd: cardId),
  );
}

// In your build method where you show the dialog:
onPressed: () => _showCreateBinderDialog(context, card.id),
