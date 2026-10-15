/// النصوص الثابتة والأسماء المعتمدة في تطبيق صبر إلكترونكس
class AppStrings {
  AppStrings._();

  static const String appName = 'صبر إلكترونكس';
  static const String appSubtitle = 'منظومة الصيانة الإلكترونية والطبية والصوتية';
  static const String appTagline = 'الدقة الفنية والموثوقية الهندسية';

  // العملات
  static const String currencyYER = 'YER';
  static const String currencySAR = 'SAR';
  static const String currencyUSD = 'USD';

  static const String currencyYERLabel = 'ريال يمني';
  static const String currencySARLabel = 'ريال سعودي';
  static const String currencyUSDLabel = 'دولار أمريكي';

  // تصنيفات الأجهزة المعتمدة
  static const String catMedical = 'medical';
  static const String catCarScreen = 'car_screen';
  static const String catAmplifier = 'amplifier';
  static const String catAudioSpeaker = 'audio_speaker';
  static const String catPowerElectronics = 'power_electronics';

  static const String catMedicalLabel = 'أجهزة ومعدات طبية';
  static const String catCarScreenLabel = 'شاشات ومنظومات سيارات';
  static const String catAmplifierLabel = 'مضخمات قدرة صوتية';
  static const String catAudioSpeakerLabel = 'مكسرات وأنظمة صوتية';
  static const String catPowerElectronicsLabel = 'إلكترونيات وباور ومزودات طاقة';

  // حالات الصيانة
  static const String statusReceived = 'received';
  static const String statusInspection = 'inspection';
  static const String statusWaiting = 'waiting_approval';
  static const String statusInProgress = 'in_progress';
  static const String statusWaitingParts = 'waiting_parts';
  static const String statusReady = 'ready';
  static const String statusDone = 'delivered';
  static const String statusCancelled = 'cancelled';
}
