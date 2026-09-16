import { useMemo, useState } from "react";
import { Alert, Image, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import { router } from "expo-router";
import * as ImagePicker from "expo-image-picker";
import MaterialIcons from "@expo/vector-icons/MaterialIcons";

import { ScreenContainer } from "@/components/screen-container";
import { SchemeColors } from "@/constants/theme";
import { useAppData } from "@/lib/app-store";
import { DEVICE_TYPES, DEVICE_STATUSES, type DeviceRecord, type DeviceStatus } from "@/lib/app-types";
import { useThemeContext } from "@/lib/theme-provider";

export default function NewDeviceScreen() {
  const { addDevice, createDraft } = useAppData();
  const { colorScheme } = useThemeContext();
  const colors = SchemeColors[colorScheme];
  const styles = useMemo(() => makeStyles(colors), [colors]);
  const draft = useMemo(() => createDraft(), [createDraft]);
  const [form, setForm] = useState<DeviceRecord>(draft);
  const [saving, setSaving] = useState(false);
  const set = (patch: Partial<DeviceRecord>) => setForm((current) => ({ ...current, ...patch }));

  async function pickImages() {
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ["images"], allowsMultipleSelection: true, quality: 0.8 });
    if (!result.canceled) set({ imageUris: [...form.imageUris, ...result.assets.map((asset) => asset.uri)] });
  }
  async function takePhoto() {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (permission.status !== "granted") { Alert.alert("صلاحية الكاميرا", "اسمح للتطبيق باستخدام الكاميرا لإضافة صورة الجهاز."); return; }
    const result = await ImagePicker.launchCameraAsync({ quality: 0.8, allowsEditing: true });
    if (!result.canceled) set({ imageUris: [...form.imageUris, result.assets[0].uri] });
  }
  async function save() {
    if (!form.customerName.trim() || !form.deviceModel.trim()) { Alert.alert("بيانات ناقصة", "أدخل اسم الزبون واسم أو موديل الجهاز."); return; }
    setSaving(true);
    try {
      await addDevice({ ...form, customerName: form.customerName.trim(), deviceModel: form.deviceModel.trim(), customerPhone: form.customerPhone.trim() });
      router.back();
    } catch { Alert.alert("تعذر الحفظ", "حدث خطأ أثناء حفظ الجهاز. حاول مرة أخرى."); } finally { setSaving(false); }
  }

  return <ScreenContainer edges={["top", "left", "right", "bottom"]}><KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === "ios" ? "padding" : "height"}><ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled"><View style={styles.header}><Pressable onPress={() => router.back()} style={styles.close} accessibilityRole="button" accessibilityLabel="إغلاق"><MaterialIcons name="close" size={22} color={colors.foreground} /></Pressable><View><Text style={styles.eyebrow}>سجل جديد</Text><Text style={styles.title}>إضافة جهاز</Text></View></View>
    <Field styles={styles} label="اسم الزبون *" value={form.customerName} onChangeText={(customerName) => set({ customerName })} placeholder="مثال: أحمد علي" />
    <Field styles={styles} label="رقم الهاتف" value={form.customerPhone} onChangeText={(customerPhone) => set({ customerPhone })} placeholder="07xxxxxxxxx" keyboardType="phone-pad" />
    <Text style={styles.label}>نوع الجهاز</Text><ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chips}>{DEVICE_TYPES.map((type) => <Pressable key={type} onPress={() => set({ deviceType: type })} style={[styles.chip, form.deviceType === type && styles.chipActive]}><Text style={[styles.chipText, form.deviceType === type && styles.chipTextActive]}>{type}</Text></Pressable>)}</ScrollView>
    <Field styles={styles} label="اسم الجهاز أو الموديل *" value={form.deviceModel} onChangeText={(deviceModel) => set({ deviceModel })} placeholder="مثال: iPhone 13 Pro" />
    <Text style={styles.label}>حالة الجهاز عند الاستلام</Text><ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chips}>{DEVICE_STATUSES.slice(0, 5).map((status) => <Pressable key={status} onPress={() => set({ status: status as DeviceStatus })} style={[styles.chip, form.status === status && styles.chipActive]}><Text style={[styles.chipText, form.status === status && styles.chipTextActive]}>{status}</Text></Pressable>)}</ScrollView>
    <Field styles={styles} label="ملاحظات" value={form.notes} onChangeText={(notes) => set({ notes })} placeholder="وصف العطل أو الملحقات المرفقة" multiline />
    <Text style={styles.label}>صور الجهاز</Text><View style={styles.photoActions}><Pressable onPress={() => void takePhoto()} style={styles.photoButton}><MaterialIcons name="photo-camera" size={20} color={colors.primary} /><Text style={styles.photoText}>التقاط صورة</Text></Pressable><Pressable onPress={() => void pickImages()} style={styles.photoButton}><MaterialIcons name="photo-library" size={20} color={colors.primary} /><Text style={styles.photoText}>من المعرض</Text></Pressable></View>{form.imageUris.length > 0 && <ScrollView horizontal contentContainerStyle={styles.photos}>{form.imageUris.map((uri) => <Image key={uri} source={{ uri }} style={styles.photo} />)}</ScrollView>}
    <Pressable disabled={saving} onPress={() => void save()} style={({ pressed }) => [styles.save, pressed && { opacity: 0.75 }, saving && { opacity: 0.55 }]} accessibilityRole="button" accessibilityLabel="حفظ الجهاز"><MaterialIcons name="save" size={21} color={colors.onPrimary} /><Text style={styles.saveText}>{saving ? "جارٍ الحفظ..." : `حفظ ${draft.orderNumber}`}</Text></Pressable>
  </ScrollView></KeyboardAvoidingView></ScreenContainer>;
}

