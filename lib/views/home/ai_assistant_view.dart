import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../viewmodels/chatbot/chatbot_viewmodel.dart';

// ─── Public entry point used by MainShell ────────────────────────────────────

class AiAssistantContent extends StatefulWidget {
  const AiAssistantContent({super.key});

  @override
  State<AiAssistantContent> createState() => _AiAssistantContentState();
}

class _AiAssistantContentState extends State<AiAssistantContent> {
  final ChatbotViewModel _vm = ChatbotViewModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.checkHealth());
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: const _AiAssistantBody(),
    );
  }
}

// ─── Main body ───────────────────────────────────────────────────────────────

class _AiAssistantBody extends StatefulWidget {
  const _AiAssistantBody();

  @override
  State<_AiAssistantBody> createState() => _AiAssistantBodyState();
}

class _AiAssistantBodyState extends State<_AiAssistantBody> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Suggested questions to display in the empty state
  static const List<String> _suggestions = [
    'What are the conditions for renting a property in Tunisia?',
    'ما هي إجراءات عقد الإيجار في تونس؟',
    'Quelles sont les conditions d\'un contrat de bail en Tunisie?',
    'What are tenant rights under Tunisian law?',
    'ما هي حقوق المستأجر في القانون التونسي؟',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    debugPrint('[DEBUG] _sendMessage triggered with: "$text"');
    _controller.clear();
    _scrollToBottom();
    await context.read<ChatbotViewModel>().sendMessage(text);
    _scrollToBottom();
    debugPrint('[DEBUG] _sendMessage completed');
  }

  void _fillSuggestion(String text) {
    _controller.text = text;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatbotViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [

        _ChatHeader(onClear: vm.hasMessages ? vm.clearHistory : null),

        const Divider(height: 1),

        // ── Messages or welcome ─────────────────────────────────────────────
        Expanded(
          child: vm.hasMessages
              ? _MessageList(
                  messages: vm.messages,
                  isLoading: vm.isLoading,
                  scrollController: _scrollController,
                )
              : _WelcomeScreen(
                  suggestions: _suggestions,
                  onSuggestionTap: _fillSuggestion,
                ),
        ),

        const Divider(height: 1),

        // ── Input bar ───────────────────────────────────────────────────────
        _InputBar(
          controller: _controller,
          focusNode: _focusNode,
          isLoading: vm.isLoading,
          onSend: _sendMessage,
        ),
      ],
    );
  }
}


class _ChatHeader extends StatelessWidget {
  final VoidCallback? onClear;

  const _ChatHeader({this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          // AI avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.balance_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Legal AI Assistant',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Tunisian Law · Arabic · French · English',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Clear button
          if (onClear != null)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              tooltip: 'Clear conversation',
              onPressed: () => _confirmClear(context, onClear!),
            ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, VoidCallback onConfirm) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear conversation?'),
        content: const Text(
          'All messages will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome / Empty State ────────────────────────────────────────────────────

class _WelcomeScreen extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  const _WelcomeScreen({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero illustration
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.balance_rounded, color: Colors.white, size: 46),
          ),
          const SizedBox(height: 20),
          const Text(
            'Legal AI Assistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me anything about Tunisian law.\nI answer in Arabic, French, or English.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Capability chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: const [
              _CapabilityChip(icon: Icons.menu_book_rounded, label: 'Legal Articles'),
              _CapabilityChip(icon: Icons.search_rounded, label: 'Web Search'),
              _CapabilityChip(icon: Icons.translate_rounded, label: 'Multilingual'),
              _CapabilityChip(icon: Icons.gavel_rounded, label: 'Case References'),
            ],
          ),
          const SizedBox(height: 32),

          // Suggestions
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (s) => _SuggestionTile(text: s, onTap: () => onSuggestionTap(s)),
          ),
        ],
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CapabilityChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionTile({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message List ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ScrollController scrollController;

  const _MessageList({
    required this.messages,
    required this.isLoading,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length + (isLoading ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          // Loading / typing indicator
          return const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 8),
            child: _TypingIndicator(),
          );
        }
        final msg = messages[index];
        return msg.isUser
            ? _UserBubble(message: msg)
            : _AiBubble(message: msg);
      },
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _dots;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _dots = List.generate(3, (i) {
      final start = i * 0.2;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, start + 0.4, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _AiAvatar(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _dots[i],
                builder: (_, __) => Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.3 + _dots[i].value * 0.7,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── User Bubble ─────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─── AI Bubble ───────────────────────────────────────────────────────────────

class _AiBubble extends StatefulWidget {
  final ChatMessage message;
  const _AiBubble({required this.message});

  @override
  State<_AiBubble> createState() => _AiBubbleState();
}

class _AiBubbleState extends State<_AiBubble> {
  bool _sourcesExpanded = false;

  Color get _bubbleBg =>
      widget.message.isError
          ? AppColors.error.withValues(alpha: 0.08)
          : AppColors.surface;

  Color get _bubbleBorder =>
      widget.message.isError ? AppColors.error.withValues(alpha: 0.3) : AppColors.border;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AiAvatar(isError: widget.message.isError),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main message card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _bubbleBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: _bubbleBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message.text,
                    style: TextStyle(
                      color: widget.message.isError
                          ? AppColors.error
                          : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),
                ),

                // Sources accordion
                if (widget.message.sources.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _SourcesAccordion(
                    sources: widget.message.sources,
                    expanded: _sourcesExpanded,
                    onToggle: () =>
                        setState(() => _sourcesExpanded = !_sourcesExpanded),
                  ),
                ],

                // Metadata row
                const SizedBox(height: 4),
                _MetaRow(message: widget.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Avatar ───────────────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
  final bool isError;
  const _AiAvatar({this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: isError
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isError ? AppColors.error.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isError ? Icons.error_outline_rounded : Icons.balance_rounded,
        color: isError ? AppColors.error : Colors.white,
        size: 18,
      ),
    );
  }
}

// ─── Sources Accordion ───────────────────────────────────────────────────────

class _SourcesAccordion extends StatelessWidget {
  final List<LegalSource> sources;
  final bool expanded;
  final VoidCallback onToggle;

  const _SourcesAccordion({
    required this.sources,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle button
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.library_books_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${sources.length} source${sources.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable source cards
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: !expanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: sources
                        .map((s) => _SourceCard(source: s))
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final LegalSource source;
  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Art. ${source.articleNum}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Law ${source.lawNum}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
              const Spacer(),
              // Relevance score
              Text(
                '${(source.score * 100).toStringAsFixed(0)}% match',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Article text (truncated)
          Text(
            source.text.length > 200
                ? '${source.text.substring(0, 200)}…'
                : source.text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metadata Row ─────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final ChatMessage message;
  const _MetaRow({required this.message});

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUser || message.isError) {
      return Text(
        _formatTime(message.timestamp),
        style: const TextStyle(fontSize: 10, color: AppColors.textHint),
      );
    }

    final lang = message.language ?? '';
    final langLabel = lang == 'arabic'
        ? 'AR'
        : lang == 'french'
            ? 'FR'
            : 'EN';

    return Row(
      children: [
        Text(
          _formatTime(message.timestamp),
          style:
              const TextStyle(fontSize: 10, color: AppColors.textHint),
        ),
        if (lang.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              langLabel,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryDark,
              ),
            ),
          ),
        ],
        if ((message.geminiModel ?? '').isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            message.geminiModel!,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 140),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !isLoading,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Ask about Tunisian law… (Arabic, French, or English)',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 48,
                      height: 48,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Material(
                      key: const ValueKey('send'),
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onSend,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
