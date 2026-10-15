# Database Specification — مواصفات قاعدة البيانات

## المبدأ الأساسي
قاعدة بيانات **SQLite** المحلية هي مصدر الحقيقة الوحيد (Single Source of Truth) لكافة العمليات المالية، وتوصيف الأجهزة الإلكترونية والطبية، ومخزون القطع الإلكترونية، وسجلات الصيانة.

---

## الجداول والمخطط التفصيلي (Schema)

### 1. `users` (المستخدمون والصلاحيات)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `username` (TEXT UNIQUE NOT NULL)
- `displayName` (TEXT NOT NULL)
- `pinCode` (TEXT NOT NULL) — رمز سري 4 أو 6 أرقام للتبديل السريع وتفويض العمليات الحساسة
- `role` (TEXT NOT NULL) — `owner`, `manager`, `technician`
- `isActive` (INTEGER NOT NULL DEFAULT 1)
- `createdAt` (TEXT NOT NULL)

### 2. `customers` (العملاء والجهات)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `name` (TEXT NOT NULL) — اسم العميل، المهندس، المستشفى، أو ورشة السيارات
- `customerType` (TEXT NOT NULL DEFAULT 'individual') — `individual` (فرد), `car_workshop` (ورشة سيارات), `medical_center` (مركز طبي/مستشفى)
- `phone` (TEXT NOT NULL UNIQUE)
- `alternatePhone` (TEXT)
- `notes` (TEXT)
- `createdAt` (TEXT NOT NULL)
- `updatedAt` (TEXT NOT NULL)

### 3. `devices` (الأجهزة ووحدات الصيانة)
> **ملاحظة:** تم تصميم الحقول لتلائم هندسة الأجهزة الطبية، ومنظومات السيارات، ومضخمات الصوت، مع استبعاد كامل لخصوصيات الهواتف المحمولة.
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `customerId` (INTEGER NOT NULL, FK -> customers.id ON DELETE RESTRICT)
- `category` (TEXT NOT NULL) — `medical`, `car_screen`, `amplifier`, `audio_speaker`, `power_electronics`
- `deviceType` (TEXT NOT NULL) — مثل: شاشة أندرويد 9 إنش، جهاز تخطيط قلب، مضخم صوت 4 قنوات، مكسر صوتي
- `brand` (TEXT NOT NULL) — الشركة الصانعة (مثل: Pioneer, Sony, Mindray, Yamaha, JBL)
- `model` (TEXT NOT NULL) — الموديل أو رقم الشاسيه / رقم البوردة
- `serialNumber` (TEXT) — السيريال أو الباركود
- `carVehicleInfo` (TEXT) — خاص بشاشات ومسجلات السيارات (نوع وموديل وسنة السيارة)
- `medicalFacility` (TEXT) — خاص بالأجهزة الطبية (اسم العيادة أو القسم)
- `operatingVoltage` (TEXT) — فولتية التشغيل (12V DC, 24V DC, 220V AC)
- `receivedAccessories` (TEXT) — الملحقات (فيش التوصيل، محول، ضفيرة أسلاك، كابل فحص، ريموت)
- `physicalCondition` (TEXT) — الحالة الفيزيائية (كسور، حروق ظاهرة، علامات تلاعب سابقة)
- `createdAt` (TEXT NOT NULL)
- `updatedAt` (TEXT NOT NULL)

### 4. `device_images` (الصور والتوثيق الهندسي)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `deviceId` (INTEGER NOT NULL, FK -> devices.id ON DELETE CASCADE)
- `repairRecordId` (INTEGER, FK -> repair_records.id ON DELETE SET NULL)
- `imageType` (TEXT NOT NULL) — `intake` (شكل الجهاز والمداخل عند الاستلام), `circuit_board` (صور اللوحة الإلكترونية ومناطق الحرق), `completed` (بعد الصيانة)
- `originalPath` (TEXT NOT NULL)
- `thumbnailPath` (TEXT NOT NULL)
- `createdAt` (TEXT NOT NULL)

### 5. `spare_parts` (مستودع القطع والمكونات الإلكترونية)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `name` (TEXT NOT NULL) — مثل: IC صوت TDA7388، ترانزستور 2SC5200، شاشة لمس 9 إنش، مكثف 4700uF 50V
- `partCode` (TEXT UNIQUE) — كود القطعة الفني أو الباركود
- `category` (TEXT NOT NULL) — `integrated_circuit`, `transistor`, `capacitor`, `car_screen_lcd`, `power_supply`
- `costPrice` (REAL NOT NULL DEFAULT 0.0) — سعر التكلفة
- `sellingPrice` (REAL NOT NULL DEFAULT 0.0) — سعر البيع للعميل
- `currency` (TEXT NOT NULL DEFAULT 'YER') — عملة التسعير: `YER` (ريال يمني), `SAR` (ريال سعودي), `USD` (دولار أمريكي)
- `stockQuantity` (INTEGER NOT NULL DEFAULT 0) — الكمية المتوفرة
- `minStockAlert` (INTEGER NOT NULL DEFAULT 2) — حد التنبيه عند قرب النفاد
- `createdAt` (TEXT NOT NULL)
- `updatedAt` (TEXT NOT NULL)

