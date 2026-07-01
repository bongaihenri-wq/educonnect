// lib/presentation/pages/admin/admin_messages_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'admin_send_message_page.dart';

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = CommentRepository(Supabase.instance.client);
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMessages = [];
  List<Map<String, dynamic>> _parentMessages = [];
  List<Map<String, dynamic>> _teacherMessages = [];
  List<Map<String, dynamic>> _adminMessages = [];
  
  String? _selectedClassId;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMessages();
    _loadClasses();
  }

  Future<void> _loadMessages() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isLoading = true);

    try {
      final result = await _repo.getAllMessages(
        schoolId: authState.schoolId,
      );

      if (mounted) {
        setState(() {
          _allMessages = result['all'] ?? [];
          _parentMessages = result['parent'] ?? [];
          _teacherMessages = result['teacher'] ?? [];
          _adminMessages = result['admin'] ?? [];
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

  List<Map<String, dynamic>> _filterByClass(List<Map<String, dynamic>> messages) {
    if (_selectedClassId == null || _selectedClassId!.isEmpty) return messages;
    
    return messages.where((msg) {
      final classId = msg['class_id'] as String?;
      return classId == _selectedClassId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAll = _filterByClass(_allMessages);
    final filteredParent = _filterByClass(_parentMessages);
    final filteredTeacher = _filterByClass(_teacherMessages);
    final filteredAdmin = _filterByClass(_adminMessages);

    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Messagerie École'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: _allMessages.isNotEmpty,
                label: Text('${_allMessages.length}'),
                child: const Icon(Icons.all_inbox),
              ),
              text: 'Tout',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _parentMessages.isNotEmpty,
                label: Text('${_parentMessages.length}'),
                child: const Icon(Icons.family_restroom),
              ),
              text: 'Parents',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _teacherMessages.isNotEmpty,
                label: Text('${_teacherMessages.length}'),
                child: const Icon(Icons.school),
              ),
              text: 'Enseignants',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _adminMessages.isNotEmpty,
                label: Text('${_adminMessages.length}'),
                child: const Icon(Icons.admin_panel_settings),
              ),
              text: 'Admin',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildClassFilter(),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMessageList(filteredAll),
                      _buildMessageList(filteredParent),
                      _buildMessageList(filteredTeacher),
                      _buildMessageList(filteredAdmin),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminSendMessagePage(),
          ),
        ).then((_) => _loadMessages()),
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

  Widget _buildClassFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 18, color: AppTheme.violet),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedClassId,
                hint: Text('Toutes les classes', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.violet, size: 18),
                style: TextStyle(fontSize: 13, color: AppTheme.nightBlue, fontWeight: FontWeight.w500),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Toutes les classes', style: TextStyle(fontSize: 13)),
                  ),
                  ..._classes.map((c) {
                    return DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['name'] as String, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                ],
                onChanged: (value) => setState(() => _selectedClassId = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildMessageCard(messages[index]),
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
            'Les messages envoyés dans l\'école apparaîtront ici',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final content = message['content'] as String? ?? '';
    final createdAt = DateTime.parse(message['created_at'] as String);
    final isBroadcast = message['is_broadcast'] == true;
    final senderName = message['sender_name'] as String? ?? 'Inconnu';
    final senderRole = message['sender_role'] as String? ?? 'unknown';
    
    final sender = message['sender'] as Map<String, dynamic>?;
    final senderDisplayName = sender != null 
        ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim()
        : senderName;
    
    final studentData = message['students'] as Map<String, dynamic>?;
    final className = studentData?['classes']?['name'] as String? ?? 'Classe';
    final studentName = studentData != null 
        ? '${studentData['first_name'] ?? ''} ${studentData['last_name'] ?? ''}'.trim()
        : '';
    
    final recipients = (message['message_recipients'] as List?) ?? [];
    final readCount = recipients.where((r) => r['read_at'] != null).length;
    final totalCount = recipients.length;

    final dateStr = '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    final Color roleColor;
    final IconData roleIcon;
    final String roleLabel;
    
    switch (senderRole) {
      case 'parent':
        roleColor = Colors.green;
        roleIcon = Icons.family_restroom;
        roleLabel = 'PARENT';
        break;
      case 'teacher':
        roleColor = AppTheme.violet;
        roleIcon = Icons.school;
        roleLabel = 'ENSEIGNANT';
        break;
      case 'admin':
        roleColor = Colors.orange;
        roleIcon = Icons.admin_panel_settings;
        roleLabel = 'ADMIN';
        break;
      default:
        roleColor = Colors.grey;
        roleIcon = Icons.person;
        roleLabel = 'INCONNU';
    }

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
              color: roleColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(roleIcon, size: 16, color: roleColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBroadcast 
                            ? 'Broadcast: $className' 
                            : (studentName.isNotEmpty ? 'À: $studentName' : 'Message direct'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.nightBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$dateStr • De: $senderDisplayName',
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
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isBroadcast ? '📢 BROADCAST' : roleLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
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
                if (totalCount > 0) ...[
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