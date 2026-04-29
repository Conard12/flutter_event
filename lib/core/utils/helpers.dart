import 'package:intl/intl.dart';

// Formatage des dates
String formatDate(DateTime date) {
  return DateFormat('dd/MM').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('dd/MM/yyyy à HH:mm').format(date);
}

String formatTime(DateTime date) {
  return DateFormat('HH:mm').format(date);
}

// Validation email
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

// Capitalisation
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

// Troncature de texte
String truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

// Obtenir le nom du mois
String getMonthName(int month) {
  const months = [
    'JAN', 'FEV', 'MAR', 'AVR', 'MAI', 'JUN',
    'JUL', 'AOU', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  return months[month - 1];
}