### 6. `repair_records` (تذاكر وعمليات الصيانة)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `recordNumber` (TEXT UNIQUE NOT NULL) — رقم تسلسلي معتمد للسند (مثال: `REC-2026-0001`)
- `customerId` (INTEGER NOT NULL, FK -> customers.id ON DELETE RESTRICT)
- `deviceId` (INTEGER NOT NULL, FK -> devices.id ON DELETE RESTRICT)
- `technicianId` (INTEGER, FK -> users.id ON DELETE SET NULL)
- `receivedAt` (TEXT NOT NULL)
- `expectedDeliveryAt` (TEXT)
- `deliveredAt` (TEXT)
- `status` (TEXT NOT NULL) — حالات الصيانة أدناه
- `problemDescription` (TEXT NOT NULL) — شكوى العميل (مثل: قاطع باور، صوت مشوش في القناة اليمنى، تعليق على شعار السيارة)
- `diagnosticNotes` (TEXT) — تقرير الفحص الهندسي والقياسات
- `currency` (TEXT NOT NULL DEFAULT 'YER') — عملة الحساب المعتمدة للسند (`YER`, `SAR`, `USD`)
- `estimatedCost` (REAL NOT NULL DEFAULT 0.0) — السعر التقديري المتفق عليه
- `laborCost` (REAL NOT NULL DEFAULT 0.0) — أجرة يد الصيانة الهندسية
- `partsCost` (REAL NOT NULL DEFAULT 0.0) — إجمالي قطع الغيار والمكونات
- `totalAmount` (REAL NOT NULL DEFAULT 0.0) — الإجمالي = (laborCost + partsCost - discountAmount)
- `discountAmount` (REAL NOT NULL DEFAULT 0.0) — الخصم
- `paidAmount` (REAL NOT NULL DEFAULT 0.0) — المدفوع حتى اللحظة
- `remainingAmount` (REAL NOT NULL DEFAULT 0.0) — المتبقي المستحق
- `warrantyDays` (INTEGER NOT NULL DEFAULT 30) — مدة الضمان بالأيام
- `createdAt` (TEXT NOT NULL)
- `updatedAt` (TEXT NOT NULL)

### 7. `repair_items` (بنود الصيانة والمكونات المستهلكة)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `repairRecordId` (INTEGER NOT NULL, FK -> repair_records.id ON DELETE CASCADE)
- `itemType` (TEXT NOT NULL) — `spare_part` (مكون إلكتروني) أو `labor_service` (أجرة عمل فني)
- `sparePartId` (INTEGER, FK -> spare_parts.id ON DELETE SET NULL)
- `description` (TEXT NOT NULL)
- `unitCost` (REAL NOT NULL DEFAULT 0.0)
- `unitPrice` (REAL NOT NULL DEFAULT 0.0)
- `quantity` (INTEGER NOT NULL DEFAULT 1)
- `totalPrice` (REAL NOT NULL DEFAULT 0.0)
- `createdAt` (TEXT NOT NULL)

### 8. `payments` (سندات القبض والدفعات المالية)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `receiptNumber` (TEXT UNIQUE NOT NULL)
- `repairRecordId` (INTEGER NOT NULL, FK -> repair_records.id ON DELETE RESTRICT)
- `customerId` (INTEGER NOT NULL, FK -> customers.id ON DELETE RESTRICT)
- `amount` (REAL NOT NULL)
- `currency` (TEXT NOT NULL DEFAULT 'YER') — عملة الدفعة المستلمة (`YER`, `SAR`, `USD`)
- `paymentMethod` (TEXT NOT NULL) — `cash`, `kuraimi`, `jawali`, `bank_transfer`
- `receivedByUserId` (INTEGER NOT NULL, FK -> users.id ON DELETE RESTRICT)
- `paidAt` (TEXT NOT NULL)
- `notes` (TEXT)

### 9. `repair_status_history` (سجل تتبع الحالات)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `repairRecordId` (INTEGER NOT NULL, FK -> repair_records.id ON DELETE CASCADE)
- `changedByUserId` (INTEGER, FK -> users.id ON DELETE SET NULL)
- `oldStatus` (TEXT NOT NULL)
- `newStatus` (TEXT NOT NULL)
- `note` (TEXT)
- `changedAt` (TEXT NOT NULL)

### 10. `audit_logs` (سجل الرقابة والتتبع)
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `userId` (INTEGER, FK -> users.id ON DELETE SET NULL)
- `action` (TEXT NOT NULL)
- `entityName` (TEXT NOT NULL)
- `entityId` (TEXT NOT NULL)
- `details` (TEXT)
- `createdAt` (TEXT NOT NULL)

### 11. `settings` (إعدادات النظام العامة)
- `key` (TEXT PRIMARY KEY)
- `value` (TEXT NOT NULL)
- `updatedAt` (TEXT NOT NULL)

---

## بروتوكول الترقية والهجرة الآمنة بدون فقدان البيانات (Zero Data Loss Migration)

لضمان عدم مساس أي تحديث مستقبلي للتطبيق ببيانات وسجلات المركز:
1. **المسار المحمي:** ملف قاعدة البيانات `sabr_electronics.db` يُحفظ داخل `getApplicationDocumentsDirectory()` الذي لا يحذفه نظام التشغيل عند تحديث التطبيق فوق الإصدار السابق.
2. **الترقية المتسلسلة (Incremental Migrations):**
   - استخدام `PRAGMA user_version` ودالة `onUpgrade(db, oldVersion, newVersion)` في مكتبة `sqflite`.
   - كل إصدار جديد يحتوي فقط على أوامر توسيع غير مدمرة: `ALTER TABLE ... ADD COLUMN ...` أو `CREATE TABLE IF NOT EXISTS`.
   - **يُمنع منعاً باتاً كتابة أي أمر `DROP TABLE`** في دوال الترقية.
3. **الأمان بالمعاملات (Transactional Safety):**
   - تنفيذ أوامر الترقية داخل SQLite Transaction؛ في حال فشل أي أمر، يتم التراجع الفوري (Rollback) واسترجاع النسخة الاحتياطية التلقائية التي أُخذت قبل التحديث بثوانٍ.
