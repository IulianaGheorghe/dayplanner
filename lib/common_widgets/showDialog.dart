import 'package:flutter/material.dart';
import '../util/constants.dart';

class ShowDialog extends StatefulWidget {
  const ShowDialog({
    super.key,
    required this.title,
    required this.inputText,
    required this.onPressedFunction,
    required this.buttonText,
  });

  final String title;
  final String inputText;
  final Future<void> Function(String controllerText, void Function(String?) setError) onPressedFunction;
  final String buttonText;

  @override
  State<ShowDialog> createState() => _ShowDialogState();
}

class _ShowDialogState extends State<ShowDialog> {
  TextEditingController dialogController = TextEditingController();
  String? dialogLocalErrorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: const TextStyle(fontFamily: font1),
      ),
      content: TextField(
        controller: dialogController,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: widget.inputText,
          errorText: dialogLocalErrorMessage,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            dialogController.clear();
            setState(() {
              dialogLocalErrorMessage = null;
            });
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: primaryColor),
          ),
        ),
        TextButton(
          onPressed: () async {
            if (dialogController.text.isEmpty) {
              setState(() {
                dialogLocalErrorMessage = 'This field cannot be empty';
              });
            } else {
              await widget.onPressedFunction(dialogController.text, (error) {
                setState(() {
                  dialogLocalErrorMessage = error;
                });
              });
            }
          },
          child: Text(
            widget.buttonText,
            style: const TextStyle(color: primaryColor),
          ),
        ),
      ],
    );
  }
}
