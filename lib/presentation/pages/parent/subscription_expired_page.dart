// lib/presentation/pages/parent/subscription_expired_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../services/payment_number_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class SubscriptionExpiredPage extends StatefulWidget {
  final String parentId;
  final String? schoolId;
  final DateTime? expiresAt;
  final int? daysRemaining;
  final String? currentStatus;

  const SubscriptionExpiredPage({
    super.key,
    required this.parentId,
    this.schoolId,
    this.expiresAt,
    this.daysRemaining,
    this.currentStatus,
    required int amount,
    required String currency,
    String? paymentPhoneNumber,
  });

  @override
  State<SubscriptionExpiredPage> createState() =>
      _SubscriptionExpiredPageState();
}

class _SubscriptionExpiredPageState extends State<SubscriptionExpiredPage> {
  final _referenceController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingNumbers = true;
  List<Map<String, dynamic>> _paymentNumbers = [];
  Map<String, dynamic>? _selectedNumber;

  @override
  void initState() {
    super.initState();
    _loadPaymentNumbers();
  }

  Future<void> _loadPaymentNumbers() async {
    try {
      final service = PaymentNumberService(Supabase.instance.client);
      final numbers = await service.getParentPaymentInfo(widget.parentId);

      // Si getParentPaymentInfo retourne un seul numéro, on le convertit en liste
      if (numbers != null) {
        setState(() {
          _paymentNumbers = [numbers];
          _selectedNumber = numbers;
          _isLoadingNumbers = false;
        });
      } else {
        // Fallback : charger tous les numéros actifs
        final allNumbers = await service.getPaymentNumbersByCountry('+225');
        setState(() {
          _paymentNumbers = allNumbers;
          if (allNumbers.isNotEmpty) _selectedNumber = allNumbers.first;
          _isLoadingNumbers = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingNumbers = false);
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<AuthBloc>().add(const LogoutRequested());
  }

  String get _monthlyAmount {
    return '${_selectedNumber?['monthly_amount'] ?? 1000} ${_selectedNumber?['currency'] ?? 'XOF'}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is Unauthenticated,
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              label: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6B4EFF), Color(0xFF9B7BFF), Colors.white],
              stops: [0.0, 0.35, 0.7],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icône + Message
                  _buildHeader(),
                  const SizedBox(height: 32),

                  // Carte principale
                  _buildPaymentCard(),
                  const SizedBox(height: 24),

                  // Message motivation
                  _buildMotivationCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final daysExpired =
        widget.daysRemaining != null && widget.daysRemaining! < 0
            ? widget.daysRemaining!.abs()
            : 0;

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_clock, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          'Votre accès est temporairement suspendu',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            daysExpired > 0
                ? '⏰ Expiré depuis $daysExpired jour${daysExpired > 1 ? 's' : ''}'
                : '👋 Renouvelez pour retrouver l\'accès',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6D00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_clock,
                    color: Color(0xFFFF6D00), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Renouvellement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    Text(
                      '$_monthlyAmount / mois',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Étape 1 : Numéros de paiement
          _buildStep(
            number: '1',
            title: 'Effectuez un dépôt',
            child: _isLoadingNumbers
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _paymentNumbers.isEmpty
                    ? _buildFallbackNumber()
                    : _buildNumbersList(),
          ),
          const SizedBox(height: 20),

          // Étape 2 : Référence
          _buildStep(
            number: '2',
            title: 'Saisissez la référence',
            child: Column(
              children: [
                TextField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    hintText: 'Ex: WAVE123456 ou MM789012',
                    prefixIcon: const Icon(Icons.confirmation_number,
                        color: Color(0xFF6B4EFF)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B4EFF), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Votre numéro utilisé pour le dépôt',
                    prefixIcon: const Icon(Icons.phone_android,
                        color: Color(0xFF6B4EFF)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bouton
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitPayment,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(
                _isSubmitting ? 'Envoi en cours...' : '✅ J\'ai payé',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Support
          Center(
            child: TextButton.icon(
              onPressed: () {/* TODO: Support */},
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Un problème ? Contactez-nous'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumbersList() {
    return Column(
      children: _paymentNumbers.map((number) {
        final isSelected =
            _selectedNumber?['phone_number'] == number['phone_number'];
        final provider = number['provider'] ?? 'Mobile Money';
        final phone = number['phone_number'] ?? '';
        final accountName = number['account_name'] ?? 'EduConnect';

        return InkWell(
          onTap: () => setState(() => _selectedNumber = number),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF3F0FF)
                  : const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF6B4EFF) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4EFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getProviderIcon(provider),
                    color: const Color(0xFF6B4EFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        accountName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF00C853)),
                IconButton(
                  icon: const Icon(Icons.copy,
                      color: Color(0xFF6B4EFF), size: 20),
                  onPressed: () {
                    // TODO: Copy to clipboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('📋 Numéro copié'),
                          duration: Duration(seconds: 2)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFallbackNumber() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aucun numéro configuré. Contactez l\'administration.',
              style: TextStyle(color: Colors.orange[800], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
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
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb, color: Color(0xFFFFB300), size: 28),
          SizedBox(width: 14),
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
    );
  }

  IconData _getProviderIcon(String provider) {
    final p = provider.toLowerCase();
    if (p.contains('orange')) return Icons.phone_android;
    if (p.contains('mtn')) return Icons.signal_cellular_alt;
    if (p.contains('wave')) return Icons.waves;
    if (p.contains('moov')) return Icons.network_cell;
    return Icons.account_balance_wallet;
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

    setState(() => _isSubmitting = true);

    try {
      context.read<AuthBloc>().add(
            PaymentReferenceSubmitted(
              parentId: widget.parentId,
              schoolId: widget.schoolId ?? '',
              reference: reference,
              amount: (_selectedNumber?['monthly_amount'] ?? 1000).toDouble(),
              phoneNumber: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
            ),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Demande envoyée ! Validation en cours...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
