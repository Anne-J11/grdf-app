import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String elevatedButtonText;
  final String textButtonText;
  final VoidCallback elevatedButtonClicked;
  final VoidCallback textButtonClicked;

  const CustomButton({
    super.key,
    required this.elevatedButtonText,
    required this.textButtonText,
    required this.elevatedButtonClicked,
    required this.textButtonClicked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: elevatedButtonClicked,
          child: Text(elevatedButtonText),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: textButtonClicked,
          child: Text(textButtonText),
        ),
      ],
    );
  }
}