import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth_screen.dart';

class AuthOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onAuthenticated;

  const AuthOptionsBottomSheet({super.key, required this.onAuthenticated});

  void _handleGoogleSignIn(BuildContext context) async {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    try {
      await authVm.signInWithGoogle();
      if (context.mounted && authVm.isLoggedIn) {
        Navigator.pop(context); // Close sheet
        onAuthenticated();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authVm.parseAuthError(e), style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _navigateToEmailAuth(BuildContext context) {
    Navigator.pop(context); // Close sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(onAuthenticated: onAuthenticated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF122A34),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Account Required",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            "To book an appointment, please verify your identity securely.",
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          // Google Button
          _AuthOptionButton(
            title: "Continue with Google",
            icon: Icons.g_mobiledata_rounded, // Using native icon as fallback for google logo
            color: Colors.white,
            textColor: Colors.black,
            onPressed: () => _handleGoogleSignIn(context),
          ),
          const SizedBox(height: 16),
          // Email Button
          _AuthOptionButton(
            title: "Login / Sign up with Email",
            icon: Icons.email_outlined,
            color: const Color(0xFF00BFA5).withOpacity(0.15),
            textColor: const Color(0xFF00E5CC),
            borderColor: const Color(0xFF00BFA5).withOpacity(0.3),
            onPressed: () => _navigateToEmailAuth(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AuthOptionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _AuthOptionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: borderColor != null ? BorderSide(color: borderColor!, width: 1.5) : BorderSide.none,
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
