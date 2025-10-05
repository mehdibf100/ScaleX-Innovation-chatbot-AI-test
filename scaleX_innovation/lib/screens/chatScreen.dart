import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive/hive.dart';
import 'package:scalex_innovation/models/conversation.dart';
import 'package:scalex_innovation/screens/login.dart';
import 'package:scalex_innovation/services/conversation_service.dart';
import 'package:scalex_innovation/services/notification_service.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:scalex_innovation/widgets/empty_state.dart';
import 'package:scalex_innovation/services/ai_service.dart';
import 'package:scalex_innovation/services/auth_service.dart';
import 'package:scalex_innovation/utils/pdf_export.dart';
import 'package:scalex_innovation/widgets/messages_list.dart';
import 'package:scalex_innovation/widgets/loading_indicator.dart';
import 'package:scalex_innovation/widgets/input_area.dart';
import 'package:scalex_innovation/widgets/scroll_to_bottom_button.dart';
import 'package:scalex_innovation/widgets/model_option.dart';
import 'package:scalex_innovation/models/chat_message.dart';
import 'package:scalex_innovation/models/ai_model.dart';
import 'package:scalex_innovation/widgets/sidebar_history.dart';

final aiServiceProvider = Provider((ref) => AiService());
final authServiceProvider = Provider((ref) => AuthService());
final selectedModelProvider = StateProvider<AiModel>((ref) => AiModel.groq);
final isLoadingProvider = StateProvider<bool>((ref) => false);
bool _showAppBarShadow = false;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final _uuid = const Uuid();
  late ConversationService _convService;
  List<ChatMessage> _messages = [];
  Box? _conversationsBox;
  String _userId = 'anon';
  bool _showScrollButton = false;

  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  List<Conversation> _conversations = [];
  String? _currentConversationId;


  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _convService = ConversationService();
    _initUserAndHistory();
    _initSpeech();
    _scroll_controller_addListener();
    _fabController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeInOut);
    _controller.addListener(() => setState(() {}));
  }
  Future<void> _generateAndSaveSummary(AiModel model) async {
    if (_currentConversationId == null) return;

    final userMessages = _messages.where((m) => m.role == 'user').map((m) => m.content).toList();
    if (userMessages.length < 1) return;

    try {
      final ai = ref.read(aiServiceProvider);
      final summary = await ai.summarizeHistory(model, userMessages);

      final idx = _conversations.indexWhere((c) => c.id == _currentConversationId);
      if (idx == -1) return;
      final conv = _conversations[idx];

      conv.summary = summary;
      conv.updatedAt = DateTime.now();
      _conversations.removeAt(idx);
      _conversations.insert(0, conv);
      await _persistConversations();

      try {
        final user = FirebaseAuth.instance.currentUser;
        final firebaseUid = user?.uid;
        if (firebaseUid == null) return;

        if (conv.remoteId == null) {
          try {
            final remoteId = await _convService.createRemoteConversation(firebaseUid: firebaseUid, title: conv.title);
            conv.remoteId = remoteId;
            await _persistConversations();
          } catch (e) {
            debugPrint('createRemoteConversation failed: $e');
          }
        }

        try {
          final contextMeta = 'model=${ref.read(selectedModelProvider).name};lang=${context.locale.languageCode}';
          final created = await _convService.createRemoteSummary(
            remoteConversationId: conv.remoteId,
            firebaseUid: firebaseUid,
            summary: summary,
            context: contextMeta,
          );

          final remoteSummaryId = created['id'] ?? created['summaryId'] ?? (created['summary'] == summary ? created['id'] ?? created['summaryId'] : null);

          if (remoteSummaryId != null) {
            conv.remoteSummaryId = remoteSummaryId.toString();
            await _persistConversations();
          }

          debugPrint('createRemoteSummary OK: $created');
        } catch (e) {
          debugPrint('createRemoteSummary failed: $e');
        }
      } catch (e) {
        debugPrint('Summary remote sync outer: $e');
      }
    } catch (e, st) {
      debugPrint('Summary generation failed: $e\n$st');
    }
  }

  void _showModelSelector() {
    final selectedModel = ref.read(selectedModelProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('choose_model'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ModelOption(
              model: AiModel.groq,
              title: 'Groq (Llama 3)',
              description: tr('model_groq_desc'),
              icon: Icons.flash_on,
              isSelected: selectedModel == AiModel.groq,
              onTap: () {
                ref.read(selectedModelProvider.notifier).state = AiModel.groq;
                Navigator.pop(ctx);
              },
            ),
            ModelOption(
              model: AiModel.mistral,
              title: 'Mistral.ai',
              description: tr('model_mistral_desc'),
              icon: Icons.balance,
              isSelected: selectedModel == AiModel.mistral,
              onTap: () {
                ref.read(selectedModelProvider.notifier).state = AiModel.mistral;
                Navigator.pop(ctx);
              },
            ),
            ModelOption(
              model: AiModel.gemini,
              title: 'Gemini',
              description: tr('model_gemini_desc'),
              icon: Icons.stars,
              isSelected: selectedModel == AiModel.gemini,
              onTap: () {
                ref.read(selectedModelProvider.notifier).state = AiModel.gemini;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      await _speech.initialize();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll_controller_maybeDispose();
    _focusNode.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _scroll_controller_maybeDispose() {
    try {
      _scrollController.dispose();
    } catch (_) {}
  }

  Future<void> _initUserAndHistory() async {
    try {
      final auth = ref.read(authServiceProvider);
      final user = auth.currentUser;
      _userId = user?.uid ?? 'anon';
      _conversationsBox = await Hive.openBox('conversations_$_userId');
      final raw = _conversationsBox!.get('conversations', defaultValue: []);
      _conversations = (raw as List).map((e) => Conversation.fromMap(Map<String, dynamic>.from(e))).toList();

      if (_conversations.isEmpty) {
        await _createNewConversation();
      } else {
        _selectConversation(_conversations.first.id);
      }
    } catch (e) {
      debugPrint('Init conv error: $e');
    }
  }

  Future<void> _persistConversations() async {
    if (_conversationsBox == null) return;
    final list = _conversations.map((c) => c.toMap()).toList();
    await _conversationsBox!.put('conversations', list);
  }

  Future<void> _createNewConversation() async {
    final id = _uuid.v4();
    final conv = Conversation(id: id, title: tr('new_conversation_title'), messages: [], createdAt: DateTime.now(), updatedAt: DateTime.now(), summary: '');
    setState(() {
      _conversations.insert(0, conv);
      _currentConversationId = id;
      _messages = conv.messages;
    });
    await _persistConversations();
  }

  Future<void> _selectConversation(String id) async {
    final conv = _conversations.firstWhere((c) => c.id == id, orElse: () => Conversation(id: id, title: tr('conversation'), messages: [], summary: ''));
    setState(() {
      _currentConversationId = conv.id;
      _messages = [...conv.messages];
    });
    _scrollToBottom(animated: false);
  }

  Future<void> _deleteConversation(String id) async {
    setState(() {
      _conversations.removeWhere((c) => c.id == id);
      if (_currentConversationId == id) {
        if (_conversations.isNotEmpty) {
          _selectConversation(_conversations.first.id);
        } else {
          _createNewConversation();
        }
      }
    });
    await _persistConversations();
  }

  Future<void> _saveCurrentConversation() async {
    if (_currentConversationId == null) return;
    final idx = _conversations.indexWhere((c) => c.id == _currentConversationId);
    if (idx == -1) {
      final conv = Conversation(id: _currentConversationId!, title: tr('conversation'), messages: _messages, updatedAt: DateTime.now(), summary: '');
      _conversations.insert(0, conv);
    } else {
      final conv = _conversations[idx];
      conv.messages = [..._messages];
      conv.updatedAt = DateTime.now();
      if (conv.title == tr('new_conversation_title') && conv.messages.isNotEmpty) {
        conv.title = conv.messages.first.content.length > 30 ? '${conv.messages.first.content.substring(0, 30)}...' : conv.messages.first.content;
      }
      _conversations.removeAt(idx);
      _conversations.insert(0, conv);
    }
    await _persistConversations();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final firebaseUid = user?.uid;
      if (firebaseUid != null) {
        final idx = _conversations.indexWhere((c) => c.id == _currentConversationId);
        if (idx != -1) {
          final conv = _conversations[idx];
          unawaited(_convService.syncLocalToRemote(local: conv, firebaseUid: firebaseUid));
        }
      }
    } catch (e) {
      debugPrint('Sync to remote failed: $e');
    }
  }

  void _scroll_controller_addListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      if (_messages.isEmpty) {
        if (_showScrollButton || _showAppBarShadow) {
          setState(() {
            _showScrollButton = false;
            _showAppBarShadow = false;
          });
          _fabController.reverse();
        }
        return;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;

      final showButton = current < maxScroll - 200;
      if (showButton != _showScrollButton) {
        setState(() => _showScrollButton = showButton);
        if (showButton) _fabController.forward(); else _fabController.reverse();
      }

      final showShadow = current > 10;
      if (showShadow != _showAppBarShadow) {
        setState(() => _showAppBarShadow = showShadow);
      }
    });
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final target = _scrollController.position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(target);
        }
      }
    });
  }


  Future<void> _sendMessage(String text) async {
    final msg = text.trim();
    if (msg.isEmpty) return;
    final model = ref.read(selectedModelProvider);
    ref.read(isLoadingProvider.notifier).state = true;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: msg));
    });
    _controller.clear();
    await _saveCurrentConversation();
    _scrollToBottom();

    try {
      final ai = ref.read(aiServiceProvider);
      final payload = _messages
          .map((m) => {
        'role': m.role == 'user' ? 'user' : 'assistant',
        'content': m.content
      })
          .toList();
      final aiResponse = await ai.sendMessage(
        model: model,
        messages: payload,
        userLang: context.locale.languageCode,
      );

      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: aiResponse));
      });

      await _saveCurrentConversation();
      _scrollToBottom();

      try {
        await NotificationService.instance.showAiReply(aiResponse, title: 'Réponse AI');
      } catch (notifyError) {
        debugPrint('Erreur lors de l\'affichage de la notification: $notifyError');
      }

      try {
        await _generateAndSaveSummary(model);
      } catch (_) {
      }
    } catch (e) {
      setState(() =>
          _messages.add(ChatMessage(role: 'assistant', content: 'Erreur: $e')));
      await _saveCurrentConversation();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null) return;
      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        final f = File(file.path!);
        bytes = await f.readAsBytes();
      }
      if (bytes == null) {
        _showSnackBar(tr('file_read_error'), isError: true);
        return;
      }
      String messageToSend;
      try {
        final decoded = utf8.decode(bytes, allowMalformed: true);
        final nonPrintable = decoded.runes.where((r) => r <= 8 || (r >= 14 && r <= 31)).length;
        final threshold = (decoded.length * 0.05).round();
        if (nonPrintable > threshold) {
          messageToSend = tr('binary_file_preview', args: [file.name, file.size.toString()]);
        } else {
          var preview = decoded;
          const maxPreview = 8000;
          if (preview.length > maxPreview) preview = preview.substring(0, maxPreview) + '\n\n[...aperçu tronqué]';
          messageToSend = '📎 ${tr('file')}: ${file.name}\n\n$preview';
        }
      } catch (_) {
        messageToSend = tr('binary_file_preview', args: [file.name, file.size.toString()]);
      }
      await _sendMessage(messageToSend);
      _showSnackBar(tr('file_sent', args: [file.name]), isError: false);
    } catch (e) {
      _showSnackBar('${tr('import_error')}: $e', isError: true);
    }
  }

  Future<void> _exportPdf() async {
    try {
      final list = _messages.map((m) => {'role': m.role, 'content': m.content}).toList();
      await exportChatAsPdf('chat_export_$_userId', list);
      _showSnackBar(tr('export_success'), isError: false);
    } catch (e) {
      _showSnackBar('${tr('export_error')}: $e', isError: true);
    }
  }

  Future<void> _createConversationAndOpen() async {
    await _createNewConversation();
    _scrollToBottom(animated: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))]),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _toggleVoice() async {
    if (!_isListening) {
      final available = await _speech.initialize();
      if (!available) {
        _showSnackBar('Voice not available', isError: true);
        return;
      }
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          _controller.text = text;
          if (result.finalResult) {
            _toggleVoice();
            _sendMessage(_controller.text);
          }
        },
        localeId: context.locale.languageCode,
        listenFor: const Duration(seconds: 30),
      );
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final selectedModel = ref.watch(selectedModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar:
      AppBar(
        elevation: _showAppBarShadow ? 4 : 0,
        backgroundColor: const Color(0xFFF5F7FA),
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('assistant_title'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2D3748))),
                Text('${selectedModel.name.toUpperCase()} • ${context.locale.languageCode}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('new_conversation'),
            icon: const Icon(Icons.add_comment, color: Color(0xFF64748B)),
            onPressed: _createConversationAndOpen,
          ),
          IconButton(
            icon: const Icon(Icons.language, color: Color(0xFF64748B)),
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Image.asset('assets/images/flags/en.png', width: 28, height: 28, fit: BoxFit.contain),
                    title: const Text('English'),
                    onTap: () {
                      context.setLocale(const Locale('en'));
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: Image.asset('assets/images/flags/ar.png', width: 28, height: 28, fit: BoxFit.contain),
                    title: const Text('العربية'),
                    onTap: () {
                      context.setLocale(const Locale('ar'));
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showModelSelector()),
        ],
      ),
      drawer: SidebarHistory(
        conversations: _conversations,
        onSelectConversation: (id) => _selectConversation(id),
        onExport: _exportPdf,
        onCreateNew: _createConversationAndOpen,
        onDelete: (id) async => _deleteConversation(id),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _messages.isEmpty ? EmptyStateWidget(model: selectedModel) : MessagesList(messages: _messages, controller: _scrollController)),
              if (isLoading) const LoadingIndicatorWidget(),
              InputArea(
                controller: _controller,
                focusNode: _focusNode,
                onSend: _sendMessage,
                onAttach: _pickAndSendFile,
                onVoiceToggle: _toggleVoice,
                isListening: _isListening,
              ),
            ],
          ),
          if (_showScrollButton && _messages.isNotEmpty)
            ScrollToBottomButton(
              animation: _fabAnimation,
              onPressed: () => _scrollToBottom(),
            ),
        ],
      ),
    );
  }
}
