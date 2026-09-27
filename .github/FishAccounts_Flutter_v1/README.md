# Fish Accounts — Flutter v1.0

تطبيق عربي لإدارة تجارة وتصدير الأسماك، مهيأ للفتح في Android Studio ثم بناء APK.

## أهم ما يحتويه
- لوحة تحكم.
- حفظ الشحنات والصادرات.
- العملاء والدول.
- التحصيلات.
- المصروفات.
- المخزون الأساسي.
- العملات: YER / SAR / USD.
- أسعار صرف قابلة للتعديل.
- حساب إجماليات كل عملة بشكل منفصل.
- حفظ محلي على الجهاز باستخدام SharedPreferences.
- واجهة عربية RTL.
- يعمل بدون إنترنت بعد تثبيت الاعتماديات.

## فتح المشروع
1. ثبّت Flutter SDK وAndroid Studio.
2. ثبّت إضافتي Dart وFlutter في Android Studio.
3. افتح مجلد `FishAccounts_Flutter_v1` في Android Studio.
4. نفّذ:
   `flutter pub get`
5. وصّل هاتف Android مع تفعيل USB debugging، أو شغّل Emulator.
6. نفّذ:
   `flutter run`

## استخراج APK تجريبي
من Terminal داخل مجلد المشروع:
`flutter build apk --debug`

الملف الناتج عادة:
`build/app/outputs/flutter-apk/app-debug.apk`

## APK للإصدار
بعد إعداد توقيع Release:
`flutter build apk --release`

## ملاحظة محاسبية
النسخة تحفظ العملة الأصلية لكل عملية ولا تجمع YER وSAR وUSD في رقم واحد.
أسعار الصرف محفوظة في الإعدادات، والنسخة التالية يمكن أن تضيف دفتر أستاذ كامل، مخزون مشتريات/هدر، فواتير PDF، Excel، نسخ احتياطي واستعادة.

المشروع يستخدم Flutter 3.47 أو أحدث متوافقاً مع Android حسب توثيق Flutter الحالي.
