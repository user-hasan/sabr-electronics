import "../global.css";

import { useCallback, useState } from "react";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";

import { AppLock } from "@/components/app-lock";
import { BrandSplash } from "@/components/brand-splash";
import { AppDataProvider } from "@/lib/app-store";
import { ThemeProvider } from "@/lib/theme-provider";

export default function RootLayout() {
  const [showBrandSplash, setShowBrandSplash] = useState(true);
  const finishSplash = useCallback(() => setShowBrandSplash(false), []);
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
        {showBrandSplash && <BrandSplash onDone={finishSplash} />}
      </AppDataProvider>
    </ThemeProvider>
  );
}
