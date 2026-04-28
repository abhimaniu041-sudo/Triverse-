import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/support_chat_service.dart';
import '../services/firestore_service.dart';

class SupportHubScreen extends StatefulWidget {
  const SupportHubScreen({Key? key}) : super(key: key);

  @override
  _SupportHubScreenState createState() => _SupportHubScreenState();
}

class _SupportHubScreenState extends State<SupportHubScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupportChatService _chat = SupportChatService();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
        'Hi Creator! 👋 I am your TriVerse AI Support Manager. Ask me anything about credits, payments, app generation, or any issue you face.',
        isUser: false),
  ];
  bool _isSending = false;
  String? _ticketId;

  Future<void> _saveMessage(String text, bool isUser) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Lazily create a ticket for this chat session on the first user message
    _ticketId ??= await FirestoreService.createTicket(text);
    if (_ticketId == null) return;

    await FirestoreService.appendTicketMessage(
      ticketId: _ticketId!,
      text: text,
      role: isUser ? 'user' : 'assistant',
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text, isUser: true));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();
    _saveMessage(text, true);

    final reply = await _chat.sendMessage(text);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(reply, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
    _saveMessage(reply, false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Manager (Support)'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isSending && index == _messages.length) {
                  return _buildTypingIndicator(maxBubbleWidth);
                }
                return _buildChatBubble(_messages[index], maxBubbleWidth);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF16162C),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isSending,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.black26,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _isSending ? null : _send,
                  mini: true,
                  backgroundColor: const Color(0xFFB026FF),
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage msg, double maxWidth) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color:
              msg.isUser ? const Color(0xFFB026FF) : const Color(0xFF16162C),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                msg.isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight:
                msg.isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(msg.text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTypingIndicator(double maxWidth) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF16162C),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFB026FF)),
            ),
            SizedBox(width: 10),
            Text('AI is thinking...',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage(this.text, {required this.isUser});
}
