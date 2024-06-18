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
      floatingLabelBehavior: FloatingLabelBehavior.never,
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

Text titleStyle(String title, double size, TextAlign textAlignment) {
  return Text(
      title,
      style: TextStyle(
        color: Colors.black,
        fontSize: size,
        fontFamily: font1,
      ),
    textAlign: textAlignment,
  );
}

Container detailsContainer(String title, String content, TextAlign textAlignment) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(10),
    child: ListTile(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Center(
          child: titleStyle(title, secondaryTitleSize, textAlignment),
        )
      ),
      subtitle: Text(
        content,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        textAlign: textAlignment,
      ),
    ),
  );
}

Widget customTooltip(String text) {
  return Transform.translate(
    offset: const Offset(0, -10),
    child: Tooltip(
      message: text,
      preferBelow: false,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      margin: const EdgeInsets.only(left: 40, right: 40),
      padding: const EdgeInsets.all(15),
      child: const Icon(Icons.info_outline, color: secondColor,),
    ),
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
