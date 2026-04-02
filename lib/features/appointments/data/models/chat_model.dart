class ChatMessage {
  final String id;
  final String message;
  final DateTime timestamp;
  final ChatUser sender;

  ChatMessage({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      sender: ChatUser.fromJson(json['user'] ?? {}),
    );
  }

  bool isMe(String currentUserId) => sender.id == currentUserId;
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
