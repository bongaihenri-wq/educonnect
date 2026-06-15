// lib/presentation/pages/admin/admin_send_message_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class AdminSendMessagePage extends StatefulWidget {
  const AdminSendMessagePage({super.key});

  @override
  State<AdminSendMessagePage> createState() => _AdminSendMessagePageState();
}

class _AdminSendMessagePageState extends State<AdminSendMessagePage> {
  final _client = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchController = TextEditingController(); // ✅ AJOUTÉ
  
  String _recipientType = 'all_parents';
  String? _selectedClassId;
  String? _selectedParentId;
  String? _selectedTeacherId;
  final Set<String> _selectedParentIds = {}; // ✅ AJOUTÉ (sélection multiple)
  String _priority = 'normal';
  DateTime? _expiresAt;
  
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _initSchoolId();
    _searchController.addListener(() => setState(() {})); // ✅ AJOUTÉ
  }

  void _initSchoolId() {
    final state = context.read<AuthBloc>().state;
    if (state is AdminAuthenticated) {
      _schoolId = state.schoolId;
    } else if (state is SuperAdminAuthenticated) {
      _schoolId = state.schoolId;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    if (_schoolId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final classes = await _client
          .from('classes')
          .select('id, name, level')
          .eq('school_id', _schoolId!)
          .order('level');
      
      final parents = await _client
          .from('app_users')
          .select('id, first_name, last_name, phone')
          .eq('school_id', _schoolId!)
          .eq('role', 'parent')
          .order('last_name');
      
      final teachers = await _client
          .from('app_users')
          .select('id, first_name, last_name')
          .eq('school_id', _schoolId!)
          .eq('role', 'teacher')
          .order('last_name');

      setState(() {
        _classes = List<Map<String, dynamic>>.from(classes);
        _parents = List<Map<String, dynamic>>.from(parents);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ✅ AJOUTÉ : Filtrer parents selon recherche
  List<Map<String, dynamic>> get _filteredParents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _parents;
    
    return _parents.where((p) {
      final name = '${p['first_name']} ${p['last_name']}'.toLowerCase();
      final phone = (p['phone'] ?? '').toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  Future<void> _sendMessage() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir le titre et le contenu'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School ID non trouvé'), backgroundColor: Colors.red),
      );
      return;
    }

    // ✅ Vérification sélection multiple
    if (_recipientType == 'specific_parents' && _selectedParentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un parent'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final now = DateTime.now().toIso8601String();
      final expiresAt = _expiresAt?.toIso8601String();

      // ✅ ENVOI MULTIPLE : une ligne par parent sélectionné
      if (_recipientType == 'specific_parents') {
        for (final parentId in _selectedParentIds) {
          final parent = _parents.firstWhere((p) => p['id'] == parentId);
          await _client.from('admin_messages').insert({
            'school_id': _schoolId,
            'title': _titleController.text.trim(),
            'content': _contentController.text.trim(),
            'recipient_type': 'specific_parent',
            'priority': _priority,
            'is_active': true,
            'created_at': now,
            'expires_at': expiresAt,
            'sender_name': 'Administration',
            'target_parent_id': parentId,
            'target_parent_name': '${parent['first_name']} ${parent['last_name']}',
          });
        }
      } else {
        // ✅ ENVOI SIMPLE (ancien comportement)
        final insertData = {
          'school_id': _schoolId,
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'recipient_type': _recipientType,
          'priority': _priority,
          'is_active': true,
          'created_at': now,
          'expires_at': expiresAt,
          'sender_name': 'Administration',
        };

        if (_recipientType == 'class_parents' && _selectedClassId != null) {
          insertData['target_class_id'] = _selectedClassId;
        }
        if (_recipientType == 'specific_parent' && _selectedParentId != null) {
          insertData['target_parent_id'] = _selectedParentId;
        }
        if (_recipientType == 'specific_teacher' && _selectedTeacherId != null) {
          insertData['target_teacher_id'] = _selectedTeacherId;
        }

        await _client.from('admin_messages').insert(insertData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_recipientType == 'specific_parents'
              ? '✅ Message envoyé à ${_selectedParentIds.length} parent(s)'
              : '✅ Message envoyé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    _searchController.clear(); // ✅ AJOUTÉ
    setState(() {
      _recipientType = 'all_parents';
      _selectedClassId = null;
      _selectedParentId = null;
      _selectedParentIds.clear(); // ✅ AJOUTÉ
      _selectedTeacherId = null;
      _priority = 'normal';
      _expiresAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Envoyer un message'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Titre *',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Contenu *',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildRecipientSelector(),
                  const SizedBox(height: 16),
                  
                  // ✅ AJOUTÉ : Sélection multiple parents avec recherche
                  if (_recipientType == 'specific_parents') _buildMultiParentSelector(),
                  if (_recipientType == 'class_parents') _buildClassSelector(),
                  if (_recipientType == 'specific_parent') _buildParentSelector(),
                  if (_recipientType == 'specific_teacher') _buildTeacherSelector(),
                  if (_recipientType == 'all_teachers') _buildTeacherSelector(),
                  
                  const SizedBox(height: 16),
                  
                  _buildPrioritySelector(),
                  const SizedBox(height: 16),
                  
                  _buildExpirySelector(),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(_isSending
                          ? 'Envoi...'
                          : _recipientType == 'specific_parents' && _selectedParentIds.isNotEmpty
                              ? 'Envoyer à ${_selectedParentIds.length} parent(s)'
                              : 'Envoyer le message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.violet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRecipientSelector() {
    final recipients = [
      {'value': 'all_parents', 'label': 'Tous les parents', 'icon': Icons.people},
      {'value': 'class_parents', 'label': 'Parents d\'une classe', 'icon': Icons.class_},
      {'value': 'specific_parents', 'label': 'Parents spécifiques', 'icon': Icons.people_outline}, // ✅ AJOUTÉ
      {'value': 'specific_parent', 'label': 'Un parent (dropdown)', 'icon': Icons.person}, // ✅ Renommé
      {'value': 'all_teachers', 'label': 'Tous les enseignants', 'icon': Icons.school},
      {'value': 'specific_teacher', 'label': 'Enseignant spécifique', 'icon': Icons.person_outline},
      {'value': 'all_users', 'label': 'Tout le monde', 'icon': Icons.public},
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Destinataires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recipients.map((r) {
                final isSelected = _recipientType == r['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(r['icon'] as IconData, size: 16, color: isSelected ? Colors.white : Colors.grey),
                      const SizedBox(width: 4),
                      Text(r['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.violet,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _recipientType = r['value'] as String);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NOUVEAU : Sélection multiple avec recherche
  Widget _buildMultiParentSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Parents sélectionnés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  '${_selectedParentIds.length} / ${_parents.length}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou téléphone...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            
            // Boutons tout sélectionner / désélectionner
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _selectedParentIds.addAll(_filteredParents.map((p) => p['id'] as String));
                  }),
                  child: const Text('Tout sélectionner', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedParentIds.clear()),
                  child: const Text('Tout désélectionner', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            
            // Liste des parents avec checkbox
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _filteredParents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Aucun parent trouvé',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredParents.length,
                      itemBuilder: (context, index) {
                        final parent = _filteredParents[index];
                        final id = parent['id'] as String;
                        final isSelected = _selectedParentIds.contains(id);
                        final name = '${parent['first_name']} ${parent['last_name']}';
                        final phone = parent['phone'] ?? 'N/A';
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selectedParentIds.add(id);
                            } else {
                              _selectedParentIds.remove(id);
                            }
                          }),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(phone, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                          activeColor: const Color(0xFF6C63FF),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedClassId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Classe *',
            prefixIcon: Icon(Icons.class_),
            border: OutlineInputBorder(),
          ),
          items: _classes.map((c) {
            return DropdownMenuItem(
              value: c['id'] as String,
              child: Text(c['name'] as String),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedClassId = value),
          validator: (value) => value == null ? 'Sélectionnez une classe' : null,
        ),
      ),
    );
  }

  Widget _buildParentSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedParentId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Parent *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          items: _parents.map((p) {
            final name = '${p['first_name']} ${p['last_name']}';
            return DropdownMenuItem(
              value: p['id'] as String,
              child: Text('$name (${p['phone'] ?? 'N/A'})'),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedParentId = value),
          validator: (value) => value == null ? 'Sélectionnez un parent' : null,
        ),
      ),
    );
  }

  Widget _buildTeacherSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedTeacherId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Enseignant *',
            prefixIcon: Icon(Icons.school),
            border: OutlineInputBorder(),
          ),
          items: _teachers.map((t) {
            final name = '${t['first_name']} ${t['last_name']}';
            return DropdownMenuItem(
              value: t['id'] as String,
              child: Text(name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedTeacherId = value),
          validator: (value) => value == null ? 'Sélectionnez un enseignant' : null,
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final priorities = [
      {'value': 'low', 'label': 'Basse', 'color': Colors.grey},
      {'value': 'normal', 'label': 'Normale', 'color': Colors.blue},
      {'value': 'high', 'label': 'Haute', 'color': Colors.orange},
      {'value': 'urgent', 'label': 'Urgente', 'color': Colors.red},
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Priorité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: priorities.map((p) {
                final isSelected = _priority == p['value'];
                return ChoiceChip(
                  label: Text(p['label'] as String),
                  selected: isSelected,
                  selectedColor: p['color'] as Color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : p['color'] as Color,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _priority = p['value'] as String);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpirySelector() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _expiresAt = picked);
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: AppTheme.violet),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date d\'expiration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      _expiresAt != null
                          ? '${_expiresAt!.day.toString().padLeft(2, '0')}/${_expiresAt!.month.toString().padLeft(2, '0')}/${_expiresAt!.year}'
                          : 'Par défaut : 30 jours',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose(); // ✅ AJOUTÉ
    super.dispose();
  }
}