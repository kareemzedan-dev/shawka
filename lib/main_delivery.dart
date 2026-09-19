import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/di/service_locator.dart';
import 'package:matlobgo/core/services/location_service.dart';
import 'package:matlobgo/core/firestore/firestore_bootstrap.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/firebase_options.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/driver_location_service.dart';
import 'package:matlobgo/services/push_notification_service.dart';
import 'package:matlobgo/core/constants/app_branding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirestoreBootstrap.init();
  await ServiceLocator.init();
  await PushNotificationService.instance.init();
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
        useMaterial3: true,
      ),
      home: const DeliveryHomeScreen(),
    );
  }
}

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  AppUser? _user;
  bool _loading = true;
  bool _tracking = false;
  String _status = 'جاري التحميل...';
  Position? _lastPos;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final user = await _auth.getCurrentAppUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
      _status = user == null
          ? 'سجّل دخولك كمندوب'
          : user.isDelivery
              ? 'جاهز لتفعيل GPS'
              : 'هذا الحساب ليس مندوب delivery';
    });
    if (user?.isDelivery == true) {
      await _startTracking();
    }
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await _bootstrap();
    } catch (e) {
      setState(() => _status = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    DriverLocationService.instance.stop();
    await _auth.signOut();
    setState(() {
      _user = null;
      _tracking = false;
      _lastPos = null;
      _status = 'تم تسجيل الخروج';
    });
  }

  Future<({double lat, double lng})?> _readLocation() async {
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (mounted) setState(() => _lastPos = pos);
      return (lat: pos.latitude, lng: pos.longitude);
    } on LocationServiceException catch (e) {
      if (mounted) setState(() => _status = e.message);
      return null;
    }
  }

  Future<void> _startTracking() async {
    try {
      await LocationService.instance.ensurePermission(
        requestBackground: true,
      );
    } on LocationServiceException catch (e) {
      setState(() => _status = e.message);
      return;
    }

    DriverLocationService.instance.startPeriodicUpdates(_readLocation);
    setState(() {
      _tracking = true;
      _status = 'GPS نشط — يُحدَّث كل 30 ث';
    });
  }

  @override
  void dispose() {
    DriverLocationService.instance.stop();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(
          AppBranding.driverAppName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_user != null)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: _user == null ? _loginForm() : _driverPanel(),
            ),
    );
  }

  Widget _loginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تطبيق المندوب',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailCtrl,
          style: GoogleFonts.cairo(color: Colors.white),
          decoration: const InputDecoration(labelText: 'البريد'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          style: GoogleFonts.cairo(color: Colors.white),
          decoration: const InputDecoration(labelText: 'كلمة المرور'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _login,
          child: Text('دخول', style: GoogleFonts.cairo()),
        ),
        const SizedBox(height: 12),
        Text(_status, style: GoogleFonts.cairo(color: Colors.white70)),
      ],
    );
  }

  Widget _driverPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _user!.name.isEmpty ? 'مندوب' : _user!.name,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _status,
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        if (_lastPos != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'آخر موقع:\n'
                '${_lastPos!.latitude.toStringAsFixed(5)}, '
                '${_lastPos!.longitude.toStringAsFixed(5)}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        const Spacer(),
        if (_user!.isDelivery && !_tracking)
          FilledButton.icon(
            onPressed: _startTracking,
            icon: const Icon(Icons.gps_fixed_rounded),
            label: Text('تفعيل GPS Live', style: GoogleFonts.cairo()),
          ),
      ],
    );
  }
}
