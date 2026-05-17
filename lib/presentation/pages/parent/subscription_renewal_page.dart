// lib/presentation/pages/parent/subscription_renewal_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class SubscriptionRenewalPage extends StatefulWidget {
  final String parentId;
  final String schoolId;
  final String? currentStatus;
  final DateTime? currentEndDate;
  final int? daysRemaining;
  final int amount;
  final String currency;
  final String? paymentPhoneNumber;

  const SubscriptionRenewalPage({
    super.key,
    required this.parentId,
    required this.schoolId,
    this.currentStatus,
    this.currentEndDate,
    this.daysRemaining,
    this.amount = 1000,
    this.currency = 'XOF',
    this.paymentPhoneNumber,
  });

  @override
  State<SubscriptionRenewalPage> createState() => _SubscriptionRenewalPageState();
}

class _SubscriptionRenewalPageState extends State<SubscriptionRenewalPage> {
  final _referenceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customAmountController = TextEditingController();
  bool _isSubmitting = false;
  int _selectedMonths = 1;
  bool _useCustomAmount = false;

  @override
  void dispose() {
    _referenceController.dispose();
    _phoneController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  int get _totalAmount {
    if (_useCustomAmount) {
      final custom = int.tryParse(_customAmountController.text) ?? 0;
      return custom;
    }
    return widget.amount * _selectedMonths;
  }

  int get _monthsFromAmount {
    if (_totalAmount <= 0) return 0;
    return (_totalAmount / widget.amount).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.currentStatus ?? 'no_subscription';
    final daysRemaining = widget.daysRemaining ?? 0;
    
    // ✅ CORRIGÉ : Couleurs visibles sur fond violet
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;
    Color textColor; // Nouvelle variable pour le texte
    
    switch (status) {
      case 'active':
        if (daysRemaining <= 7) {
          statusColor = Colors.orange;
          statusIcon = Icons.access_time;
          statusText = 'Expire bientôt';
          statusDescription = '$daysRemaining jours restants. Renouvelez maintenant !';
          textColor = Colors.orange.shade900;
        } else {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = 'Actif';
          statusDescription = '$daysRemaining jours restants. Vous pouvez renouveler à l\'avance.';
          textColor = Colors.green.shade900;
        }
        break;
      case 'trial':
        statusColor = Colors.lightBlue;
        statusIcon = Icons.new_releases;
        statusText = 'Période d\'essai';
        statusDescription = '$daysRemaining jours restants dans votre essai gratuit.';
        textColor = Colors.blue.shade900; // ✅ Texte foncé visible
        break;
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusText = 'Expiré';
        statusDescription = 'Votre accès est bloqué. Renouvelez immédiatement !';
        textColor = Colors.red.shade900;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Sans abonnement';
        statusDescription = 'Souscrivez pour accéder à toutes les fonctionnalités.';
        textColor = Colors.grey.shade800;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B4EFF),
              Color(0xFF9B7BFF),
              Colors.white,
            ],
            stops: [0.0, 0.4, 0.8],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Mon Abonnement',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 30),

                // ✅ CORRIGÉ : Statut avec texte foncé visible
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95), // Fond blanc opaque
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              statusDescription,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor, // ✅ Texte foncé visible
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 💰 Carte de paiement
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💳 Renouvellement',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.amount} ${widget.currency} / mois',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ⭐ BOUTONS PRÉDÉFINIS
                      if (!_useCustomAmount) ...[
                        const Text(
                          'Choisissez la durée',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildMonthButton(1, '1 mois'),
                            _buildMonthButton(3, '3 mois'),
                            _buildMonthButton(6, '6 mois'),
                            _buildMonthButton(9, '9 mois'), // ✅ 9 mois au lieu de 12
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ⭐ CHAMP PERSONNALISÉ
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _useCustomAmount ? 'Montant personnalisé' : 'Ou montant libre',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: _useCustomAmount,
                            onChanged: (value) {
                              setState(() {
                                _useCustomAmount = value;
                                if (!value) {
                                  _customAmountController.clear();
                                }
                              });
                            },
                            activeColor: const Color(0xFF6B4EFF),
                          ),
                        ],
                      ),
                      
                      if (_useCustomAmount) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _customAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Ex: 5000',
                            suffixText: widget.currency,
                            prefixIcon: const Icon(Icons.edit),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '≈ ${_monthsFromAmount} mois',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),

                      // Récap montant
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B4EFF), Color(0xFF9B7BFF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '💰 ',
                              style: TextStyle(fontSize: 24),
                            ),
                            Text(
                              '$_totalAmount',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              ' ${widget.currency}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Instructions
                      _buildPaymentStep(
                        number: '1',
                        icon: Icons.phone_android,
                        title: 'Faites un dépôt',
                        description: 'Envoyez $_totalAmount ${widget.currency} au numéro ci-dessous',
                      ),
                      const SizedBox(height: 12),

                      // Numéro de paiement
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, color: Color(0xFF6B4EFF)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Numéro de dépôt',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    widget.paymentPhoneNumber ?? 'Contactez l\'école',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B4EFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Color(0xFF6B4EFF)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('📋 Numéro copié')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildPaymentStep(
                        number: '2',
                        icon: Icons.receipt_long,
                        title: 'Saisissez la référence',
                        description: 'Entrez la référence de votre transaction',
                      ),
                      const SizedBox(height: 12),

                      // Champ référence
                      TextField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          hintText: 'Ex: MM123456789',
                          prefixIcon: const Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Champ téléphone
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: 'Votre numéro utilisé pour le dépôt (optionnel)',
                          prefixIcon: const Icon(Icons.phone_android),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),

                      // Bouton "J'ai payé"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting || _totalAmount <= 0 ? null : _submitPayment,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text(
                            _isSubmitting ? 'Envoi en cours...' : '✅ J\'ai payé $_totalAmount ${widget.currency}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Message motivation
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Color(0xFFFFB300), size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '💡 Chaque minute compte pour l\'avenir de votre enfant. Ne manquez plus aucune information !',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3142),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthButton(int months, String label) {
    final isSelected = _selectedMonths == months && !_useCustomAmount;
    final amount = widget.amount * months;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMonths = months;
          _useCustomAmount = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
            Text(
              '$amount ${widget.currency}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF6B4EFF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF6B4EFF)),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

   Future<void> _submitPayment() async {
    final reference = _referenceController.text.trim();
    if (reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez saisir la référence de transaction'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Le montant doit être supérieur à 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ⭐ CORRIGÉ : Ajout schoolId
      context.read<AuthBloc>().add(
        PaymentReferenceSubmitted(
          parentId: widget.parentId,
          schoolId: widget.schoolId, // ⭐ AJOUTÉ
          reference: reference,
          amount: _totalAmount.toDouble(),
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        ),
      );

      // ✅ AFFICHER DIALOG LOCAL avant de pop
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade600,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '✅ Demande envoyée !',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Référence', reference),
                      const Divider(height: 16),
                      _buildDetailRow('Montant', '$_totalAmount ${widget.currency}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre paiement est en attente de validation par l\'administrateur.\n'
                  'Vous recevrez une notification dès qu\'il sera validé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B4EFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK, j\'ai compris',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Retour au dashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }
}