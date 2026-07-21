// lib/presentation/pages/super_admin/subscriptions/payment_numbers_management_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/payment_number_service.dart';

class PaymentNumbersManagementPage extends StatefulWidget {
  const PaymentNumbersManagementPage({super.key});

  @override
  State<PaymentNumbersManagementPage> createState() =>
      _PaymentNumbersManagementPageState();
}

class _PaymentNumbersManagementPageState
    extends State<PaymentNumbersManagementPage> {
  final _service = PaymentNumberService(Supabase.instance.client);
  List<Map<String, dynamic>> _numbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNumbers();
  }

  Future<void> _loadNumbers() async {
    setState(() => _isLoading = true);
    try {
      final numbers = await _service.getAllPaymentNumbers();
      setState(() {
        _numbers = numbers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur chargement: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Numéros de paiement'),
        backgroundColor: const Color(0xFF6B4EFF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNumbers,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: const Color(0xFF6B4EFF),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _numbers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNumbers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _numbers.length,
                    itemBuilder: (context, index) =>
                        _buildNumberCard(_numbers[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun numéro configuré',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un numéro'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF)),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberCard(Map<String, dynamic> number) {
    final isPrimary = number['is_primary'] == true;
    final isActive = number['is_active'] != false;
    final countryCode = number['country_code'] ?? '';
    final provider = number['provider'] ?? '';
    final phone = number['phone_number'] ?? '';
    final amount = number['monthly_amount'] ?? 1000;
    final currency = number['currency'] ?? 'XOF';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPrimary ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPrimary ? const Color(0xFF6B4EFF) : Colors.grey[300]!,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCountryColor(countryCode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    countryCode,
                    style: TextStyle(
                      color: _getCountryColor(countryCode),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isPrimary)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRINCIPAL',
                      style: TextStyle(
                        color: Color(0xFF6B4EFF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'INACTIF',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'primary':
                        _setPrimary(number['id']);
                        break;
                      case 'toggle':
                        _toggleActive(number['id'], !isActive);
                        break;
                      case 'edit':
                        _showEditDialog(number);
                        break;
                      case 'delete':
                        _deleteNumber(number['id']);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isPrimary)
                      const PopupMenuItem(
                          value: 'primary',
                          child: Text('🌟 Définir principal')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(isActive ? '⏸️ Désactiver' : '▶️ Activer'),
                    ),
                    const PopupMenuItem(
                        value: 'edit', child: Text('✏️ Modifier')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('🗑️ Supprimer',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              provider,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$amount $currency/mois',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCountryColor(String code) {
    switch (code) {
      case '+225':
        return const Color(0xFFFF6D00); // CI - Orange
      case '+237':
        return const Color(0xFF00C853); // CM - Green
      case '+221':
        return const Color(0xFF6B4EFF); // SN - Violet
      default:
        return Colors.grey;
    }
  }

  Future<void> _setPrimary(String id) async {
    try {
      await _service.updatePaymentNumber(id: id, isPrimary: true);
      _loadNumbers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Numéro principal défini'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleActive(String id, bool active) async {
    try {
      await _service.updatePaymentNumber(id: id, isActive: active);
      _loadNumbers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteNumber(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce numéro ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deletePaymentNumber(id);
        _loadNumbers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🗑️ Numéro supprimé'),
              backgroundColor: Colors.grey),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddDialog() {
    _showEditDialog(null);
  }

  void _showEditDialog(Map<String, dynamic>? existing) {
    final countryCodeController =
        TextEditingController(text: existing?['country_code'] ?? '+225');
    final countryNameController = TextEditingController(
        text: existing?['country_name'] ?? 'Côte d\'Ivoire');
    final providerController =
        TextEditingController(text: existing?['provider'] ?? '');
    final phoneController =
        TextEditingController(text: existing?['phone_number'] ?? '');
    final accountController =
        TextEditingController(text: existing?['account_name'] ?? 'EduConnect');
    final amountController = TextEditingController(
        text: (existing?['monthly_amount'] ?? 1000).toString());
    final currencyController =
        TextEditingController(text: existing?['currency'] ?? 'XOF');
    bool isPrimary = existing?['is_primary'] == true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null
              ? '➕ Ajouter un numéro'
              : '✏️ Modifier le numéro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Code pays
                DropdownButtonFormField<String>(
                  value: countryCodeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Pays',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: '+225',
                        child: Text('🇨🇮 Côte d\'Ivoire (+225)')),
                    DropdownMenuItem(
                        value: '+237', child: Text('🇨🇲 Cameroun (+237)')),
                    DropdownMenuItem(
                        value: '+221', child: Text('🇸🇳 Sénégal (+221)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      countryCodeController.text = value;
                      // Auto-fill country name
                      switch (value) {
                        case '+225':
                          countryNameController.text = 'Côte d\'Ivoire';
                          currencyController.text = 'XOF';
                          break;
                        case '+237':
                          countryNameController.text = 'Cameroun';
                          currencyController.text = 'XAF';
                          break;
                        case '+221':
                          countryNameController.text = 'Sénégal';
                          currencyController.text = 'XOF';
                          break;
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerController,
                  decoration: const InputDecoration(
                    labelText: 'Opérateur (ex: Orange Money)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accountController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du compte',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Montant mensuel',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Devise (XOF, XAF...)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Numéro principal'),
                  subtitle: const Text('Affiché par défaut aux parents'),
                  value: isPrimary,
                  onChanged: (v) =>
                      setDialogState(() => isPrimary = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (providerController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '❌ Veuillez remplir tous les champs obligatoires'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                try {
                  if (existing == null) {
                    await _service.createPaymentNumber(
                      countryCode: countryCodeController.text,
                      countryName: countryNameController.text,
                      provider: providerController.text,
                      phoneNumber: phoneController.text,
                      accountName: accountController.text.isEmpty
                          ? null
                          : accountController.text,
                      isPrimary: isPrimary,
                      monthlyAmount:
                          int.tryParse(amountController.text) ?? 1000,
                      currency: currencyController.text,
                    );
                  } else {
                    await _service.updatePaymentNumber(
                      id: existing['id'],
                      phoneNumber: phoneController.text,
                      accountName: accountController.text.isEmpty
                          ? null
                          : accountController.text,
                      isPrimary: isPrimary,
                      monthlyAmount: int.tryParse(amountController.text),
                    );
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadNumbers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(existing == null
                            ? '✅ Numéro ajouté'
                            : '✅ Numéro modifié'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF)),
              child: const Text('Enregistrer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
