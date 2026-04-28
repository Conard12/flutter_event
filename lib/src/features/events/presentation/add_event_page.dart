import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;
  bool _dateWasSelected = false;

  // Palette de couleurs Modern-Luxury
  final Color accentColor = const Color(0xFF6366F1); // Indigo Vibrant
  final Color darkThemeColor = const Color(0xFF1E1B4B); // Bleu nuit profond

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    // 1. Sélection de la date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: DateTime(2030),
      builder:
          (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: accentColor,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
    );

    // PREMIER CHECK : Est-ce que l'utilisateur est toujours sur la page ?
    if (!mounted) return;

    if (pickedDate != null) {
      // 2. Sélection de l'heure
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      // DEUXIÈME CHECK : Indispensable après un await pour utiliser le BuildContext
      if (!mounted) return;

      if (pickedTime != null) {
        final DateTime finalDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // 3. Validation logique
        if (finalDate.isBefore(now)) {
          _showCustomSnackBar("L'heure est déjà passée !", isError: true);
        } else {
          setState(() {
            _selectedDate = finalDate;
            _dateWasSelected = true;
          });
        }
      }
    }
  }

  void _showCustomSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : accentColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // IMAGE D'EN-TÊTE AVEC FILTRE SOMBRE
          Container(
            height: 300,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: NetworkImage(
                  "https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?q=80&w=2070&auto=format&fit=crop",
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    darkThemeColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 220),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 40,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Création",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            Icon(Icons.auto_awesome, color: accentColor),
                          ],
                        ),
                        const SizedBox(height: 30),

                        _buildInputField(
                          controller: _titleController,
                          label: "Nom de l'événement",
                          hint: "Ex: Hackathon Cotonou 2026",
                          icon: Icons.star_border_rounded,
                        ),
                        const SizedBox(height: 20),

                        _buildInputField(
                          controller: _descController,
                          label: "Description détaillée",
                          hint: "Dites-nous en plus...",
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          "PLANIFICATION",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // SÉLECTEUR DATE PREMIUM
                        InkWell(
                          onTap: _pickDateTime,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    _dateWasSelected
                                        ? accentColor
                                        : Colors.grey[200]!,
                                width: 2,
                              ),
                              color:
                                  _dateWasSelected
                                      ? accentColor.withValues(alpha: 0.05)
                                      : Colors.grey[50],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color:
                                      _dateWasSelected
                                          ? accentColor
                                          : Colors.grey,
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _dateWasSelected
                                          ? "Date choisie"
                                          : "Quand ?",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _dateWasSelected
                                          ? "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} à ${_selectedDate.hour}h${_selectedDate.minute.toString().padLeft(2, '0')}"
                                          : "Sélectionner la date et l'heure",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(
                  alpha: 0.3,
                ), // Légèrement plus sombre pour le contraste
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _isLoading
              ? CircularProgressIndicator(color: accentColor)
              : Container(
                width: double.infinity,
                height: 65,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkThemeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 10,
                    shadowColor: darkThemeColor.withValues(alpha: 0.5),
                  ),
                  child: const Text(
                    "PUBLIER L'ÉVÉNEMENT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: accentColor),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate() || !_dateWasSelected) {
      _showCustomSnackBar(
        "Formulaire incomplet ou date invalide",
        isError: true,
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('events').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'event_date': _selectedDate.toIso8601String(),
        'creator_id': Supabase.instance.client.auth.currentUser?.id,
      });
      Navigator.pop(context);
    } catch (e) {
      _showCustomSnackBar("Erreur : $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
