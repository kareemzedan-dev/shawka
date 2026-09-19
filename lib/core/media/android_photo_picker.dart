import 'package:matlobgo/core/media/android_photo_picker_stub.dart'
    if (dart.library.io) 'package:matlobgo/core/media/android_photo_picker_io.dart'
    as impl;

/// يفعّل Android Photo Picker على Android فقط (لا صلاحية مكتبة صور واسعة).
void configureAndroidPhotoPicker() => impl.configureAndroidPhotoPicker();
