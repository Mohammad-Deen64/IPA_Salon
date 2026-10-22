class ChatThread {
  const ChatThread({
    required this.salonId,
    required this.customerId,
    required this.title,
    required this.lastMessage,
  });

  final String salonId;
  final String customerId;
  final String title;
  final String lastMessage;

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      salonId: json['salon_id'] as String,
      customerId: json['customer_id'] as String,
      title: json['title'] as String? ?? 'Chat',
      lastMessage: json['last_message'] as String? ?? '',
    );
  }
}

class ChatLine {
  const ChatLine({
    required this.id,
    required this.body,
    required this.senderRole,
    required this.mine,
  });

  final String id;
  final String body;
  final String senderRole;
  final bool mine;

  factory ChatLine.fromJson(Map<String, dynamic> json) {
    return ChatLine(
      id: json['id'] as String,
      body: json['body'] as String? ?? '',
      senderRole: json['sender_role'] as String? ?? 'system',
      mine: json['mine'] == true,
    );
  }
}
