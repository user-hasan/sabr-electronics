# Assets, Icons & Branding Specification — دليل الهوية والأيقونات والصور

## 1. الهوية البصرية وشعار التطبيق (Brand Identity)

- **الاسم المعتمد:** **صبر إلكترونكس** (Sabr Electronics)
- **المفهوم البصري:** مزيج احترافي بين شريحة إلكترونية رقمية (Microchip)، ومفتاح فك دقيق (Precision Screwdriver)، وترس ميكانيكي (Gear)، يعبر عن الدقة الفنية والموثوقية التقنية في الصيانة.
- **مسار الشعار:** `assets/images/app_logo.jpg`

---

## 2. باليت الألوان المعيارية (Color Palette)

| المسمى | القيمة اللونية (Hex) | المعنى والاستخدام |
| :--- | :--- | :--- |
| **Primary Brand (Cyan)** | `#00E5FF` / `#06B6D4` | اللون الأساسي للهوية، أزرار الإجراء الرئيسي، الهايلايت |
| **Secondary Accent (Amber)** | `#F59E0B` | لمسات العتاد، المبالغ المالية، التنبيهات، والقطع الهامة |
| **Background Dark** | `#0F172A` | خلفية التطبيق في الوضع الداكن (Dark Slate) |
| **Surface / Card Dark** | `#1E293B` | خلفية البطاقات والحقول والقوائم المنسدلة |
| **Background Light** | `#F8FAFC` | خلفية التطبيق في الوضع الفاتح |
| **Surface Light** | `#FFFFFF` | خلفية البطاقات في الوضع الفاتح |
| **Text Primary (Dark)** | `#F8FAFC` | النصوص والعناوين الرئيسية في الوضع الداكن |
| **Text Secondary (Dark)** | `#94A3B8` | النصوص الفرعية والشروحات والملاحظات |
| **Border / Divider** | `#334155` | حدود البطاقات والفواصل |
| **Status Received** | `#3B82F6` (Blue) | تم استلام الجهاز / قيد الفحص |
| **Status Waiting** | `#F59E0B` (Amber) | بانتظار موافقة العميل أو قطع الغيار |
| **Status Ready / Done** | `#10B981` (Emerald) | الجهاز تم إصلاحه وجاهز للتسليم أو تم التسليم |
| **Status Cancelled** | `#EF4444` (Red) | ملغي أو تعذر الإصلاح |

---

## 3. الصور والوسائط الجاهزة في المشروع (Assets Registry)

| اسم الملف | المسار الفعلي | الغرض والاستخدام | الأبعاد / النسبة |
| :--- | :--- | :--- | :---: |
| **`app_logo.jpg`** | `assets/images/app_logo.jpg` | شعار التطبيق الأساسي، أيقونة الإطلاق (Launcher Icon)، وترويسة التقارير | 1:1 (مربع) |
| **`splash_banner.jpg`** | `assets/images/splash_banner.jpg` | خلفية شاشة البداية (Splash Screen)، وبانر تسجيل الدخول وقفل الـ PIN | 16:9 (عريض) |
| **`empty_state.jpg`** | `assets/images/empty_state.jpg` | شاشات القوائم الفارغة (لا توجد أجهزة متأخرة / تم إنجاز كافة المهام) | 1:1 (مربع) |

---

## 4. جدول الأيقونات المعتمدة للنظام (Master Icons Mapping)

جميع الأيقونات معتمدة مباشرة من حزمة `Icons` (Material Icons 3) المدمجة أصلاً في Flutter لضمان خفة الحجم، وسرعة العرض بنسبة 100%، وتجنب بطء الصور النقطية:

### أ. التنقل الرئيسي ولوحة التحكم (Navigation & Dashboard)
| العنصر | الأيقونة في Flutter | الكود البرمجي | اللون الدلالي |
| :--- | :--- | :--- | :--- |
| الرئيسية / لوحة التحكم | `Icons.dashboard_rounded` | `Icons.dashboard_rounded` | Cyan (`#00E5FF`) |
| دورة وتذاكر الصيانة | `Icons.build_circle_rounded` | `Icons.build_circle_rounded` | Blue (`#3B82F6`) |
| العملاء | `Icons.people_alt_rounded` | `Icons.people_alt_rounded` | Slate (`#94A3B8`) |
| الأجهزة | `Icons.devices_other_rounded` | `Icons.devices_other_rounded` | Slate (`#94A3B8`) |
| مستودع قطع الغيار | `Icons.inventory_2_rounded` | `Icons.inventory_2_rounded` | Amber (`#F59E0B`) |
| المدفوعات والمالية | `Icons.payments_rounded` | `Icons.payments_rounded` | Emerald (`#10B981`) |
| التقارير والأرباح | `Icons.analytics_rounded` | `Icons.analytics_rounded` | Cyan (`#06B6D4`) |
| الإعدادات والطباعة | `Icons.settings_suggest_rounded` | `Icons.settings_suggest_rounded` | Slate (`#94A3B8`) |

