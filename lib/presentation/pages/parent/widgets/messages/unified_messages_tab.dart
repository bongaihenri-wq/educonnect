// lib/presentation/pages/parent/widgets/messages/unified_messages_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:educonnect/config/theme.dart';
import 'package:educonnect/services/parent_message_service.dart';
import '../comments/comment_send_section.dart';
import '../comments/reply_dialog.dart';
import 'unified_message_item.dart';

class UnifiedMessagesTab extends StatefulWidget {
  final String studentId;
  final String parentName;
  final String schoolId;
  final String? classId;

  const UnifiedMessagesTab({
    super.key,
    required this.studentId,
    required this.parentName,
    required this.schoolId,
    this.classId,
  });

  @override
  State<UnifiedMessagesTab> createState() => _UnifiedMessagesTabState();
}

class _UnifiedMessagesTabState extends State<UnifiedMessagesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ParentMessageService();
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      print('🔍 [UnifiedMessagesTab] Chargement...');
      print('   studentId=${widget.studentId}, schoolId=${widget.schoolId}, classId=${widget.classId}');
      
      final messages = await _service.getParentMessages(
        studentId: widget.studentId,
        schoolId: widget.schoolId,
        classId: widget.classId,
      );
      
      print('🔍 [UnifiedMessagesTab] ${messages.length} messages reçus');
      
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [UnifiedMessagesTab] Erreur: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String messageId, String type) async {
    print('🔍 [UnifiedMessagesTab] markAsRead: $messageId, type=$type');
    await _service.markAsRead(messageId, type);
    _loadMessages();
  }

  void _showReplyDialog(String messageId, String? teacherId, String content, String type) {
    if (type != 'comment') {
      print('⚠️ [UnifiedMessagesTab] Reply impossible pour type=$type');
      return;
    }

    final message = _messages.firstWhere(
      (m) => m['message_id'] == messageId,
      orElse: () => {},
    );
    
    if (message.isEmpty) {
      print('❌ [UnifiedMessagesTab] Message non trouvé: $messageId');
      return;
    }
    
    final teacherName = message['sender_name'] as String?;
    final subjectName = message['target_subject'] as String?;

    showDialog(
      context: context,
      builder: (context) => ReplyDialog(
        commentId: messageId.replaceFirst('hw_', '').replaceFirst('adm_', ''),
        teacherId: teacherId,
        originalContent: content,
        parentName: widget.parentName,
        teacherName: teacherName,
        subjectName: subjectName,
        onReplySent: () => _loadMessages(),
      ),
    );
  }

  void _showSendMessageDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: CommentSendSection(
                studentId: widget.studentId,
                parentName: widget.parentName,
                onSent: () {
                  Navigator.pop(context);
                  _loadMessages();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> get _allMessages => _messages;

  List<Map<String, dynamic>> get _receivedMessages => _messages.where((m) {
    final senderType = m['sender_type'] as String? ?? 'teacher';
    final isReceived = senderType == 'teacher' || senderType == 'admin';
    print('🔍 [filtre reçu] senderType=$senderType → isReceived=$isReceived');
    return isReceived;
  }).toList();

  List<Map<String, dynamic>> get _sentMessages => _messages.where((m) {
    final senderType = m['sender_type'] as String? ?? 'teacher';
    final isSent = senderType == 'parent';
    print('🔍 [filtre envoyé] senderType=$senderType → isSent=$isSent');
    return isSent;
  }).toList();

  int get _unreadCount => _messages.where((m) {
    final isRead = m['is_read'] as bool? ?? true;
    final expiresAt = m['expires_at'] as String?;
    final isExpired = expiresAt != null 
        ? DateTime.parse(expiresAt).isBefore(DateTime.now())
        : false;
    return !isRead && !isExpired;
  }).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des messages...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(color: Colors.red[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bisLight,
        body: _buildEmptyState(),
        floatingActionButton: _buildFAB(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.violet,
              labelColor: AppTheme.violet,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(
                  icon: Badge(
                    isLabelVisible: _unreadCount > 0,
                    label: Text('$_unreadCount'),
                    child: const Icon(Icons.all_inbox),
                  ),
                  text: 'Tout (${_allMessages.length})',
                ),
                Tab(
                  icon: const Icon(Icons.inbox),
                  text: 'Reçus (${_receivedMessages.length})',
                ),
                Tab(
                  icon: const Icon(Icons.send),
                  text: 'Envoyés (${_sentMessages.length})',
                ),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessageList(_allMessages, 'Tous les messages'),
                _buildMessageList(_receivedMessages, 'Messages reçus'),
                _buildMessageList(_sentMessages, 'Messages envoyés'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showSendMessageDialog,
      backgroundColor: AppTheme.violet,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_comment),
      label: const Text(
        'Nouveau',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      elevation: 4,
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages, String label) {
    if (messages.isEmpty) {
      return _buildEmptyStateForTab(label);
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          print('🔍 [build] $index: senderType=${message['sender_type']}, id=${message['message_id']}');
          return UnifiedMessageItem(
            message: message,
            parentName: widget.parentName,
            onReply: _showReplyDialog,
            onMarkRead: _markAsRead,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur "Nouveau" pour envoyer un message',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateForTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun message dans $tabName',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            tabName.contains('Envoyés') 
                ? 'Envoyez un message avec le bouton "Nouveau"'
                : 'Les messages apparaîtront ici',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}