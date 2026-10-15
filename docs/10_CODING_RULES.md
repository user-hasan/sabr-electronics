# Coding Rules

## General
- Dart null safety.
- Strong typing.
- Clean code.
- SOLID عند الحاجة.
- أسماء واضحة.
- لا duplication.
- لا giant files.
- لا business logic داخل UI.
- لا magic numbers/strings عند الحاجة.
- استخدم constants/configuration.

## Flutter
- استخدم أحدث Stable متاح وقت التنفيذ بعد التحقق.
- لا تستخدم deprecated APIs.
- تحقق من compatibility قبل إضافة package.
- لا تضف package فقط لتسهيل شيء بسيط يمكن عمله بFlutter/Dart بشكل موثوق.

## Errors
الأخطاء يجب أن تكون:
- قابلة للفهم للمستخدم.
- قابلة للتتبع للمطور.
- لا تكشف أسرارًا.

## Logging
لا تسجل:
- API keys
- كلمات مرور
- بيانات شخصية كاملة دون ضرورة
- صور حساسة

## Refactoring
قبل refactor:
1. افهم الاستخدامات.
2. ابحث عن references.
3. افحص dependencies.
4. نفذ التغيير.
5. شغّل الاختبارات.

## Database
لا تنفذ SQL من UI.
لا تنفذ SQL من Gemini.
Repository فقط.

## AI
لا تثق في output غير المتحقق منه.
كل AI output يجب:
Parse → Validate → Normalize → Use

## Comments
اكتب التعليقات عندما تشرح "لماذا"، وليس عندما تكرر "ماذا".