type FormStyles = ReturnType<typeof makeStyles>;
function Field({ styles, label, value, onChangeText, placeholder, keyboardType, multiline }: { styles: FormStyles; label: string; value: string; onChangeText: (value: string) => void; placeholder: string; keyboardType?: "default" | "phone-pad" | "numeric"; multiline?: boolean }) { return <View style={styles.field}><Text style={styles.label}>{label}</Text><TextInput value={value} onChangeText={onChangeText} placeholder={placeholder} placeholderTextColor={styles.placeholder.color as string} keyboardType={keyboardType} multiline={multiline} numberOfLines={multiline ? 4 : 1} style={[styles.input, multiline && styles.notes]} textAlign="right" /></View>; }

function makeStyles(c: typeof SchemeColors.light) { return StyleSheet.create({ content: { padding: 20, paddingBottom: 40, gap: 6, direction: "rtl" }, header: { flexDirection: "row-reverse", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }, eyebrow: { color: c.primary, fontSize: 12, fontWeight: "800", textAlign: "right" }, title: { color: c.foreground, fontSize: 28, fontWeight: "900", textAlign: "right", marginTop: 3 }, close: { width: 42, height: 42, borderRadius: 14, backgroundColor: c.surface, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: c.border }, field: { marginBottom: 8, minWidth: 0 }, label: { color: c.foreground, fontSize: 12, fontWeight: "800", textAlign: "right", marginBottom: 7, marginTop: 7 }, input: { borderWidth: 1, borderColor: c.border, borderRadius: 13, backgroundColor: c.surface, paddingHorizontal: 13, paddingVertical: 13, color: c.foreground, fontSize: 14 }, placeholder: { color: c.muted }, chips: { flexDirection: "row-reverse", gap: 7, paddingBottom: 6 }, chip: { backgroundColor: c.surface, borderWidth: 1, borderColor: c.border, borderRadius: 11, paddingHorizontal: 11, paddingVertical: 9 }, chipActive: { backgroundColor: c.primary, borderColor: c.primary }, chipText: { color: c.muted, fontSize: 11, fontWeight: "700" }, chipTextActive: { color: c.onPrimary }, photoActions: { flexDirection: "row-reverse", gap: 9 }, photoButton: { flex: 1, borderWidth: 1, borderColor: c.border, borderStyle: "dashed", borderRadius: 14, padding: 15, alignItems: "center", gap: 5, backgroundColor: c.surface }, photoText: { color: c.primary, fontSize: 12, fontWeight: "800" }, photos: { flexDirection: "row-reverse", gap: 8, paddingVertical: 8 }, photo: { width: 78, height: 78, borderRadius: 12, backgroundColor: c.border }, notes: { minHeight: 92, textAlignVertical: "top" }, save: { backgroundColor: c.primary, borderRadius: 15, padding: 16, alignItems: "center", justifyContent: "center", flexDirection: "row-reverse", gap: 8, marginTop: 14 }, saveText: { color: c.onPrimary, fontSize: 15, fontWeight: "900" } }); }