### ب. عمليات الصيانة السريعة والاستقبال (Counter & Intake)
| الإجراء | الأيقونة في Flutter | الكود البرمجي | الغرض |
| :--- | :--- | :--- | :--- |
| استلام جهاز جديد | `Icons.add_task_rounded` | `Icons.add_task_rounded` | زر الإجراء العائم الرئيسي (FAB) |
| مسح باركود / QR | `Icons.qr_code_scanner_rounded` | `Icons.qr_code_scanner_rounded` | قراءة كود إيصال الجهاز فوراً بالكاميرا |
| طباعة حرارية | `Icons.print_rounded` | `Icons.print_rounded` | طباعة سند الاستلام أو ملصق الجهاز |
| طابعة بلوتوث متصلة | `Icons.bluetooth_connected_rounded` | `Icons.bluetooth_connected_rounded` | مؤشر جاهزية الطابعة الحرارية |
| طابعة غير متصلة | `Icons.bluetooth_disabled_rounded` | `Icons.bluetooth_disabled_rounded` | تنبيه عدم اتصال الطابعة |
| قفل PIN / تبديل مستخدم | `Icons.lock_person_rounded` | `Icons.lock_person_rounded` | قفل الشاشة والتبديل بين الفنيين |
| إرسال واتساب | `Icons.chat_bubble_rounded` | `Icons.chat_bubble_rounded` | إرسال إشعار جاهزية الجهاز للعميل |
| اتصال هاتفي مباشر | `Icons.phone_forwarded_rounded` | `Icons.phone_forwarded_rounded` | الاتصال بالعميل من داخل السجل |

### ج. أنواع الأجهزة وتخصصات المركز (Device Categories)
| نوع وتصنيف الجهاز | الأيقونة في Flutter | الكود البرمجي |
| :--- | :--- | :--- |
| **أجهزة طبية (Medical Equipment)** | `Icons.medical_services_rounded` | `Icons.medical_services_rounded` |
| **شاشات ومنظومات سيارات (Car Displays)** | `Icons.directions_car_rounded` | `Icons.directions_car_rounded` |
| **مضخمات صوت (Power Amplifiers)** | `Icons.speaker_group_rounded` | `Icons.speaker_group_rounded` |
| **صوتيات وسماعات (Pro Audio & PA)** | `Icons.surround_sound_rounded` | `Icons.surround_sound_rounded` |
| **إلكترونيات وبوردات وباور (Electronics/Power)** | `Icons.memory_rounded` | `Icons.memory_rounded` |

### د. حالات الصيانة (Repair Status Badges)
| الحالة | الأيقونة في Flutter | الكود البرمجي | اللون المعتمد |
| :--- | :--- | :--- | :--- |
| تم الاستلام (Received) | `Icons.inbox_rounded` | `Icons.inbox_rounded` | `#3B82F6` (Blue) |
| قيد الفحص (Inspection) | `Icons.biotech_rounded` | `Icons.biotech_rounded` | `#8B5CF6` (Purple) |
| بانتظار الموافقة (Approval) | `Icons.hourglass_top_rounded` | `Icons.hourglass_top_rounded` | `#F59E0B` (Amber) |
| قيد الإصلاح (In Progress) | `Icons.handyman_rounded` | `Icons.handyman_rounded` | `#06B6D4` (Cyan) |
| بانتظار قطع غيار (Parts) | `Icons.pending_actions_rounded` | `Icons.pending_actions_rounded` | `#EC4899` (Pink) |
| جاهز للتسليم (Ready) | `Icons.verified_rounded` | `Icons.verified_rounded` | `#10B981` (Green) |
| تم التسليم والقبض (Done) | `Icons.task_alt_rounded` | `Icons.task_alt_rounded` | `#059669` (Dark Green) |
| تعذر الإصلاح / ملغي | `Icons.cancel_rounded` | `Icons.cancel_rounded` | `#EF4444` (Red) |

### هـ. الذكاء الاصطناعي والكاميرا والوسائط (AI & Media)
| الوظيفة | الأيقونة في Flutter | الكود البرمجي |
| :--- | :--- | :--- |
| OCR محلي فوري | `Icons.document_scanner_rounded` | `Icons.document_scanner_rounded` |
| مساعد Gemini الذكي | `Icons.auto_awesome_rounded` | `Icons.auto_awesome_rounded` |
| التقاط صورة العطل | `Icons.photo_camera_rounded` | `Icons.photo_camera_rounded` |
| اقتصاص الصورة | `Icons.crop_rotate_rounded` | `Icons.crop_rotate_rounded` |
| صورة مصغرة / تفاصيل | `Icons.zoom_in_rounded` | `Icons.zoom_in_rounded` |

---

## 5. تكوين ملف `pubspec.yaml` للوسائط (Assets Configuration)

عند بدء المشروع، سيتم تفعيل المجلد في `pubspec.yaml` كالتالي:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```
