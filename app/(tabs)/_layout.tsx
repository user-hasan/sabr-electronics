import { Tabs } from "expo-router";
import { Platform } from "react-native";
import MaterialIcons from "@expo/vector-icons/MaterialIcons";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { HapticTab } from "@/components/haptic-tab";
import { useColors } from "@/hooks/use-colors";

export default function TabLayout() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const bottomPadding = Platform.OS === "web" ? 10 : Math.max(insets.bottom, 8);
  return <Tabs screenOptions={{ headerShown: false, tabBarActiveTintColor: colors.primary, tabBarInactiveTintColor: colors.muted, tabBarButton: HapticTab, tabBarStyle: { paddingTop: 7, paddingBottom: bottomPadding, height: 57 + bottomPadding, backgroundColor: colors.background, borderTopColor: colors.border, borderTopWidth: 0.5 } }}>
    <Tabs.Screen name="index" options={{ title: "الرئيسية", tabBarIcon: ({ color, size }) => <MaterialIcons name="dashboard" color={color} size={size} /> }} />
    <Tabs.Screen name="devices" options={{ title: "الأجهزة", tabBarIcon: ({ color, size }) => <MaterialIcons name="precision-manufacturing" color={color} size={size} /> }} />
    <Tabs.Screen name="reports" options={{ title: "التقارير", tabBarIcon: ({ color, size }) => <MaterialIcons name="bar-chart" color={color} size={size} /> }} />
    <Tabs.Screen name="settings" options={{ title: "الإعدادات", tabBarIcon: ({ color, size }) => <MaterialIcons name="settings" color={color} size={size} /> }} />
  </Tabs>;
}
