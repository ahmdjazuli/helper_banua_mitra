import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool readOnly;
  final bool isPassword;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final Color labelColor; // Parameter untuk menyesuaikan latar belakang (Hitam / Putih)

  const CustomInputField({
    super.key,
    required this.icon,
    required this.label,
    required this.hintText,
    this.controller,
    this.readOnly = false,
    this.isPassword = false,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.onTap,
    this.labelColor = Colors.white, // Default untuk halaman Login
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. JUDUL LABEL DI LUAR KOTAK INPUT FIELD
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),

          // 2. KOTAK INPUT FIELD
          TextField(
            controller: controller,
            readOnly: readOnly,
            obscureText: isPassword ? obscureText : false,
            keyboardType: keyboardType,
            onTap: onTap,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(icon, color: Colors.grey.shade700),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFFD600),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}