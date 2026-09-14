import { useMemo } from "react";
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import MaterialIcons from "@expo/vector-icons/MaterialIcons";

import { ScreenContainer } from "@/components/screen-container";
import { useAppData } from "@/lib/app-store";
import { DEVICE_STATUSES, formatDate, isOverdue, STATUS_COLORS } from "@/lib/app-types";

export default function HomeScreen() {
  const { devices, isHydrated } = useAppData();
  const activeDevices = devices.filter((device) => !device.isArchived);
  const ready = activeDevices.filter((device) => device.status === "جاهز للتسليم");
  const overdue = activeDevices.filter(isOverdue);
  const revenue = activeDevices.reduce((sum, device) => sum + device.paidAmount, 0);
  const recent = useMemo(() => activeDevices.slice(0, 4), [activeDevices]);

  if (!isHydrated) return <ScreenContainer><View style={styles.loading}><ActivityIndicator color="#9A661D" size="large" /></View></ScreenContainer>;

  return (
    <ScreenContainer edges={["top", "left", "right"]}>
      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <View>
            <Text style={styles.eyebrow}>إدارة المحل اليومية</Text>
            <Text style={styles.title}>صبر إلكترونكس</Text>
            <Text style={styles.subtitle}>كل جهاز في مكانه، وكل موعد تحت السيطرة.</Text>
          </View>
          <View style={styles.logo}><MaterialIcons name="memory" size={28} color="#FFF" /></View>
        </View>

        <View style={styles.heroCard}>
          <View style={{ flex: 1 }}>
            <Text style={styles.heroKicker}>ملخص العمل</Text>
            <Text style={styles.heroTitle}>{activeDevices.length} جهاز قيد المتابعة</Text>
            <Text style={styles.heroText}>{ready.length ? `${ready.length} جاهز للتسليم الآن` : "لا توجد أجهزة جاهزة للتسليم الآن"}</Text>
          </View>
          <View style={styles.heroIcon}><MaterialIcons name="inventory-2" size={30} color="#9A661D" /></View>
        </View>

        <View style={styles.quickRow}>
          <Pressable onPress={() => router.push("/device/new" as any)} style={({ pressed }) => [styles.primaryButton, pressed && styles.pressed]}>
            <MaterialIcons name="add" size={21} color="#FFF" /><Text style={styles.primaryText}>إضافة جهاز</Text>
          </Pressable>
          <Pressable onPress={() => router.push("/devices" as any)} style={({ pressed }) => [styles.outlineButton, pressed && styles.pressed]}>
            <MaterialIcons name="search" size={20} color="#9A661D" /><Text style={styles.outlineText}>بحث سريع</Text>
          </Pressable>
        </View>

        <View style={styles.statsGrid}>
          <StatCard label="قيد المتابعة" value={activeDevices.filter((d) => d.status !== "تم التسليم" && d.status !== "ملغي").length} icon="build" color="#7C3AED" />
          <StatCard label="جاهز للتسليم" value={ready.length} icon="check-circle" color="#2E8B70" />
          <StatCard label="متأخر" value={overdue.length} icon="schedule" color="#C25B56" />
          <StatCard label="المدفوع اليوم" value={`${revenue.toLocaleString()} د.ع`} icon="payments" color="#C98B32" />
        </View>

        <SectionHeader title="الحالات" action="عرض الكل" onPress={() => router.push("/devices" as any)} />
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.statusScroller}>
          {DEVICE_STATUSES.map((status) => {
            const count = activeDevices.filter((device) => device.status === status).length;
            return <View key={status} style={styles.statusPill}><View style={[styles.dot, { backgroundColor: STATUS_COLORS[status] }]} /><Text style={styles.statusLabel}>{status}</Text><Text style={styles.statusCount}>{count}</Text></View>;
          })}
        </ScrollView>

        <SectionHeader title="آخر الأجهزة" action="كل الأجهزة" onPress={() => router.push("/devices" as any)} />
        {recent.length === 0 ? <EmptyState /> : recent.map((device) => (
          <Pressable key={device.id} onPress={() => router.push((`/device/${device.id}`) as any)} style={({ pressed }) => [styles.deviceRow, pressed && styles.pressed]}>
            <View style={styles.deviceBadge}><MaterialIcons name="phone-iphone" size={20} color="#9A661D" /></View>
            <View style={styles.deviceInfo}><Text style={styles.deviceName}>{device.deviceModel || device.deviceType}</Text><Text style={styles.deviceMeta}>{device.customerName} • {device.orderNumber}</Text></View>
            <View style={styles.deviceRight}><Text style={[styles.statusMini, { color: STATUS_COLORS[device.status] }]}>{device.status}</Text><Text style={styles.date}>{formatDate(device.receivedAt)}</Text></View>
          </Pressable>
        ))}
      </ScrollView>
    </ScreenContainer>
  );
}

function StatCard({ label, value, icon, color }: { label: string; value: number | string; icon: keyof typeof MaterialIcons.glyphMap; color: string }) {
  return <View style={styles.statCard}><View style={[styles.statIcon, { backgroundColor: `${color}18` }]}><MaterialIcons name={icon} size={19} color={color} /></View><Text style={styles.statValue}>{value}</Text><Text style={styles.statLabel}>{label}</Text></View>;
}

function SectionHeader({ title, action, onPress }: { title: string; action: string; onPress: () => void }) {
  return <View style={styles.sectionHeader}><Text style={styles.sectionTitle}>{title}</Text><Pressable onPress={onPress}><Text style={styles.sectionAction}>{action}</Text></Pressable></View>;
}

