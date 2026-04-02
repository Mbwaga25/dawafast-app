import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:app/core/theme.dart';

const String requestInstantCallMutation = r'''
  mutation RequestInstantCall($appointmentId: ID!) {
     requestInstantCall(appointmentId: $appointmentId) {
       success
       message
     }
  }
''';

class InstantCallButton extends StatelessWidget {
  final String appointmentId;

  const InstantCallButton({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: gql(requestInstantCallMutation),
        onCompleted: (dynamic result) {
          final success = result?['requestInstantCall']?['success'] ?? false;
          final msg = result?['requestInstantCall']?['message'] ?? '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? 'Instant call requested' : msg)),
          );
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${error?.graphqlErrors.first.message ?? 'Unknown error'}')),
          );
        },
      ),
      builder: (runMutation, result) {
        final loading = result?.isLoading ?? false;
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue, // matching theme
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.flash_on, size: 20),
          label: const Text('Instant Call', style: TextStyle(fontSize: 14)),
          onPressed: loading ? null : () => runMutation({'appointmentId': appointmentId}),
        );
      },
    );
  }
}
