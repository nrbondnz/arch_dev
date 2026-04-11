import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import 'amplify_outputs.dart';
import 'models/ModelProvider.dart'; // retained for Amplify API plugin options
import 'screens/role_select_screen.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await _configureAmplify();
    runApp(const MyApp());
  } on AmplifyException catch (e) {
    runApp(Text("Error configuring Amplify: ${e.message}"));
  }
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyAPI(
        options: APIPluginOptions(modelProvider: ModelProvider.instance),
      ),
    ]);
    await Amplify.configure(amplifyConfig);
    safePrint('Successfully configured');
  } on Exception catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      authenticatorBuilder: (context, state) {
        if (state.currentStep == AuthenticatorStep.signIn) {
          return _StartPage(state: state);
        }
        return null;
      },
      child: MaterialApp(
        title: 'ARCH – Subcontractor Management',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A56DB)),
          useMaterial3: true,
        ),
        builder: Authenticator.builder(),
        home: const RoleSelectScreen(),
      ),
    );
  }
}

// ── Public landing / sign-in page ────────────────────────────────────────────

class _StartPage extends StatefulWidget {
  final AuthenticatorState state;
  const _StartPage({required this.state});

  @override
  State<_StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<_StartPage> {
  bool _showLoginForm = false;

  @override
  Widget build(BuildContext context) {
    if (_showLoginForm) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _showLoginForm = false),
          ),
          title: const Text('Sign In'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SignInForm(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business, size: 64, color: Color(0xFF1A56DB)),
                ),
                const SizedBox(height: 32),
                const Text(
                  'ARCH',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Subcontractor Management',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 64),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showLoginForm = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sign In', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
