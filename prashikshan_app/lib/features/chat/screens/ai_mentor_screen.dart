import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_palette.dart';
import '../../../services/api_service.dart';
import '../models/chat_models.dart';
import 'chat_history_screen.dart';

class AiMentorScreen extends StatefulWidget {
  final String? sessionId;
  const AiMentorScreen({super.key, this.sessionId});

  @override
  State<AiMentorScreen> createState() => _AiMentorScreenState();
}

class _AiMentorScreenState extends State<AiMentorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitLoading = true;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      if (widget.sessionId != null) {
        _currentSessionId = widget.sessionId;
        final history = await ApiService.getChatMessages(_currentSessionId!);
        setState(() {
          _messages.clear();
          _messages.addAll(history.map((m) => ChatMessage.fromJson(m)));
          _isInitLoading = false;
        });
        _scrollToBottom();
      } else {
        final newId = await ApiService.createChatSession();
        setState(() {
          _currentSessionId = newId;
          if (_messages.isEmpty) {
            _messages.add(ChatMessage(
              role: 'assistant',
              content: 'Hello! I am your AI Career Mentor. I have started a new session for you.'
            ));
          }
          _isInitLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Init Chat Error: $e");
      setState(() => _isInitLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection Issue: Check your internet or server.')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading || _currentSessionId == null) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final replyText = await ApiService.sendChatMessage(
        message: text,
        sessionId: _currentSessionId!,
      );

      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: replyText));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant', 
            content: 'Sorry, I encountered an error. Please try again later.'
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI SAFETY: Always return Scaffold
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        title: Text(
          'AI Mentor',
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppPalette.pureWhite,
          ),
        ),
        actions: [
          if (_isInitLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.pureWhite),
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatHistoryScreen()),
              );
            },
            icon: const Icon(Icons.history_rounded, color: AppPalette.pureWhite),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && _isInitLoading
                ? const Center(child: Text("Preparing Mentor...", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.role == 'user';
                      return _buildChatBubble(message.content, isUser);
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.pureWhite),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppPalette.pureWhite : AppPalette.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 15,
            color: isUser ? Colors.black : AppPalette.pureWhite,
            height: 1.4,
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: AppPalette.background,
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppPalette.border),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !_isInitLoading,
                style: GoogleFonts.roboto(color: AppPalette.pureWhite),
                decoration: InputDecoration(
                  hintText: _isInitLoading ? 'Connecting...' : 'Type your career question...',
                  hintStyle: GoogleFonts.roboto(color: AppPalette.textMuted, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppPalette.pureWhite, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
