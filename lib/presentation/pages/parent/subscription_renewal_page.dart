// lib/presentation/pages/parent/subscription_renewal_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../blocs/auth_bloc/auth_bloc.dart';

class SubscriptionRenewalPage extends StatefulWidget {
  final String parentId;
  final String? schoolId;
  final int amount;
  final String currency;
  final String? paymentPhoneNumber;
  final String? currentStatus;      // ✅ AJOUTÉ
  final DateTime? currentEndDate;   // ✅ AJOUTÉ
  final int? daysRemaining;       // ✅ AJOUTÉ

  const SubscriptionRenewalPage({
    super.key,
    required this.parentId,
    this.schoolId,
    required this.amount,
    required this.currency,
    this.paymentPhoneNumber,
    this.currentStatus,
    this.currentEndDate,
    this.daysRemaining,
  });

  @override
  State<SubscriptionRenewalPage> createState() => _SubscriptionRenewalPageState();
}

class _SubscriptionRenewalPageState extends State<SubscriptionRenewalPage> {
  final _refController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customMonthsController = TextEditingController();
  File? _screenshotFile;
  bool _isUploading = false;
  final _picker = ImagePicker();

  int _selectedMonths = 1;
  bool _isCustom = false;
  final List<int> _presetMonths = [1, 3, 6, 9];

  int get _totalAmount => _selectedMonths * widget.amount;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _screenshotFile = File(picked.path));
    }
  }

  Future<String?> _uploadScreenshot() async {
    if (_screenshotFile == null) return null;
    try {
      final ext = _screenshotFile!.path.split('.').last;
      final fileName = '${widget.parentId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = 'payments/$fileName';

      await Supabase.instance.client.storage
          .from('payment-screenshots')
          .upload(path, _screenshotFile!, fileOptions: const FileOptions(upsert: true));

      final url = Supabase.instance.client.storage
          .from('payment-screenshots')
          .getPublicUrl(path);

      return url;
    } catch (e) {
      print('Erreur upload screenshot: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (_refController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir la référence de paiement')),
      );
      return;
    }

    if (_isCustom) {
      final custom = int.tryParse(_customMonthsController.text.trim());
      if (custom == null || custom < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez saisir un nombre de mois valide')),
        );
        return;
      }
      setState(() => _selectedMonths = custom);
    }

    setState(() => _isUploading = true);

    String? screenshotUrl;
    if (_screenshotFile != null) {
      screenshotUrl = await _uploadScreenshot();
    }

    if (!mounted) return;

    context.read<AuthBloc>().add(PaymentReferenceSubmitted(
          parentId: widget.parentId,
          schoolId: widget.schoolId ?? '',
          reference: _refController.text.trim(),
          amount: _totalAmount.toDouble(),
          phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          screenshotUrl: screenshotUrl,
        ));
  }

  String _getStatusTitle() {
    switch (widget.currentStatus) {
      case 'trial':
        return 'Essai en cours';
      case 'active':
        return 'Abonnement actif';
      case 'expired':
        return 'Abonnement expiré';
      case 'no_subscription':
        return 'Aucun abonnement';
      default:
        return 'Abonnement expiré';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Renouvellement'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PaymentSubmittedSuccessfully) {
            Navigator.of(context).pushReplacementNamed('/paymentPending');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
            setState(() => _isUploading = false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Carte info avec statut dynamique
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4A44D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusTitle(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (widget.daysRemaining != null && widget.daysRemaining! < 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Expiré depuis ${widget.daysRemaining!.abs()} jours',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '$_totalAmount ${widget.currency}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'pour $_selectedMonths mois',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (widget.paymentPhoneNumber != null)
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Déposer sur : ${widget.paymentPhoneNumber}',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Sélecteur de mois
              const Text(
                'Durée de l\'abonnement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._presetMonths.map((months) => _buildMonthChip(months)),
                  _buildCustomChip(),
                ],
              ),
              if (_isCustom) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customMonthsController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    if (val != null && val > 0) {
                      setState(() => _selectedMonths = val);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Nombre de mois personnalisé',
                    hintText: 'Ex: 5',
                    prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF6C63FF)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              const Text(
                'Instructions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInstruction('1', 'Effectuez le paiement de $_totalAmount ${widget.currency} au numéro ci-dessus'),
              _buildInstruction('2', 'Conservez la capture d\'écran du dépôt'),
              _buildInstruction('3', 'Saisissez la référence et envoyez'),
              const SizedBox(height: 24),
              TextField(
                controller: _refController,
                decoration: InputDecoration(
                  labelText: 'Référence de paiement',
                  hintText: 'Ex: WAVE123456',
                  prefixIcon: const Icon(Icons.confirmation_number),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro déposant (optionnel)',
                  hintText: 'Ex: +2250706224549',
                  prefixIcon: const Icon(Icons.phone_android),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Capture d\'écran du dépôt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3), width: 2),
                  ),
                  child: _screenshotFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_screenshotFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 48, color: const Color(0xFF6C63FF).withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'Appuyez pour ajouter une capture',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Soumettre ($_totalAmount ${widget.currency})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthChip(int months) {
    final isSelected = !_isCustom && _selectedMonths == months;
    return ChoiceChip(
      label: Text(
        '$months mois',
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF6C63FF),
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF6C63FF),
      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        setState(() {
          _selectedMonths = months;
          _isCustom = false;
        });
      },
    );
  }

  Widget _buildCustomChip() {
    return ChoiceChip(
      label: Text(
        'Personnalisé',
        style: TextStyle(
          color: _isCustom ? Colors.white : const Color(0xFF6C63FF),
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: _isCustom,
      selectedColor: const Color(0xFF6C63FF),
      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        setState(() {
          _isCustom = true;
          _selectedMonths = int.tryParse(_customMonthsController.text) ?? 1;
        });
      },
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ),
        ],
      ),
    );
  }
}