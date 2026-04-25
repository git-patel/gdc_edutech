import 'package:flutter/material.dart';

import '../services/ai_tutor_service.dart';
import '../theme/app_colors.dart';
import '../widgets/widgets.dart';

class AITutorScreen extends StatefulWidget {
  final String? subjectName;
  final String? chapterTitle;

  const AITutorScreen({super.key, this.subjectName, this.chapterTitle});

  @override
  State<AITutorScreen> createState() => _AITutorScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _AITutorScreenState extends State<AITutorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AITutorService _tutorService = AITutorService();
  
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  String _currentStreamedText = '';

  @override
  void initState() {
    super.initState();
    _tutorService.initialize(subject: widget.subjectName, chapter: widget.chapterTitle).then((_) {
      String welcomeText = "Hi! I'm your Agentic Tutor. I personalize content and adapt to your pace.";
      if (widget.subjectName != null && widget.chapterTitle != null) {
        welcomeText += " Let's dive deep into ${widget.subjectName} - ${widget.chapterTitle}! What specifically would you like to explore?";
      } else {
        welcomeText += " What concept would you like to learn today?";
      }
      _addBotMessage(welcomeText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isTyping = true;
      _currentStreamedText = '';
    });
    _scrollToBottom();

    try {
      final stream = _tutorService.sendMessageStream(text);
      await for (final chunk in stream) {
        if (mounted) {
          setState(() {
            _currentStreamedText += chunk;
          });
          _scrollToBottom();
        }
      }
      
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: _currentStreamedText, isUser: false));
          _isTyping = false;
          _currentStreamedText = '';
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _currentStreamedText = '';
          _messages.add(_ChatMessage(text: 'An error occurred. Please try again.', isUser: false));
        });
        _scrollToBottom();
      }
    }
  }

  Widget _buildChatBubble(_ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;
    final colors = theme.colorScheme;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? colors.primary : colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.onSurface.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isUser ? null : Border.all(color: colors.dividerColor),
        ),
        child: BodyText(
          message.text,
          style: TextStyle(
            color: isUser ? colors.onPrimary : colors.onSurface,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingBubble(ThemeData theme) {
    if (!_isTyping) return const SizedBox.shrink();
    
    final colors = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.onSurface.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: colors.dividerColor),
        ),
        child: _currentStreamedText.isEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                  ),
                  const SizedBox(width: 8),
                  BodyText("Thinking...", style: TextStyle(color: colors.captionColor)),
                ],
              )
            : BodyText(
                _currentStreamedText,
                style: TextStyle(color: colors.onSurface, height: 1.5),
              ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, ColorScheme colors) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: colors.primary),
      label: Text(label, style: TextStyle(color: colors.onSurface, fontSize: 12)),
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.dividerColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _controller.text = label;
        _sendMessage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
        // Custom App Bar for Tutor
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: colors.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back Button (only if pushed, not in bottom nav)
              if (Navigator.of(context).canPop())
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTitle('Agentic Tutor', style: TextStyle(fontSize: 20, color: colors.onSurface)),
                  Subtitle('Adaptive & Personalized', style: TextStyle(fontSize: 12, color: colors.primary)),
                ],
              ),
            ],
          ),
        ),

        // Chat View
        Expanded(
          child: Container(
            color: colors.background,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              itemCount: _messages.length + 1, // +1 for streaming bubble
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildChatBubble(_messages[index], theme);
                } else {
                  return _buildStreamingBubble(theme);
                }
              },
            ),
          ),
        ),

        // Action Prompts
        Container(
          color: colors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionChip("Test My Knowledge", Icons.quiz, colors),
                const SizedBox(width: 8),
                _buildActionChip("Explain Simpler", Icons.compress, colors),
                const SizedBox(width: 8),
                _buildActionChip("Give an Analogy", Icons.lightbulb, colors),
                const SizedBox(width: 8),
                _buildActionChip("Summarize", Icons.summarize, colors),
              ],
            ),
          ),
        ),

        // Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: colors.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colors.dividerColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ask me anything...",
                        hintStyle: TextStyle(color: colors.captionColor),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(color: colors.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(Icons.send_rounded, color: colors.onPrimary, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}
