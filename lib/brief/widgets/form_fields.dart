// lib/brief/widgets/form_fields.dart
// Modification : ajout du paramètre readOnly sur les 3 builders de champs
// pour supporter le mode lecture seule des briefs verrouillés.
// Le reste (styles, logique, signatures box) est identique.

import 'package:flutter/material.dart';

class FormFields {

  static Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  static Widget buildTextField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool isRequired = true,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      style: TextStyle(
          fontSize: 13,
          color: readOnly ? Colors.grey[600] : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
        fillColor: readOnly ? Colors.grey[100] : const Color(0xFFF8F9FA),
        filled: true,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: readOnly ? Colors.grey[300]! : Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: readOnly
                ? BorderSide(color: Colors.grey[300]!)
                : const BorderSide(color: Color(0xFF33A1C9), width: 1.5)),
      ),
      validator: isRequired && !readOnly
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ est requis';
              }
              return null;
            }
          : null,
    );
  }

  static Widget buildSmallField({
    required String label,
    required TextEditingController controller,
    bool isRequired = true,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
              fontSize: 13,
              color: readOnly ? Colors.grey[600] : Colors.black87),
          decoration: InputDecoration(
            isDense: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: readOnly ? Colors.grey[300]! : Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: readOnly
                    ? BorderSide(color: Colors.grey[300]!)
                    : const BorderSide(color: Color(0xFF33A1C9), width: 1.5)),
          ),
          validator: isRequired && !readOnly
              ? (value) {
                  if (value == null || value.trim().isEmpty) return 'Requis';
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  static Widget buildDateField({
    required BuildContext context,
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onDateSelected,
    bool isRequired = true,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        InkWell(
          onTap: readOnly
              ? null
              : () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (picked != null) onDateSelected(picked);
                },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: readOnly ? Colors.grey[100] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: readOnly ? Colors.grey[300]! : Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDate.day.toString().padLeft(2, '0')}/'
                  '${selectedDate.month.toString().padLeft(2, '0')}/'
                  '${selectedDate.year}',
                  style: TextStyle(
                      fontSize: 13,
                      color: readOnly
                          ? Colors.grey[600]
                          : Colors.black87),
                ),
                Icon(Icons.calendar_today,
                    size: 16,
                    color: readOnly
                        ? Colors.grey[400]
                        : const Color(0xFF33A1C9)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildSignatureBox(String label) {
    return Container(
      width: 140,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
