import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/pages/initial_trick_selection_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final localizations = AppLocalizations.of(Localizations.localeOf(context).languageCode);
      
      try {
        debugPrint("DEBUG: Starting registration for ${_usernameController.text}");
        
        // 1. Register User
        await _apiService.register(
          _usernameController.text,
          _passwordController.text,
          _emailController.text,
          _nameController.text,
        );
        debugPrint("DEBUG: Registration successful");
        
        // 2. Automatically Log In to get the token
        debugPrint("DEBUG: Starting automatic login...");
        await _apiService.login(
          _usernameController.text,
          _passwordController.text,
        );
        debugPrint("DEBUG: Login successful");

        if (mounted) {
          debugPrint("DEBUG: Navigating to InitialTrickSelectionPage...");
          // 3. Navigate to Initial Trick Selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InitialTrickSelectionPage(
                localizations: localizations,
                onComplete: widget.onLogin,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint("DEBUG: Error in registration flow: $e");
        if (mounted) {
          String errorMessage = localizations.registrationFailed;
          if (e.toString().toLowerCase().contains('email') && e.toString().toLowerCase().contains('exists')) {
            errorMessage = localizations.emailAlreadyExists;
          } else {
            errorMessage = '${localizations.registrationFailed}: ${e.toString()}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(Localizations.localeOf(context).languageCode);
    
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
          localizations.registerButton,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: localizations.name,
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF004D40)),
                  ),
                  validator: (value) => value!.isEmpty ? localizations.enterName : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: localizations.username,
                    prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF004D40)),
                  ),
                  validator: (value) => value!.isEmpty ? localizations.enterUsername : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: localizations.email,
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF004D40)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? localizations.enterEmail : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: localizations.password,
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF004D40)),
                  ),
                  obscureText: true,
                  validator: (value) => value!.length < 6 ? localizations.passwordTooShort : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(localizations.registerButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
