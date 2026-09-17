import { useEffect } from "react";
import { Alert, Platform } from "react-native";
import { checkForUpdate, openUpdate } from "@/lib/app-updates";

export function AppUpdateNotice() {
  useEffect(() => {
    if (Platform.OS === "web") return;
    const timer = setTimeout(() => { void checkForUpdate().then((update) => { if (!update) return; Alert.alert("يتوفر تحديث جديد", `${update.name}\n\nيمكنك تنزيله الآن. لن تُحذف بياناتك الحالية.`, [{ text: "لاحقًا", style: "cancel" }, { text: "تنزيل التحديث", onPress: () => void openUpdate(update) }]); }).catch(() => undefined); }, 1800);
    return () => clearTimeout(timer);
  }, []);
  return null;
}
