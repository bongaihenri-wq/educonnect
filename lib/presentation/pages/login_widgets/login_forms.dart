import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';

class ParentLoginForm extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController matriculeController;

  const ParentLoginForm({
    super.key, 
    required this.phoneController, 
    required this.matriculeController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TÉLÉPHONE avec format +225 imposé
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Téléphone du parent',
            hintText: '+2250102030405',
            helperText: 'Format: +225 suivi du numéro',
            prefixIcon: const Icon(Icons.phone_android),
            prefixText: '+225 ',
            prefixStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10), // 10 chiffres après +225
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Numéro requis';
            }
            if (value.length < 10) {
              return 'Numéro incomplet (10 chiffres)';
            }
            return null;
          },
          onChanged: (value) {
            // Auto-formattage : ajoute +225 si absent
            if (value.isNotEmpty && !value.startsWith('+')) {
              // Le prefixText gère l'affichage, on stocke les chiffres
            }
          },
        ),
        const SizedBox(height: 16),
        
        // MATRICULE
        TextFormField(
          controller: matriculeController,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Matricule de l\'élève',
            hintText: 'MAT12345',
            helperText: 'Ex: MAT12345, ELV2024...',
            prefixIcon: const Icon(Icons.badge),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Matricule requis';
            }
            if (value.length < 3) {
              return 'Matricule trop court';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class TeacherLoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  const TeacherLoginForm({
    super.key, 
    required this.emailController, 
    required this.passwordController, 
    required this.obscurePassword, 
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // EMAIL
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Email professionnel',
            hintText: 'prenom.nom@ecole.com',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email requis';
            }
            if (!value.contains('@')) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // MOT DE PASSE
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onTogglePassword,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mot de passe requis';
            }
            if (value.length < 6) {
              return 'Minimum 6 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }
}