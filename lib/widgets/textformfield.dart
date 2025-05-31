import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTextForm extends StatefulWidget {
  final String hinttext;
  final TextEditingController myController;
  final IconData icon;
  final bool isPassword;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool isDatePicker;
  final bool isDropdown;
  final TextInputType? keyboardType;
  final List<String>? dropdownItems;
  final ValueChanged<String?>? onDropdownChanged;
  final int? maxLines;
  final double? iconSize;
  final double? fontSize;
  final String? Function(String?)? validator;
  final VoidCallback? onTap; // أضفنا خاصية onTap هنا

  const CustomTextForm({
    super.key,
    required this.hinttext,
    required this.myController,
    required this.icon,
    this.isPassword = false,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.isDatePicker = false,
    this.isDropdown = false,
    this.dropdownItems,
    this.keyboardType,
    this.onDropdownChanged,
    this.maxLines = 1,
    this.iconSize = 24,
    this.fontSize = 16,
    this.validator,
    this.onTap, // أضفنا المعامل هنا
  });

  @override
  _CustomTextFormState createState() => _CustomTextFormState();
}

class _CustomTextFormState extends State<CustomTextForm> {
  bool _isPasswordVisible = false;

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: DateTime.now(),
            minimumDate: DateTime(1900),
            maximumDate: DateTime.now(),
            onDateTimeChanged: (date) {
              setState(() {
                widget.myController.text = DateFormat('yyyy-MM-dd').format(date);
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: 'Zain',
      fontSize: widget.fontSize,
    );

    if (widget.isDatePicker) {
      return GestureDetector(
        onTap: _showDatePicker,
        child: AbsorbPointer(
          child: TextFormField(
            controller: widget.myController,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            style: textStyle,
            validator: widget.validator,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.teal, width: 1),
              ),
              hintText: widget.hinttext,
              hintStyle: textStyle,
              prefixIcon: Icon(widget.icon, size: widget.iconSize, color: Color(0xFF139799)),
              suffixIcon: Icon(Icons.calendar_today, size: widget.iconSize, color: Colors.teal),
              errorStyle: TextStyle(fontFamily: 'Zain'),
            ),
          ),
        ),
      );
    }

    if (widget.isDropdown && widget.dropdownItems != null) {
      return DropdownButtonFormField<String>(
        style: textStyle,
        validator: widget.validator,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal, width: 1),
          ),
          hintText: widget.hinttext,
          hintStyle: textStyle,
          prefixIcon: Icon(widget.icon, size: widget.iconSize, color: Color(0xFF139799)),
          errorStyle: TextStyle(fontFamily: 'Zain'),
        ),
        dropdownColor: Colors.grey[200],
        icon: Icon(Icons.arrow_drop_down, size: widget.iconSize),
        items: widget.dropdownItems!.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: textStyle),
          );
        }).toList(),
        onChanged: widget.onDropdownChanged,
      );
    }

    return GestureDetector(
      onTap: widget.onTap, // استخدمنا onTap هنا
      child: TextFormField(
        controller: widget.myController,
        obscureText: widget.isPassword ? !_isPasswordVisible : false,
        maxLines: widget.maxLines,
        style: textStyle,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal, width: 1),
          ),
          hintText: widget.hinttext,
          hintStyle: textStyle,
          prefixIcon: Icon(widget.icon, size: widget.iconSize, color: Color(0xFF139799)),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.teal,
                    size: widget.iconSize,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : (widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(widget.suffixIcon, size: widget.iconSize, color: Color(0xFF139799)),
                      onPressed: widget.onSuffixIconPressed,
                    )
                  : null),
          errorStyle: TextStyle(fontFamily: 'Zain'),
        ),
      ),
    );
  }
}