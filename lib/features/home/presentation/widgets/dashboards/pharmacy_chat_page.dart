import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:app/features/appointments/presentation/pages/chat_page.dart';

class PharmacyChatPage extends ConsumerStatefulWidget {
  const PharmacyChatPage({super.key});

  @override
  ConsumerState<PharmacyChatPage> createState() => _PharmacyChatPageState();
}

class _PharmacyChatPageState extends ConsumerState<PharmacyChatPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await ref.read(userRepositoryProvider).searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startChat(String userId) async {
    try {
      final appointmentId = await ref.read(appointmentRepositoryProvider).startDirectChat(userId);
      if (appointmentId != null) {
        if (mounted) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(appointmentId: appointmentId)));
        }
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Messaging', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryTeal),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients or doctors...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: _performSearch,
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('Start a conversation with anyone', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                          child: Text(user['firstName']?[0] ?? '?', style: const TextStyle(color: AppTheme.primaryTeal)),
                        ),
                        title: Text('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'),
                        subtitle: Text(user['email'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.message_outlined, color: AppTheme.primaryTeal),
                          onPressed: () => _startChat(user['id']),
                        ),
                        onTap: () => _startChat(user['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
