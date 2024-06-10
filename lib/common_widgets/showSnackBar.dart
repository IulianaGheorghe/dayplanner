import 'package:dayplanner/util/constants.dart';
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String text){
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontFamily: font1,
          color: Colors.black
        ),
      ),
      backgroundColor: primaryColor,
    ),
  );
}