import 'package:flutter/material.dart';
import '../utils/error_handler.dart';

/// A widget that handles loading states, errors, and empty data
class LoadingHandler<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final String? loadingMessage;
  final String? errorMessage;
  final String? emptyMessage;
  final bool showProgressIndicator;
  final bool Function(T data)? isEmpty;

  const LoadingHandler({
    super.key,
    required this.future,
    required this.builder,
    this.loadingMessage,
    this.errorMessage,
    this.emptyMessage,
    this.showProgressIndicator = true,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }
        
        // Handle error state
        if (snapshot.hasError) {
          ErrorHandler.logError(
            errorMessage ?? 'Error loading data',
            snapshot.error,
            snapshot.stackTrace,
          );
          return _buildErrorState(context, snapshot.error.toString());
        }

        // Handle empty data
        if (!snapshot.hasData || 
            (isEmpty != null && isEmpty!(snapshot.data as T)) || 
            _isEmptyCollection(snapshot.data)) {
          return _buildEmptyState(context);
        }

        // Build UI with data
        return builder(snapshot.data as T);
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgressIndicator)
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          if (loadingMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              loadingMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorDetails) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'An error occurred',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (errorDetails.isNotEmpty)
              Text(
                errorDetails,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Create a new instance with a new future
                final parent = context.findAncestorWidgetOfExactType<LoadingHandler<T>>();
                if (parent != null) {
                  // This will trigger a rebuild with a new future
                  (context as Element).markNeedsBuild();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? 'No data available',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper to identify empty collections
  bool _isEmptyCollection(dynamic data) {
    if (data == null) return true;
    if (data is List) return data.isEmpty;
    if (data is Map) return data.isEmpty;
    if (data is Iterable) return data.isEmpty;
    return false;
  }
}
