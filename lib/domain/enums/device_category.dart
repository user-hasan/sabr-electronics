import 'package:flutter/material.dart';

/// تصنيفات الأجهزة الهندسية المعتمدة لمركز صبر إلكترونكس
enum DeviceCategory {
  medical('medical', 'أجهزة ومعدات طبية', Icons.medical_services_rounded),
  carScreen('car_screen', 'شاشات ومنظومات سيارات', Icons.directions_car_rounded),
  amplifier('amplifier', 'مضخمات قدرة صوتية', Icons.speaker_group_rounded),
  audioSpeaker('audio_speaker', 'صوتيات وسماعات ومكسرات', Icons.surround_sound_rounded),
  powerElectronics('power_electronics', 'إلكترونيات وباور وبوردات', Icons.memory_rounded);

  final String code;
  final String label;
  final IconData icon;

  const DeviceCategory(this.code, this.label, this.icon);

  static DeviceCategory fromCode(String code) {
    return DeviceCategory.values.firstWhere(
      (c) => c.code.toLowerCase() == code.toLowerCase(),
      orElse: () => DeviceCategory.powerElectronics,
    );
  }
}
