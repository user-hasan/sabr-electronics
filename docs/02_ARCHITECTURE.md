# Architecture Rules — المعمارية الهندسية

## الهدف
بناء بنية برمجية قابلة للصيانة، والتوسع، واختبار الوحدات، مع تحقيق مبدأ **Offline-First** الحقيقي والفصل الصارم بين المنطق التجاري (Business Logic)، ومصادر البيانات (Data Sources)، والواجهات (Presentation).

## هيكل المجلدات المقترح (Feature-First Clean Architecture)

```text
lib/
├── app.dart
├── main.dart
├── core/
│   ├── constants/            # ألوان، مسارات، أبعاد، نصوص ثابتة
│   ├── errors/               # Exceptions و Failures المعيارية
│   ├── network/              # مراقبة حالة الاتصال بالإنترنت
│   ├── printer/              # محرك الطباعة الحرارية ESC/POS
│   ├── security/             # تشفير البيانات والتحقق من PIN
│   ├── theme/                # Dark & Light Themes بدعم كامل للـ RTL
│   └── utils/                # ضغط الصور، معالجة التاريخ، العملات
├── data/
│   ├── datasources/
│   │   ├── local/            # SQLite Database, Secure Storage, Shared Preferences
│   │   ├── ocr/              # Google ML Kit Local OCR
│   │   └── remote/           # Gemini API Client
│   ├── models/               # Data Transfer Objects (DTOs) + Mappers
│   └── repositories/         # التطبيق الفعلي للـ Repositories
├── domain/
│   ├── entities/             # نماذج العمل النقية (Pure Business Models)
│   ├── enums/                # RepairStatus, UserRole, PaymentMethod
│   └── repositories/         # واجهات ومخططات الـ Repositories (Contracts)
├── presentation/
│   ├── common/               # أزرار، حقول إدخال، حالات تحميل وأخطاء موحدة
│   └── features/
│       ├── auth_lock/        # شاشة القفل ورمز PIN
│       ├── customers/        # إدارة العملاء والبحث الفوري
│       ├── devices/          # إدارة الأجهزة والتقاط الصور
│       ├── repairs/          # دورة الصيانة، تسجيل التكاليف وقطع الغيار
│       ├── spare_parts/      # مستودع قطع الغيار والخدمات
│       ├── payments/         # السندات المالية والدفعات المجزأة
│       ├── printer/          # معاينة وطباعة السندات والملصقات
│       ├── dashboard/        # لوحة الإحصائيات الفورية
│       ├── reports/          # تقارير الأرباح والديون وتصدير PDF
│       ├── ai_assistant/     # المساعد الذكي للتحليلات وصياغة الرسائل
│       └── settings/         # النسخ الاحتياطي، الطابعة، والعملات
└── services/
    ├── backup_service.dart   # تصدير واسترجاع قاعدة البيانات والصور
    ├── image_service.dart    # ضغط الصور وتوليد الـ Thumbnails محلياً
    ├── thermal_print_service.dart # التواصل مع طابعات البلوتوث وUSB
    └── ocr_service.dart      # منسق الـ OCR الهجين (ML Kit -> Gemini)
```

## تدفق البيانات المعماري (Data Flow)

```text
[UI / Presentation Layer]
         ↓ (User Actions / Events)
[State Management (Riverpod Notifiers)]
         ↓ (Calls Business Operations)
[Domain Repositories (Interfaces)]
         ↓ (Implemented By)
[Data Repositories (Data Layer)]
    ┌────┴──────────────────────────┐
    ▼                               ▼
[Local Data Sources]         [Remote Data Sources]
- SQLite (Local DB)           - Gemini REST API (Online only)
- ML Kit (On-device OCR)
- File System (Compressed Images)
- ESC/POS Printer Driver
```

## القواعد المعمارية الصارمة

1. **قاعدة البيانات هي مصدر الحقيقة الوحيد (Single Source of Truth):**
   - لا توجد أي واجهة UI تقرأ أو تكتب مباشرة في SQLite.
   - لا توجد أي خدمة ذكاء اصطناعي تكتب مباشرة في قاعدة البيانات.
   - جميع العمليات تمر حصرياً عبر `Repository` محصن بـ Transactions للعمليات متعددة الجداول.
2. **استقلالية المنطق عن السحابة (True Offline Capability):**
   - عمليات: تسجيل عميل، فتح تذكرة صيانة، إضافة قطع غيار، دفع مبلغ، طباعة سند حراري، والبحث... جميعها تعمل بسرعة 100% دون الحاجة لأي ذكاء اصطناعي أو إنترنت.
3. **فصل معالجة الصور عن التوليد السحابي:**
   - صور الأجهزة تُضغط وتُحفظ محلياً عبر مكتبات معالجة صور نقية وحتمية (Deterministic).
   - يُمنع تماماً تمرير صور الأجهزة لنموذج توليدي لإعادة رسمها أو تحسينها بكسلياً.
4. **خدمة الـ OCR الهجين:**
   - واجهة `OcrService` تستدعي `LocalOcrEngine` أولاً لمعالجة النصوص الإنجليزية والأرقام والبطاقات المطبوعة فوراً.
   - في حال طلب المستخدم معالجة خط يدوي معقد وكان الإنترنت متوفراً، يتم الاستدعاء الاختياري لـ `GeminiVisionEngine`.
5. **إدارة الحالة (State Management):**
   - استخدام `flutter_riverpod` مع `Notifier` / `AsyncNotifier` مع `freezed` أو `immutable models` لضمان استقرار الحالة والتعامل الآمن مع Null Safety.
