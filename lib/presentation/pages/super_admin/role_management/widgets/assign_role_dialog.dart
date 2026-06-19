// lib/presentation/pages/super_admin/role_management/widgets/assign_role_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../data/models/role_model.dart';
import '/../../data/repositories/role_repository.dart';
import '/presentation/blocs/auth_bloc/auth_bloc.dart' as auth;

class AssignRoleDialog extends StatefulWidget {
  final RoleModel role;
  final RoleRepository repository;

  const AssignRoleDialog({
    super.key,
    required this.role,
    required this.repository,
  });

  @override
  State<AssignRoleDialog> createState() => _AssignRoleDialogState();
}

class _AssignRoleDialogState extends State<AssignRoleDialog> {
  final _phoneController = TextEditingController();
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.person_add, color: Color(0xFF6C63FF)), // ⭐ Harmonisation couleur
          const SizedBox(width: 12),
          Text('Attribuer ${widget.role.name}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rôle: ${widget.role.name}\n'
            '${widget.role.countryCode != null ? 'Pays: ${_getCountryName(widget.role.countryCode!)}' : 'Global'}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Téléphone de l\'utilisateur *',
              hintText: '+237699887766',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _isAssigning ? null : _submit,
          icon: _isAssigning
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(_isAssigning ? 'Attribution...' : 'Attribuer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF), // ⭐ Harmonisation couleur
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isAssigning = true);

    try {
      final users = await widget.repository.findUserByPhone(phone);

      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Utilisateur non trouvé'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isAssigning = false);
        return;
      }

      final user = users[0];
      final userId = user['id'].toString();

      // ✅ Passer null pour granted_by
      final result = await Supabase.instance.client.rpc('assign_role_to_user', params: {
        'p_user_id': userId,
        'p_role_id': widget.role.id,
        'p_granted_by': null,  // ✅ Plus de problème FK
        'p_is_primary': true,
      });

      Navigator.pop(context);

      final success = result != null && (
        (result is Map && result['success'] == true) ||
        (result is List && result.isNotEmpty && result[0]['success'] == true)
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rôle attribué à ${user['first_name']} ${user['last_name']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Échec attribution');
      }
    } catch (e) {
      setState(() => _isAssigning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCountryName(String code) {
    switch (code) {
      case '+225': return '🇨🇮 Côte d\'Ivoire';
      case '+237': return '🇨🇲 Cameroun';
      case '+221': return '🇸🇳 Sénégal';
      case '+233': return '🇬🇭 Ghana';
      case '+226': return '🇧🇫 Burkina Faso';
      case '+241': return '🇬🇦 Gabon';
      default: return code;
    }
  }
}