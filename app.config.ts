import type { ExpoConfig } from "expo/config";

const config: ExpoConfig = {
  name: "صبر إلكترونكس",
  slug: "sabr-electronics",
  version: "1.0.0",
  orientation: "portrait",
  icon: "./assets/images/icon.png",
  scheme: "sabr-electronics",
  userInterfaceStyle: "light",
  newArchEnabled: true,
  ios: { supportsTablet: true, bundleIdentifier: "com.sabr.electronics", infoPlist: { ITSAppUsesNonExemptEncryption: false, NSCameraUsageDescription: "نحتاج الكاميرا لتصوير الأجهزة المستلمة.", NSPhotoLibraryUsageDescription: "نحتاج الصور لإرفاق صور الأجهزة بسجلات الزبائن.", NSFaceIDUsageDescription: "استخدم Face ID لفتح تطبيق صبر إلكترونكس." } },
  android: { package: "com.sabr.electronics", adaptiveIcon: { backgroundColor: "#F1E7D4", foregroundImage: "./assets/images/android-icon-foreground.png", backgroundImage: "./assets/images/android-icon-background.png", monochromeImage: "./assets/images/android-icon-monochrome.png" }, edgeToEdgeEnabled: true, predictiveBackGestureEnabled: false, permissions: ["CAMERA", "READ_MEDIA_IMAGES", "POST_NOTIFICATIONS"] },
  web: { bundler: "metro", output: "static", favicon: "./assets/images/favicon.png" },
  plugins: ["expo-router", ["expo-image-picker", { photosPermission: "اسمح لصبر إلكترونكس بالوصول إلى الصور لإرفاقها بسجل الجهاز." }], ["expo-local-authentication", { faceIDPermission: "اسمح لصبر إلكترونكس باستخدام Face ID لفتح التطبيق." }], "expo-notifications", "expo-document-picker", ["expo-splash-screen", { image: "./assets/images/splash-icon.png", imageWidth: 200, resizeMode: "contain", backgroundColor: "#F8F7F4" }]],
  experiments: { typedRoutes: true, reactCompiler: true },
};

export default config;
