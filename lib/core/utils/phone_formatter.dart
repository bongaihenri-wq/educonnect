// lib/core/utils/phone_formatter.dart
class PhoneFormatter {
  /// Normalise un numéro de téléphone avec l'indicatif pays
  /// 
  /// Exemples:
  /// - normalize("0506224449", "+225") → "+2250506224449"
  /// - normalize("+2250506224449", "+225") → "+2250506224449"
  /// - normalize("0506224449", "+221") → "+2210506224449"
  static String normalize(String input, String countryCode) {
    // Supprime tout sauf chiffres et +
    String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si déjà complet avec +, retourne tel quel
    if (cleaned.startsWith('+')) return cleaned;
    
    // Si commence par l'indicatif sans +, ajoute +
    String countryDigits = countryCode.replaceAll('+', '');
    if (cleaned.startsWith(countryDigits)) {
      return '+$cleaned';
    }
    
    // Si commence par 0, remplace par l'indicatif
    if (cleaned.startsWith('0')) {
      return '$countryCode${cleaned.substring(1)}';
    }
    
    // Sinon ajoute l'indicatif complet
    return '$countryCode$cleaned';
  }
  
  /// Formate pour l'affichage: +225 05 06 22 44 49
  static String display(String phone) {
    if (phone.length < 10) return phone;
    
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10) return phone;
    
    String country = digits.substring(0, 3);
    String rest = digits.substring(3);
    
    if (rest.length >= 8) {
      return '+$country ${rest.substring(0, 2)} ${rest.substring(2, 4)} ${rest.substring(4, 6)} ${rest.substring(6)}';
    }
    
    return '+$country $rest';
  }
}