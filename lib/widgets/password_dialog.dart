import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class PasswordDialog extends StatefulWidget {
  final VoidCallback onPasswordCorrect;

  const PasswordDialog({Key? key, required this.onPasswordCorrect}) : super(key: key);

  @override
  _PasswordDialogState createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  String? _errorText;
  final String _correctPassword = "Faten1979F";

  void _checkPassword(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_passwordController.text.isEmpty) {
       setState(() {
         _errorText = appLocalizations.passwordRequired;
       });
       return;
    }

    if (_passwordController.text == _correctPassword) {
      widget.onPasswordCorrect();
    } else {
      setState(() {
        _errorText = appLocalizations.wrongPassword;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async => false, // Prevent dialog from closing by back button
      child: AlertDialog(
        title: Text(appLocalizations.passwordDialogTitle),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            hintText: appLocalizations.passwordHintText,
            errorText: _errorText,
          ),
          onSubmitted: (_) => _checkPassword(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _checkPassword(context),
            child: Text(appLocalizations.submit),
          ),
        ],
      ),
    );
  }
}
