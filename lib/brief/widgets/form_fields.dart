// lib/brief/widgets/form_fields.dart

import 'package:flutter/material.dart';

class FormFields {

  static Widget buildLabel(String text, {BuildContext? context}) {
    Color? color;
    if (context != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      color = isDark ? Colors.grey[300] : const Color(0xFF2C3E50);
    } else {
      color = const Color(0xFF2C3E50);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
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
    BuildContext? context,
  }) {
    final bool isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color readOnlyTextColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final Color fillColor = readOnly
        ? (isDark ? Colors.grey[900]! : Colors.grey[100]!)
        : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA));
    final Color borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final Color primaryColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      style: TextStyle(
          fontSize: 13,
          color: readOnly ? readOnlyTextColor : textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400], fontSize: 12),
        fillColor: fillColor,
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
                color: readOnly ? (isDark ? Colors.grey[800]! : Colors.grey[300]!) : borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: readOnly
                ? BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!)
                : BorderSide(color: primaryColor, width: 1.5)),
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
    BuildContext? context,
  }) {
    final bool isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color readOnlyTextColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final Color fillColor = readOnly
        ? (isDark ? Colors.grey[900]! : Colors.grey[100]!)
        : (isDark ? const Color(0xFF2C2C2C) : Colors.white);
    final Color borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final Color primaryColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label, context: context),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
              fontSize: 13,
              color: readOnly ? readOnlyTextColor : textColor),
          decoration: InputDecoration(
            isDense: true,
            fillColor: fillColor,
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: readOnly ? (isDark ? Colors.grey[800]! : Colors.grey[300]!) : borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: readOnly
                    ? BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!)
                    : BorderSide(color: primaryColor, width: 1.5)),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color readOnlyTextColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final Color fillColor = readOnly
        ? (isDark ? Colors.grey[900]! : Colors.grey[100]!)
        : (isDark ? const Color(0xFF2C2C2C) : Colors.white);
    final Color borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final Color primaryColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label, context: context),
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
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark
                              ? ColorScheme.dark(primary: primaryColor, onPrimary: Colors.black)
                              : ColorScheme.light(primary: primaryColor, onPrimary: Colors.white),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) onDateSelected(picked);
                },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: readOnly ? (isDark ? Colors.grey[800]! : Colors.grey[300]!) : borderColor),
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
                          ? readOnlyTextColor
                          : textColor),
                ),
                Icon(Icons.calendar_today,
                    size: 16,
                    color: readOnly
                        ? (isDark ? Colors.grey[600] : Colors.grey[400])
                        : primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildSignatureBox(String label, {BuildContext? context}) {
    final bool isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA);
    final Color borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final Color textColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      width: 140,
      height: 60,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
