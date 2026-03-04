// lib/brief/widgets/form_fields_old.dart

import 'package:flutter/material.dart';

class FormFields {
  // Label de champ
  static Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.blueGrey[800],
        ),
      ),
    );
  }

  // Champ texte standard
  static Widget buildTextField({
    required TextEditingController controller,
    int maxLines = 1,
    String? hint,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(hint: hint),
      validator: isRequired 
          ? (value) => value?.isEmpty ?? true ? 'Requis' : null 
          : null,
    );
  }

  // Petit champ compact (pour header)
  static Widget buildSmallField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[400],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            fillColor: const Color(0xFFF1F3F5),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
        ),
      ],
    );
  }

  // Champ statique (non éditable)
  static Widget buildSmallFieldStatic({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[400],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // Sélecteur de date
  static Widget buildDateField({
    required BuildContext context,
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[400],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onDateSelected(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.blueGrey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Box de signature
  static Widget buildSignatureBox(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[400],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 70,
          width: 105,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Center(
            child: Icon(Icons.edit_outlined, color: Colors.grey[300]),
          ),
        ),
      ],
    );
  }

  // Décoration d'input
  static InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF33A1C9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}
