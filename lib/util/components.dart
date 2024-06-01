import 'package:flutter/material.dart';
import 'constants.dart';

class Box {
  InputDecoration textInputDecoration([String labelText="", String hintText = ""]){
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.fromLTRB(marginSize, marginSize, marginSize, marginSize),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100.0), borderSide: const BorderSide(color: Colors.grey)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100.0), borderSide: BorderSide(color: Colors.grey.shade400)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100.0), borderSide: const BorderSide(color: Colors.red, width: 2.0)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100.0), borderSide: const BorderSide(color: Colors.red, width: 2.0)),
    );
  }

  BoxDecoration inputBoxDecorationShadow() {
    return BoxDecoration(boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 5),
      )
    ]);
  }

}

InputDecoration addPageInputStyle(String labelText) {
  return InputDecoration(
    hintText: labelText,
    hintStyle: const TextStyle(color: Colors.grey),
    labelStyle: const TextStyle(color: inputDecorationColor),
    filled: true,
    fillColor: Colors.white.withOpacity(0.8),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide.none
    ),
  );
}

Text titleStyle(String title, double size) {
  return Text(
      title,
      style: TextStyle(
        color: Colors.black,
        fontSize: size,
        fontFamily: font1,
      )
  );
}

Color getColorForPriority(String option) {
  switch (option) {
    case 'Low':
      return Colors.blue;
    case 'Medium':
      return Colors.orange;
    case 'High':
      return Colors.red;
    default:
      return Colors.white;
  }
}
