import { useMemo, useState } from "react";
import { FlatList, Pressable, ScrollView, StyleSheet, Text, TextInput, View, useWindowDimensions } from "react-native";
import { router } from "expo-router";
import MaterialIcons from "@expo/vector-icons/MaterialIcons";
import { ScreenContainer } from "@/components/screen-container";
import { useAppData } from "@/lib/app-store";
import { DEVICE_TYPES, formatDate, isOverdue, matchesDevice, STATUS_COLORS, type DeviceRecord } from "@/lib/app-types";
import { useColors } from "@/hooks/use-colors";

const FILTERS = ["الكل", ...DEVICE_TYPES] as const;

export default function DevicesScreen() {
  const colors = useColors();
  const { width } = useWindowDimensions();
  const styles = useMemo(() => makeStyles(colors, width), [colors, width]);
  const { devices } = useAppData();
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>("الكل");
  const filtered = useMemo(
    () => devices.filter((d) => !d.isArchived && (filter === "الكل" || d.deviceType === filter) && matchesDevice(d, query)),
    [devices, filter, query]
  );

  return (
    <ScreenContainer>
      <View style={styles.container}>
        <View style={styles.header}>
          <View style={styles.headerText}>
            <Text style={styles.eyebrow}>SABER ELECTRONICS</Text>
            <Text style={styles.title}>الأجهزة</Text>
          </View>
          <Pressable onPress={() => router.push("/device/new" as any)} style={styles.add} accessibilityRole="button" accessibilityLabel="إضافة جهاز">
            <MaterialIcons name="add" size={23} color="#FFF" />
          </Pressable>
        </View>

        <View style={styles.search}>
          <MaterialIcons name="search" size={21} color={colors.muted} />
          <TextInput value={query} onChangeText={setQuery} placeholder="ابحث باسم العميل أو رقم الطلب" placeholderTextColor={colors.muted} style={styles.input} textAlign="right" />
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters} style={styles.filtersScroll}>
          {FILTERS.map((item) => (
            <Pressable key={item} onPress={() => setFilter(item)} style={[styles.filter, filter === item && styles.filterActive]}>
              <Text style={[styles.filterText, filter === item && styles.filterTextActive]}>{item}</Text>
            </Pressable>
          ))}
        </ScrollView>

        <View style={styles.result}>
          <Text style={styles.count}>{filtered.length} سجل</Text>
          <Text style={styles.hint}>{query ? `نتائج «${query}»` : "السجلات النشطة"}</Text>
        </View>

        <FlatList
          data={filtered}
          keyExtractor={(item) => item.id}
          showsVerticalScrollIndicator={false}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => <DeviceCard device={item} styles={styles} />}
          ListEmptyComponent={
            <View style={styles.empty}>
              <MaterialIcons name="search-off" size={34} color={colors.muted} />
              <Text style={styles.emptyTitle}>لم نعثر على أجهزة</Text>
              <Text style={styles.emptyText}>جرّب كلمة بحث أخرى أو أضف جهازًا جديدًا.</Text>
            </View>
          }
        />
      </View>
    </ScreenContainer>
  );
}

function DeviceCard({ device, styles }: { device: DeviceRecord; styles: ReturnType<typeof makeStyles> }) {
  const overdue = isOverdue(device);
  return (
    <Pressable onPress={() => router.push((`/device/${device.id}`) as any)} style={styles.card}>
      <View style={styles.cardTop}>
        <View style={[styles.icon, { backgroundColor: `${STATUS_COLORS[device.status]}22` }]}>
          <MaterialIcons name="memory" size={21} color={STATUS_COLORS[device.status]} />
        </View>
        <View style={styles.main}>
          <Text style={styles.name} numberOfLines={1}>{device.deviceModel || device.deviceType}</Text>
          <Text style={styles.customer} numberOfLines={1}>{device.deviceType} • {device.customerName}</Text>
          <Text style={styles.meta} numberOfLines={1}>{device.orderNumber} • استلام {formatDate(device.receivedAt)}</Text>
        </View>
        <View style={styles.right}>
          <Text style={[styles.status, { color: STATUS_COLORS[device.status] }]} numberOfLines={2}>{device.status}</Text>
          {overdue && <Text style={styles.overdue}>متأخر</Text>}
        </View>
      </View>
    </Pressable>
  );
}

