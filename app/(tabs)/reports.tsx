import { useMemo } from "react";
import { Alert, Pressable, ScrollView, Share, StyleSheet, Text, View } from "react-native";
import * as FileSystem from "expo-file-system/legacy";
import * as Print from "expo-print";
import * as Sharing from "expo-sharing";
import MaterialIcons from "@expo/vector-icons/MaterialIcons";

import { ScreenContainer } from "@/components/screen-container";
import { useAppData } from "@/lib/app-store";
import { devicesToCsv, devicesToReportHtml, csvWithUtf8Bom, remainingAmount, STATUS_COLORS, DEVICE_STATUSES } from "@/lib/app-types";

export default function ReportsScreen() {
  const { devices, settings } = useAppData();
  const active = devices.filter((device) => !device.isArchived);
  const delivered = devices.filter((device) => device.status === "تم التسليم");
  const total = active.reduce((sum, device) => sum + device.totalAmount, 0);
  const paid = active.reduce((sum, device) => sum + device.paidAmount, 0);
  const remaining = active.reduce((sum, device) => sum + remainingAmount(device), 0);
  const byType = useMemo(() => Object.entries(active.reduce<Record<string, number>>((acc, device) => { acc[device.deviceType] = (acc[device.deviceType] ?? 0) + 1; return acc; }, {})).sort((a, b) => b[1] - a[1]), [active]);

  async function exportExcel() {
    const uri = `${FileSystem.cacheDirectory}sabr-electronics-${Date.now()}.csv`;
    await FileSystem.writeAsStringAsync(uri, csvWithUtf8Bom(devicesToCsv(devices)), { encoding: FileSystem.EncodingType.UTF8 });
    if (await Sharing.isAvailableAsync()) await Sharing.shareAsync(uri, { mimeType: "text/csv", dialogTitle: "تصدير بيانات صبر إلكترونكس" }); else await Share.share({ message: devicesToCsv(devices) });
  }
  async function exportPdf() {
    const { uri } = await Print.printToFileAsync({ html: devicesToReportHtml(devices, settings.currency) });
    if (await Sharing.isAvailableAsync()) await Sharing.shareAsync(uri, { mimeType: "application/pdf", dialogTitle: "تقرير صبر إلكترونكس" });
  }
  const safe = (work: () => Promise<void>) => { void work().catch(() => Alert.alert("تعذر التصدير", "تحقق من صلاحيات المشاركة وحاول مرة أخرى.")); };
  return <ScreenContainer><ScrollView contentContainerStyle={styles.content}><Text style={styles.eyebrow}>نظرة شاملة</Text><Text style={styles.title}>التقارير</Text><Text style={styles.subtitle}>تابع المبالغ، الحالات، وسجل التسليم من مكان واحد.</Text>
    <View style={styles.summary}><Summary label="الإجمالي المتفق" value={`${total.toLocaleString()} ${settings.currency}`} color="#9A661D" /><Summary label="المدفوع" value={`${paid.toLocaleString()} ${settings.currency}`} color="#2E8B70" /><Summary label="المتبقي" value={`${remaining.toLocaleString()} ${settings.currency}`} color="#C25B56" /><Summary label="تم التسليم" value={`${delivered.length}`} color="#7C3AED" /></View>
    <Text style={styles.section}>التوزيع حسب الحالة</Text><View style={styles.reportCard}>{DEVICE_STATUSES.map((status) => { const count = active.filter((device) => device.status === status).length; const percentage = active.length ? Math.round((count / active.length) * 100) : 0; return <View key={status} style={styles.barRow}><Text style={styles.barValue}>{count}</Text><View style={styles.barMiddle}><View style={styles.barTrack}><View style={[styles.barFill, { width: `${Math.max(percentage, count ? 3 : 0)}%`, backgroundColor: STATUS_COLORS[status] }]} /></View><Text style={styles.barLabel}>{status}</Text></View></View>; })}</View>
    <Text style={styles.section}>أكثر أنواع الأجهزة</Text><View style={styles.reportCard}>{byType.length ? byType.map(([type, count]) => <View key={type} style={styles.typeRow}><Text style={styles.typeCount}>{count} جهاز</Text><Text style={styles.typeName}>{type}</Text></View>) : <Text style={styles.muted}>لا توجد بيانات كافية بعد.</Text>}</View>
    <Text style={styles.section}>تصدير البيانات</Text><View style={styles.exportRow}><Pressable onPress={() => safe(exportExcel)} style={styles.exportButton}><MaterialIcons name="table-view" size={23} color="#2E8B70" /><Text style={styles.exportTitle}>Excel / CSV</Text><Text style={styles.exportHint}>للتحليل والحفظ</Text></Pressable><Pressable onPress={() => safe(exportPdf)} style={styles.exportButton}><MaterialIcons name="picture-as-pdf" size={23} color="#C25B56" /><Text style={styles.exportTitle}>PDF</Text><Text style={styles.exportHint}>للطباعة والمشاركة</Text></Pressable></View>
  </ScrollView></ScreenContainer>;
}
function Summary({ label, value, color }: { label: string; value: string; color: string }) { return <View style={styles.summaryCard}><View style={[styles.summaryDot, { backgroundColor: color }]} /><Text style={styles.summaryValue}>{value}</Text><Text style={styles.summaryLabel}>{label}</Text></View>; }
const styles = StyleSheet.create({ content: { padding: 20, paddingBottom: 36, direction: "rtl" }, eyebrow: { color: "#9A661D", fontSize: 12, fontWeight: "800", textAlign: "right" }, title: { color: "#1F2937", fontSize: 29, fontWeight: "900", textAlign: "right", marginTop: 3 }, subtitle: { color: "#80776B", fontSize: 13, textAlign: "right", marginTop: 6, marginBottom: 18 }, summary: { flexDirection: "row-reverse", flexWrap: "wrap", gap: 10 }, summaryCard: { width: "48.5%", backgroundColor: "#FFF", borderWidth: 1, borderColor: "#EEE7DC", borderRadius: 17, padding: 14, alignItems: "flex-end" }, summaryDot: { width: 8, height: 8, borderRadius: 4, marginBottom: 10 }, summaryValue: { color: "#1F2937", fontSize: 15, fontWeight: "900" }, summaryLabel: { color: "#91877A", fontSize: 10, marginTop: 4 }, section: { color: "#1F2937", fontSize: 17, fontWeight: "900", textAlign: "right", marginTop: 22, marginBottom: 10 }, reportCard: { backgroundColor: "#FFF", borderWidth: 1, borderColor: "#EEE7DC", borderRadius: 18, padding: 15, gap: 12 }, barRow: { flexDirection: "row-reverse", alignItems: "center", gap: 10 }, barValue: { color: "#1F2937", fontSize: 12, fontWeight: "900", width: 22, textAlign: "center" }, barMiddle: { flex: 1, flexDirection: "row-reverse", alignItems: "center", gap: 10 }, barTrack: { height: 7, backgroundColor: "#F0EBE3", borderRadius: 4, flex: 1, overflow: "hidden" }, barFill: { height: "100%", borderRadius: 4 }, barLabel: { color: "#6B7280", fontSize: 11, width: 115, textAlign: "right" }, typeRow: { flexDirection: "row-reverse", justifyContent: "space-between", borderBottomWidth: 1, borderBottomColor: "#F1EEE9", paddingBottom: 9 }, typeName: { color: "#4B5563", fontSize: 13, fontWeight: "700" }, typeCount: { color: "#9A661D", fontSize: 12, fontWeight: "800" }, muted: { color: "#9A9287", fontSize: 12, textAlign: "right" }, exportRow: { flexDirection: "row-reverse", gap: 10 }, exportButton: { flex: 1, backgroundColor: "#FFF", borderWidth: 1, borderColor: "#EEE7DC", borderRadius: 16, padding: 15, alignItems: "center" }, exportTitle: { color: "#1F2937", fontWeight: "900", fontSize: 13, marginTop: 8 }, exportHint: { color: "#9A9287", fontSize: 10, marginTop: 3 } });
