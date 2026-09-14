import "../global.css";

import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";

import { AppLock } from "@/components/app-lock";
import { AppDataProvider } from "@/lib/app-store";
import { ThemeProvider } from "@/lib/theme-provider";

export default function RootLayout() {
  return (
    <ThemeProvider>
      <AppDataProvider>
        <StatusBar style="dark" />
        <AppLock />
        <Stack screenOptions={{ headerShown: false, animation: "fade" }}>
          <Stack.Screen name="(tabs)" />
          <Stack.Screen name="device/new" options={{ presentation: "modal" }} />
          <Stack.Screen name="device/[id]" />
        </Stack>
      </AppDataProvider>
    </ThemeProvider>
  );
}
