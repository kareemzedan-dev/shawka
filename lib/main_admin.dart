import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:matlobgo/admin/admin_app.dart';
import 'package:matlobgo/core/di/service_locator.dart';
import 'package:matlobgo/core/firestore/firestore_bootstrap.dart';
import 'package:matlobgo/core/maps/maps_api_key.dart';
import 'package:matlobgo/core/media/android_photo_picker.dart';
import 'package:matlobgo/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAndroidPhotoPicker();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirestoreBootstrap.init();
  await ServiceLocator.init();
  await MapsApiKey.warmUp();
  runApp(const MatlobGoAdminApp());
}
