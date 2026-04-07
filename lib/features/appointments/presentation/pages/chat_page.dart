import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app/core/theme.dart';
import 'package:app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:app/features/appointments/data/models/chat_model.dart';
import 'package:app/features/auth/data/repositories/user_repository.dart';
import 'package:app/core/services/location_service.dart';
import 'package:app/core/services/media_service.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String appointmentId;
  const ChatPage({super.key, required this.appointmentId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  ChatMessage? _replyingTo;

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.appointmentId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final userId = currentUserAsync.value?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryTeal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Start a conversation...'));
                }
                
                // Scroll to bottom on new messages
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      isMe: message.isMe(userId),
                      onReply: _onMessageReply,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildReplyPreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_replyingTo!.sender.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 12),
                ),
                Text(
                  _replyingTo!.message.length > 50 
                      ? '${_replyingTo!.message.substring(0, 50)}...' 
                      : _replyingTo!.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryTeal),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFFF1F8E9), child: Icon(Icons.location_on, color: Colors.green)),
                          title: const Text('Share Location'),
                          onTap: () {
                            Navigator.pop(context);
                            _sendLocation();
                          },
                        ),
                        ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.image, color: Colors.blue)),
                          title: const Text('Send Photo'),
                          onTap: () {
                            Navigator.pop(context);
                            _sendPhoto(false);
                          },
                        ),
                        ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFFFFF3E0), child: Icon(Icons.camera_alt, color: Colors.orange)),
                          title: const Text('Take Camera'),
                          onTap: () {
                            Navigator.pop(context);
                            _sendPhoto(true);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            _isSending
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryTeal),
                    onPressed: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendLocation() async {
    setState(() => _isSending = true);
    try {
      final pos = await LocationService().getCurrentPosition();
      if (pos != null) {
        String content = '[LOCATION]:${pos.latitude},${pos.longitude}';
        
        if (_replyingTo != null) {
          final snippet = _replyingTo!.message.length > 30 
              ? '${_replyingTo!.message.substring(0, 30)}...' 
              : _replyingTo!.message;
          content = '[REPLY:${_replyingTo!.id}:$snippet]$content';
        }

        await ref.read(appointmentRepositoryProvider).sendMessage(widget.appointmentId, content);
        setState(() => _replyingTo = null);
        ref.invalidate(chatMessagesProvider(widget.appointmentId));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendPhoto(bool fromCamera) async {
    setState(() => _isSending = true);
    try {
      final xFile = fromCamera 
          ? await MediaService().capturePhoto() 
          : await MediaService().pickFromGallery();
          
      if (xFile != null) {
        // Read bytes in a cross-platform way (works on Web and Mobile)
        final bytes = await xFile.readAsBytes();
        
        // Use the new upload method instead of Base64 strings
        await ref.read(appointmentRepositoryProvider).uploadChatMedia(
          widget.appointmentId, 
          bytes, 
          xFile.name,
        );
        
        setState(() => _replyingTo = null);
        ref.invalidate(chatMessagesProvider(widget.appointmentId));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendMessage() async {
    final rawContent = _messageController.text.trim();
    if (rawContent.isEmpty) return;

    String content = rawContent;
    if (_replyingTo != null) {
      final snippet = _replyingTo!.message.length > 30 
          ? '${_replyingTo!.message.substring(0, 30)}...' 
          : _replyingTo!.message;
      content = '[REPLY:${_replyingTo!.id}:$snippet]$content';
    }

    setState(() => _isSending = true);
    try {
      await ref.read(appointmentRepositoryProvider).sendMessage(widget.appointmentId, content);
      _messageController.clear();
      setState(() => _replyingTo = null);
      ref.invalidate(chatMessagesProvider(widget.appointmentId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessageReply(ChatMessage message) {
    setState(() => _replyingTo = message);
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Function(ChatMessage) onReply;

  const _MessageBubble({required this.message, required this.isMe, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onReply(message);
        return false; // Don't actually dismiss, just trigger reply
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.reply, color: AppTheme.primaryTeal, size: 24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: () => _showBubbleMenu(context),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Text(message.sender.name, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              
              if (message.repliedToSnippet != null)
                _buildReplyContext(context),

              _buildContent(context),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 12, color: AppTheme.primaryTeal),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBubbleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.reply, color: AppTheme.primaryTeal),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                // Clipboard integration
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageCard(context);
      case MessageType.location:
        return _buildLocationCard(context);
      default:
        return _buildTextCard(context);
    }
  }

  Widget _buildReplyContext(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
      margin: const EdgeInsets.only(bottom: 0, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(left: BorderSide(color: AppTheme.primaryTeal.withOpacity(0.5), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Replied Message', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
          Text(
            message.repliedToSnippet!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primaryTeal : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(message.repliedToSnippet != null ? 0 : 16),
          topRight: Radius.circular(message.repliedToSnippet != null ? 0 : 16),
          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        message.message,
        style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    final url = message.imageUrl;
    if (url == null) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: message.isBase64Image
            ? Image.memory(
                base64Decode(url),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
     final coords = message.locationData?.split(',') ?? ['0', '0'];
     final lat = coords[0];
     final lng = coords[1];

     return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primaryTeal : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.map_outlined, size: 48, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: isMe ? Colors.white : AppTheme.primaryTeal),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Location Shared',
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Lat: $lat, Lng: $lng',
            style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
          ),
        ],
      ),
    );
  }
}
