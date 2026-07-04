// lib/presentation/pages/teacher/teacher_messages_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'comments_classes_page.dart';

class TeacherMessagesPage extends StatefulWidget {
  const TeacherMessagesPage({super.key});

  @override
  State<TeacherMessagesPage> createState() => _TeacherMessagesPageState();
}

class _TeacherMessagesPageState extends State<TeacherMessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = CommentRepository(Supabase.instance.client);
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _sentMessages = [];
  List<Map<String, dynamic>> _receivedMessages = [];
  
  String _filterType = 'Tout';
  String? _filterClassId;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
    _loadClasses();
  }

  Future<void> _loadMessages() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isLoading = true);

    try {
      final result = await _repo.getTeacherMessages(
        teacherId: authState.userId,
        schoolId: authState.schoolId,
      );

      if (mounted) {
        setState(() {
          _sentMessages = result['sent'] ?? [];
          _receivedMessages = result['received'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClasses() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    try {
      final response = await Supabase.instance.client
          .from('classes')
          .select('id, name, level')
          .eq('school_id', authState.schoolId)
          .order('level');

      if (mounted) {
        setState(() {
          _classes = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement classes: $e');
    }
  }

  // ─── FILTRAGE ─────────────────────────

  List<Map<String, dynamic>> _filterMessages(List<Map<String, dynamic>> messages) {
    var filtered = messages;

    if (_filterType == 'Broadcast') {
      filtered = filtered.where((m) => m['is_broadcast'] == true).toList();
    } else if (_filterType == 'Individuel') {
      filtered = filtered.where((m) => m['is_broadcast'] != true).toList();
    }

    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      filtered = filtered.where((m) {
        final classId = m['class_id'] as String?;
        return classId == _filterClassId;
      }).toList();
    }

    return filtered;
  }

  // ─── SUPPRESSION ─────────────────────────

  // ✅ CORRIGÉ : messageId au lieu de commentId
  Future<void> _deleteMessage(String messageId) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 10),
            Text('Supprimer le message'),
          ],
        ),
        content: const Text(
          'Ce message sera supprimé pour tous les destinataires.\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // ✅ CORRIGÉ : messageId au lieu de commentId
      await _repo.softDeleteMessage(
        messageId: messageId,
        deletedBy: authState.userId,
      );

      _showSnack('✅ Message supprimé', Colors.green);
      _loadMessages();
    } catch (e) {
      _showSnack('❌ Erreur: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // ✅ NAVIGATION vers la page existante de création de messages
  void _navigateToCreateMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommentsClassesPage(),
      ),
    ).then((_) => _loadMessages());
  }

  // ─── BUILD ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final filteredSent = _filterMessages(_sentMessages);
    final filteredReceived = _filterMessages(_receivedMessages);

    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mes Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: _sentMessages.isNotEmpty,
                label: Text('${_sentMessages.length}'),
                child: const Icon(Icons.send),
              ),
              text: 'Envoyés',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _receivedMessages.isNotEmpty,
                label: Text('${_receivedMessages.length}'),
                child: const Icon(Icons.inbox),
              ),
              text: 'Reçus',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMessageList(filteredSent, isSent: true),
                      _buildMessageList(filteredReceived, isSent: false),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateMessage,
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment),
        label: const Text(
          'Nouveau',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ─── WIDGET : Filtres ─────────────────────────

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: 'Type',
                  value: _filterType,
                  items: const ['Tout', 'Broadcast', 'Individuel'],
                  onChanged: (v) => setState(() => _filterType = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  label: 'Classe',
                  value: _filterClassId ?? 'Toutes',
                  items: ['Toutes', ..._classes.map((c) => c['name'] as String)],
                  onChanged: (v) {
                    setState(() {
                      if (v == 'Toutes') {
                        _filterClassId = null;
                      } else {
                        final cls = _classes.firstWhere((c) => c['name'] == v);
                        _filterClassId = cls['id'] as String;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.violet.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.violet, size: 18),
          style: TextStyle(fontSize: 13, color: AppTheme.nightBlue, fontWeight: FontWeight.w500),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  // ─── WIDGET : Liste des messages ─────────────────────────

  Widget _buildMessageList(List<Map<String, dynamic>> messages, {required bool isSent}) {
    if (messages.isEmpty) {
      return _buildEmptyState(isSent: isSent);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildMessageCard(messages[index], isSent: isSent),
    );
  }

  Widget _buildEmptyState({required bool isSent}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSent ? Icons.send_outlined : Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isSent ? 'Aucun message envoyé' : 'Aucun message reçu',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            isSent
                ? 'Envoyez un message depuis la page Commentaires'
                : 'Les messages que vous recevez apparaîtront ici',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (isSent) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _navigateToCreateMessage,
              icon: const Icon(Icons.add_comment),
              label: const Text('Créer un message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── WIDGET : Carte message ─────────────────────────

  Widget _buildMessageCard(Map<String, dynamic> message, {required bool isSent}) {
    final content = message['content'] as String? ?? '';
    final createdAt = DateTime.parse(message['created_at'] as String);
    final isBroadcast = message['is_broadcast'] == true;
    final senderName = message['sender_name'] as String? ?? 'Inconnu';
    
    final studentData = message['students'] as Map<String, dynamic>?;
    final className = studentData?['classes']?['name'] as String? ?? 'Classe';
    
    final recipients = (message['message_recipients'] as List?) ?? [];
    final readCount = recipients.where((r) => r['read_at'] != null).length;
    final totalCount = recipients.length;

    final dateStr = '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    final Color typeColor = isBroadcast ? Colors.blue : AppTheme.violet;
    final IconData typeIcon = isBroadcast ? Icons.campaign : Icons.comment;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(typeIcon, size: 16, color: typeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isSent
                            ? (isBroadcast ? 'Broadcast à: $className' : 'À: ${studentData?['first_name'] ?? ''} ${studentData?['last_name'] ?? ''}')
                            : 'De: $senderName',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.nightBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isSent ? 'Envoyé le $dateStr' : 'Reçu le $dateStr',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isBroadcast ? 'BROADCAST' : 'INDIVIDUEL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                if (isSent && totalCount > 0) ...[
                  Icon(Icons.remove_red_eye, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '$readCount/$totalCount lu',
                    style: TextStyle(
                      fontSize: 11,
                      color: readCount == totalCount ? Colors.green : Colors.grey[500],
                      fontWeight: readCount == totalCount ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                ] else ...[
                  const Spacer(),
                ],
                if (isSent)
                  TextButton.icon(
                    onPressed: () => _deleteMessage(message['id'] as String),
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text(
                      'Supprimer',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
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