function makeStyles(c: ReturnType<typeof useColors>, width: number) {
  const narrow = width < 380;
  const horizontalPadding = width >= 600 ? 28 : narrow ? 14 : 20;
  return StyleSheet.create({
    container: { flex: 1, paddingHorizontal: horizontalPadding, paddingTop: 16, direction: "rtl" },
    header: { flexDirection: "row-reverse", justifyContent: "space-between", alignItems: "center", marginBottom: 16 },
    headerText: { flexShrink: 1, minWidth: 0 },
    eyebrow: { color: c.primary, fontSize: 11, fontWeight: "900", textAlign: "right", letterSpacing: 1 },
    title: { color: c.foreground, fontSize: width >= 600 ? 31 : 29, fontWeight: "900", marginTop: 3, textAlign: "right" },
    add: { width: narrow ? 44 : 48, height: narrow ? 44 : 48, borderRadius: 15, backgroundColor: c.primary, justifyContent: "center", alignItems: "center", marginStart: 10 },
    search: { backgroundColor: c.surface, borderWidth: 1, borderColor: c.border, borderRadius: 15, minHeight: 52, paddingHorizontal: 14, flexDirection: "row-reverse", alignItems: "center", gap: 9 },
    input: { flex: 1, minWidth: 0, color: c.foreground, fontSize: narrow ? 12 : 13 },
    filtersScroll: { flexGrow: 0 },
    filters: { flexDirection: "row-reverse", gap: 8, paddingVertical: 13, paddingHorizontal: 1 },
    filter: { backgroundColor: c.surface, borderWidth: 1, borderColor: c.border, paddingHorizontal: narrow ? 10 : 12, paddingVertical: 9, borderRadius: 12 },
    filterActive: { backgroundColor: c.primary, borderColor: c.primary },
    filterText: { color: c.muted, fontSize: narrow ? 10 : 11, fontWeight: "700" },
    filterTextActive: { color: "#FFF" },
    result: { flexDirection: "row-reverse", justifyContent: "space-between", marginBottom: 10, gap: 8 },
    count: { color: c.foreground, fontSize: 13, fontWeight: "900" },
    hint: { color: c.muted, fontSize: 11, flexShrink: 1, textAlign: "left" },
    list: { gap: 10, paddingBottom: 30 },
    card: { backgroundColor: c.surface, borderWidth: 1, borderColor: c.border, borderRadius: 18, padding: narrow ? 11 : 13 },
    cardTop: { flexDirection: "row-reverse", alignItems: "center", gap: narrow ? 7 : 10 },
    icon: { width: narrow ? 40 : 44, height: narrow ? 40 : 44, borderRadius: 14, alignItems: "center", justifyContent: "center" },
    main: { flex: 1, minWidth: 0, alignItems: "flex-end" },
    name: { color: c.foreground, fontSize: narrow ? 14 : 15, fontWeight: "900", textAlign: "right" },
    customer: { color: c.muted, fontSize: 11, marginTop: 5, textAlign: "right" },
    meta: { color: c.muted, fontSize: 10, marginTop: 7, textAlign: "right" },
    right: { alignItems: "flex-start", minWidth: narrow ? 58 : 74, maxWidth: narrow ? 82 : 100 },
    status: { fontSize: 10, fontWeight: "900", textAlign: "left" },
    overdue: { color: c.error, backgroundColor: "#FCE9E7", paddingHorizontal: 6, paddingVertical: 3, borderRadius: 6, fontSize: 9, marginTop: 6 },
    empty: { backgroundColor: c.surface, borderRadius: 18, padding: 30, alignItems: "center", borderWidth: 1, borderColor: c.border, marginTop: 18 },
    emptyTitle: { color: c.foreground, fontWeight: "800", fontSize: 15, marginTop: 10 },
    emptyText: { color: c.muted, fontSize: 12, marginTop: 4, textAlign: "center" },
  });
}
