import { useMemo, useState } from "react";
import { FlatList, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { router } from "expo-router";
import MaterialIcons from "@expo/vector-icons/MaterialIcons";

import { ScreenContainer } from "@/components/screen-container";
import { useAppData } from "@/lib/app-store";
import { DEVICE_STATUSES, formatDate, isOverdue, matchesDevice, STATUS_COLORS, type DeviceRecord, type DeviceStatus } from "@/lib/app-types";

export default function DevicesScreen() {
  const { devices } = useAppData();
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<DeviceStatus | "الكل">("الكل");
  const filtered = useMemo(() => devices.filter((device) => !device.isArchived && (status === "الكل" || device.status === status) && matchesDevice(device, query)), [devices, query, status]);

  return (
    <ScreenContainer>
      <View style={styles.container}>
        <View style={styles.header}><View><Text style={styles.eyebrow}>سجل العمل</Text><Text style={styles.title}>الأجهزة</Text></View><Pressable onPress={() => router.push("/device/new" as any)} style={({ pressed }) => [styles.addButton, pressed && styles.pressed]}><MaterialIcons name="add" size={22} color="#FFF" /></Pressable></View>
        <View style={styles.searchBox}><MaterialIcons name="search" size={21} color="#9A9287" /><TextInput value={query} onChangeText={setQuery} placeholder="ابحث بالاسم أو الرقم أو الموديل" placeholderTextColor="#A69C90" style={styles.input} textAlign="right" /></View>
        <FlatList horizontal data={["الكل", ...DEVICE_STATUSES] as const} keyExtractor={(item) => item} showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters} renderItem={({ item }) => <Pressable onPress={() => setStatus(item)} style={[styles.filter, status === item && styles.filterActive]}><Text style={[styles.filterText, status === item && styles.filterTextActive]}>{item}</Text></Pressable>} />
        <View style={styles.resultLine}><Text style={styles.resultText}>{filtered.length} سجل</Text><Text style={styles.resultHint}>{query ? `نتائج البحث عن «${query}»` : "السجلات النشطة"}</Text></View>
        <FlatList data={filtered} keyExtractor={(item) => item.id} showsVerticalScrollIndicator={false} contentContainerStyle={styles.list} renderItem={({ item }) => <DeviceCard device={item} />} ListEmptyComponent={<View style={styles.empty}><MaterialIcons name="search-off" size={34} color="#C7BDAE" /><Text style={styles.emptyTitle}>لم نعثر على أجهزة</Text><Text style={styles.emptyText}>جرّب كلمة بحث أخرى أو أضف جهازًا جديدًا.</Text></View>} />
      </View>
    </ScreenContainer>
  );
}

function DeviceCard({ device }: { device: DeviceRecord }) {
  const overdue = isOverdue(device);
  return <Pressable onPress={() => router.push((`/device/${device.id}`) as any)} style={({ pressed }) => [styles.card, pressed && styles.pressed]}><View style={styles.cardTop}><View style={[styles.icon, { backgroundColor: `${STATUS_COLORS[device.status]}18` }]}><MaterialIcons name="phone-iphone" size={21} color={STATUS_COLORS[device.status]} /></View><View style={styles.cardMain}><View style={styles.cardTitleLine}><Text style={styles.deviceName}>{device.deviceModel || device.deviceType}</Text><Text style={styles.order}>{device.orderNumber}</Text></View><Text style={styles.customer}>{device.customerName} • {device.customerPhone}</Text><View style={styles.metaLine}><Text style={[styles.status, { color: STATUS_COLORS[device.status] }]}>{device.status}</Text><Text style={styles.date}>استلام {formatDate(device.receivedAt)}</Text>{overdue && <Text style={styles.overdue}>متأخر</Text>}</View></View><MaterialIcons name="chevron-left" size={22} color="#B6ADA1" /></View></Pressable>;
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingHorizontal: 20, paddingTop: 16, direction: "rtl" },
  header: { flexDirection: "row-reverse", justifyContent: "space-between", alignItems: "center", marginBottom: 16 },
  eyebrow: { color: "#9A661D", fontSize: 12, fontWeight: "800", textAlign: "right" },
  title: { color: "#1F2937", fontSize: 29, fontWeight: "900", marginTop: 3, textAlign: "right" },
  addButton: { width: 46, height: 46, borderRadius: 15, backgroundColor: "#9A661D", justifyContent: "center", alignItems: "center" },
  pressed: { opacity: 0.72, transform: [{ scale: 0.985 }] },
  searchBox: { backgroundColor: "#FFF", borderWidth: 1, borderColor: "#E8E0D4", borderRadius: 15, height: 52, paddingHorizontal: 14, flexDirection: "row-reverse", alignItems: "center", gap: 9 },
  input: { flex: 1, color: "#1F2937", fontSize: 13 },
  filters: { flexDirection: "row-reverse", gap: 8, paddingVertical: 13 },
  filter: { backgroundColor: "#FFF", borderWidth: 1, borderColor: "#E8E0D4", paddingHorizontal: 12, paddingVertical: 9, borderRadius: 12 },
  filterActive: { backgroundColor: "#9A661D", borderColor: "#9A661D" },
  filterText: { color: "#7C7367", fontSize: 11, fontWeight: "700" },
  filterTextActive: { color: "#FFF" },
  resultLine: { flexDirection: "row-reverse", justifyContent: "space-between", alignItems: "center", marginBottom: 10 },
  resultText: { color: "#1F2937", fontSize: 13, fontWeight: "900" },
  resultHint: { color: "#9A9287", fontSize: 11 },
  list: { gap: 10, paddingBottom: 30 },
  card: { backgroundColor: "#FFF", borderWidth: 1, borderColor: "#EEE7DC", borderRadius: 18, padding: 13 },
  cardTop: { flexDirection: "row-reverse", alignItems: "center", gap: 10 },
  icon: { width: 44, height: 44, borderRadius: 14, alignItems: "center", justifyContent: "center" },
  cardMain: { flex: 1, alignItems: "flex-end" },
  cardTitleLine: { width: "100%", flexDirection: "row-reverse", justifyContent: "space-between", alignItems: "center" },
  deviceName: { color: "#1F2937", fontSize: 15, fontWeight: "900", flex: 1, textAlign: "right" },
  order: { color: "#9A661D", fontSize: 11, fontWeight: "900" },
  customer: { color: "#7C7367", fontSize: 11, marginTop: 5 },
  metaLine: { flexDirection: "row-reverse", alignItems: "center", gap: 8, marginTop: 7 },
  status: { fontSize: 10, fontWeight: "900" },
  date: { color: "#9A9287", fontSize: 10 },
  overdue: { color: "#C25B56", backgroundColor: "#FCE9E7", paddingHorizontal: 6, paddingVertical: 3, borderRadius: 6, fontSize: 9, fontWeight: "800" },
  empty: { backgroundColor: "#FFF", borderRadius: 18, padding: 30, alignItems: "center", borderWidth: 1, borderColor: "#EEE7DC", marginTop: 18 },
  emptyTitle: { color: "#4B5563", fontWeight: "800", fontSize: 15, marginTop: 10 },
  emptyText: { color: "#9A9287", fontSize: 12, marginTop: 4, textAlign: "center" },
});