function EmptyState() {
  return <View style={styles.empty}><MaterialIcons name="inbox" size={34} color="#C7BDAE" /><Text style={styles.emptyTitle}>لا توجد أجهزة بعد</Text><Text style={styles.emptyText}>ابدأ بإضافة أول جهاز لاستلامه وتتبع حالته.</Text></View>;
}

const styles = StyleSheet.create({
  content: { padding: 20, paddingBottom: 34, gap: 16, direction: "rtl" },
  loading: { flex: 1, alignItems: "center", justifyContent: "center" },
  header: { flexDirection: "row-reverse", justifyContent: "space-between", alignItems: "center", marginBottom: 4 },
  eyebrow: { color: "#9A661D", fontSize: 12, fontWeight: "700", marginBottom: 5, textAlign: "right" },
  title: { color: "#1F2937", fontSize: 29, fontWeight: "900", textAlign: "right" },
  subtitle: { color: "#7C7367", fontSize: 13, marginTop: 5, textAlign: "right" },
  logo: { width: 54, height: 54, backgroundColor: "#9A661D", borderRadius: 18, alignItems: "center", justifyContent: "center" },
  heroCard: { backgroundColor: "#F1E7D4", borderRadius: 24, padding: 19, flexDirection: "row-reverse", alignItems: "center", gap: 15 },
  heroKicker: { color: "#9A661D", fontWeight: "800", fontSize: 12, textAlign: "right" },
  heroTitle: { color: "#3C2C17", fontSize: 20, fontWeight: "900", marginTop: 6, textAlign: "right" },
  heroText: { color: "#7B6546", fontSize: 13, marginTop: 5, textAlign: "right" },
  heroIcon: { width: 58, height: 58, borderRadius: 18, backgroundColor: "#FFF8EC", alignItems: "center", justifyContent: "center" },
  quickRow: { flexDirection: "row-reverse", gap: 10 },
  primaryButton: { backgroundColor: "#9A661D", borderRadius: 14, paddingVertical: 14, flex: 1, flexDirection: "row-reverse", justifyContent: "center", alignItems: "center", gap: 7 },
  outlineButton: { backgroundColor: "#FFF", borderWidth: 1, borderColor: "#D9CDBD", borderRadius: 14, paddingVertical: 14, flex: 1, flexDirection: "row-reverse", justifyContent: "center", alignItems: "center", gap: 7 },
  primaryText: { color: "#FFF", fontSize: 14, fontWeight: "800" },
  outlineText: { color: "#9A661D", fontSize: 14, fontWeight: "800" },
  pressed: { opacity: 0.72, transform: [{ scale: 0.985 }] },
  statsGrid: { flexDirection: "row-reverse", flexWrap: "wrap", gap: 10 },
  statCard: { width: "48.5%", minHeight: 108, backgroundColor: "#FFF", borderWidth: 1, borderColor: "#EEE7DC", borderRadius: 18, padding: 13, alignItems: "flex-end" },
  statIcon: { width: 32, height: 32, borderRadius: 11, alignItems: "center", justifyContent: "center", marginBottom: 8 },
  statValue: { color: "#1F2937", fontSize: 20, fontWeight: "900" },
  statLabel: { color: "#80776B", fontSize: 12, marginTop: 3 },
  sectionHeader: { flexDirection: "row-reverse", justifyContent: "space-between", alignItems: "center", marginTop: 4 },
  sectionTitle: { color: "#1F2937", fontSize: 17, fontWeight: "900" },
  sectionAction: { color: "#9A661D", fontSize: 12, fontWeight: "800" },
  statusScroller: { gap: 8, flexDirection: "row-reverse" },
  statusPill: { backgroundColor: "#FFF", borderWidth: 1, borderColor: "#EEE7DC", borderRadius: 14, paddingHorizontal: 11, paddingVertical: 10, flexDirection: "row-reverse", alignItems: "center", gap: 5 },
  dot: { width: 7, height: 7, borderRadius: 4 },
  statusLabel: { color: "#6B7280", fontSize: 11 },
  statusCount: { color: "#1F2937", fontSize: 12, fontWeight: "900" },
  deviceRow: { backgroundColor: "#FFF", borderWidth: 1, borderColor: "#EEE7DC", borderRadius: 17, padding: 12, flexDirection: "row-reverse", alignItems: "center", gap: 10 },
  deviceBadge: { width: 40, height: 40, borderRadius: 13, backgroundColor: "#F6EEDC", alignItems: "center", justifyContent: "center" },
  deviceInfo: { flex: 1, alignItems: "flex-end" },
  deviceName: { color: "#1F2937", fontWeight: "800", fontSize: 14 },
  deviceMeta: { color: "#8A8174", fontSize: 11, marginTop: 4 },
  deviceRight: { alignItems: "flex-start", minWidth: 90 },
  statusMini: { fontSize: 10, fontWeight: "900" },
  date: { color: "#9A9287", fontSize: 10, marginTop: 5 },
  empty: { backgroundColor: "#FFF", borderRadius: 18, padding: 24, alignItems: "center", borderWidth: 1, borderColor: "#EEE7DC" },
  emptyTitle: { color: "#4B5563", fontWeight: "800", fontSize: 15, marginTop: 10 },
  emptyText: { color: "#9A9287", fontSize: 12, marginTop: 4, textAlign: "center" },
});
