import 'dart:convert';

enum MessageType { text, image, location }

class ChatMessage {
  final String id;
  final String message;
  final DateTime timestamp;
  final ChatUser sender;
  final MessageType? _type;
  final String? repliedToMessageId;
  final String? repliedToSnippet;
  final String? remoteImageUrl;
  final DateTime? expiresAt;

  ChatMessage({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.sender,
    MessageType? type = MessageType.text,
    this.repliedToMessageId,
    this.repliedToSnippet,
    this.remoteImageUrl,
    this.expiresAt,
  }) : _type = type;

  MessageType get type => _type ?? MessageType.text;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String rawContent = json['message'] ?? '';
    String? replyId;
    String? replySnippet;
    String content = rawContent;

    // Parse Reply Metadata: [REPLY:id:snippet]
    if (content.startsWith('[REPLY:')) {
      final endBracketIndex = content.indexOf(']');
      if (endBracketIndex != -1) {
        final metadata = content.substring(7, endBracketIndex);
        final parts = metadata.split(':');
        if (parts.length >= 2) {
          replyId = parts[0];
          replySnippet = parts.sublist(1).join(':');
          content = content.substring(endBracketIndex + 1);
        }
      }
    }

    MessageType computedType = MessageType.text;
    if (content.startsWith('[LOCATION]:')) {
      computedType = MessageType.location;
    } else if (content.startsWith('[IMAGE]:')) {
      computedType = MessageType.image;
    }

    final id = json['id']?.toString() ?? 'unknown';
    final imageUrl = json['imageUrl'] ?? json['image_url'] ?? json['image'];
    
    // Debug log to help track image data issues
    if (json.containsKey('imageUrl') || json.containsKey('image_url') || json.containsKey('image')) {
      print('DEBUG: ChatMessage $id has image data: $imageUrl');
    }

    return ChatMessage(
      id: id,
      message: content,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      sender: ChatUser.fromJson(json['user'] ?? {}),
      type: imageUrl != null ? MessageType.image : computedType,
      repliedToMessageId: replyId,
      repliedToSnippet: replySnippet,
      remoteImageUrl: imageUrl?.toString(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  bool isMe(String currentUserId) => sender.id == currentUserId;

  bool get isBase64Image => type == MessageType.image && (imageUrl?.startsWith('data:image') ?? false || ! (imageUrl?.startsWith('http') ?? true));
  
  String? get locationData => type == MessageType.location ? message.replaceFirst('[LOCATION]:', '') : null;
  String? get imageUrl {
    final rawUrl = remoteImageUrl ?? (type == MessageType.image ? message.replaceFirst('[IMAGE]:', '') : null);
    if (rawUrl == null || rawUrl.isEmpty) return null;
    
    // Fix: If the backend returns a relative path, prepend the server URL
    if (!rawUrl.startsWith('http') && !rawUrl.startsWith('data:image')) {
      final base = 'http://127.0.0.1:8000'; // Default dev backend
      if (rawUrl.startsWith('/')) return '$base$rawUrl';
      if (rawUrl.startsWith('media/')) return '$base/$rawUrl';
      return '$base/media/$rawUrl';
    }
    return rawUrl;
  }
  
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

class ChatUser {
  final String id;
  final String name;
  final String role;

  ChatUser({
    required this.id,
    required this.name,
    required this.role,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      name: '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim().isNotEmpty 
          ? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim()
          : json['username'] ?? 'User',
      role: json['role'] ?? 'USER',
    );
  }
}
