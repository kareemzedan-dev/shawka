import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/screens/admin_login_screen.dart';
import 'package:matlobgo/admin/theme/admin_theme.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/widgets/admin_shell.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/services/auth_service.dart';

/// يتحقق من جلسة الأدمن عند فتح لوحة التحكم.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _auth = AuthService();
  bool _checking = true;
  bool _isAdmin = false;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      setState(() {
        _checking = false;
        _isAdmin = false;
      });
      return;
    }

    final appUser = await _auth.getCurrentAppUser();
    setState(() {
      _checking = false;
      _isAdmin = appUser?.isAdmin ?? false;
      _user = appUser;
    });
    if (appUser?.isAdmin == true) {
      AdminSession.instance.bind(appUser);
    }

    if (appUser != null && !appUser.isAdmin) {
      await _auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AdminTheme.sidebar,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل لوحة التحكم...',
                style: GoogleFonts.cairo(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAdmin) {
      return AdminShell(user: _user);
    }

    return const AdminLoginScreen();
  }
}
