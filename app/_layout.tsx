import "../global.css";

import { useCallback, useState } from "react";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";

import { AppLock } from "@/components/app-lock";
import { AppUpdateNotice } from "@/components/app-update-notice";
import { BrandSplash } from "@/components/brand-splash";
import { AppDataProvider } from "@/lib/app-store";
import { ThemeProvider, useThemeContext } from "@/lib/theme-provider";

export default function RootLayout() {
  const [showBrandSplash, setShowBrandSplash] = useState(true);
  const finishSplash = useCallback(() => setShowBrandSplash(false), []);
  return (
    <ThemeProvider>
      <AppDataProvider>
        <RootContent showBrandSplash={showBrandSplash} finishSplash={finishSplash} />
      </AppDataProvider>
    </ThemeProvider>
  );
}

function RootContent({ showBrandSplash, finishSplash }: { showBrandSplash: boolean; finishSplash: () => void }) {
  const { colorScheme } = useThemeContext();
  return (
    <>
      <StatusBar style={colorScheme === "dark" ? "light" : "dark"} />
      <AppLock />
      <AppUpdateNotice />
      <Stack screenOptions={{ headerShown: false, animation: "fade", contentStyle: { backgroundColor: "transparent" } }}>
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="device/new" options={{ presentation: "modal" }} />
        <Stack.Screen name="device/[id]" />
      </Stack>
      {showBrandSplash && <BrandSplash onDone={finishSplash} />}
    </>
  );
}
