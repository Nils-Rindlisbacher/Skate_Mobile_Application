import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/pages/signin_page.dart';
import 'package:skaterz/services/api_service.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({
    super.key,
    required this.localizations,
    required this.onLogin,
  });

  final AppLocalizations localizations;
  final VoidCallback onLogin;

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.localizations.enterCredentials)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      if (mounted) {
        widget.onLogin();
        // Check if we can pop before calling pop to avoid "history.isNotEmpty" error
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.localizations.loginFailed}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002211), Color(0xFF004D40), Color(0xFF00FF88)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text(
          widget.localizations.loginPageTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: widget.localizations.username,
                prefixIcon: const Icon(Icons.person, color: Color(0xFF004D40)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.localizations.password,
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF004D40)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  ) 
                : Text(widget.localizations.loginButton, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInPage(onLogin: widget.onLogin),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFF004D40)),
              ),
              child: Text(widget.localizations.registerButton, style: const TextStyle(color: Color(0xFF004D40))),
            ),
          ],
        ),
      ),
    );
  }
}
