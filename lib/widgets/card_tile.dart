// Use generic terms in UI elements
'Add to Collection'  // Instead of 'Add Pokemon'
'Card Details'      // Instead of 'Pokemon Details'
'Set Number'        // Instead of 'Dex Number'

      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Image.network(
                    card.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                  ),
                ),
              ),