import { Platform } from "react-native";
import * as Notifications from "expo-notifications";

import { DeviceRecord, isOverdue } from "@/lib/app-types";

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: false,
    shouldSetBadge: false,
  }),
});

export async function prepareNotifications() {
  if (Platform.OS === "web") return false;
  if (Platform.OS === "android") {
    await Notifications.setNotificationChannelAsync("sabr-default", {
      name: "تنبيهات صبر إلكترونكس",
      importance: Notifications.AndroidImportance.DEFAULT,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: "#C98B32",
    });
  }
  const current = await Notifications.getPermissionsAsync();
  if (current.status === "granted") return true;
  const requested = await Notifications.requestPermissionsAsync();
  return requested.status === "granted";
}

export async function scheduleDeviceNotifications(devices: DeviceRecord[], options: { ready: boolean; overdue: boolean }) {
  if (Platform.OS === "web") return;
  const granted = await prepareNotifications();
  if (!granted) return;
  await Notifications.cancelAllScheduledNotificationsAsync();
  const active = devices.filter((device) => !device.isArchived && device.status !== "تم التسليم" && device.status !== "ملغي");
  for (const device of active) {
    if (options.ready && device.status === "جاهز للتسليم") {
      await Notifications.scheduleNotificationAsync({
        content: { title: "جهاز جاهز للتسليم", body: `${device.orderNumber} — ${device.customerName}`, data: { deviceId: device.id } },
        trigger: { seconds: 3, channelId: "sabr-default" },
      });
    }
    if (options.overdue && isOverdue(device)) {
      await Notifications.scheduleNotificationAsync({
        content: { title: "جهاز متأخر", body: `${device.orderNumber} — موعد التسليم ${device.expectedDeliveryAt}`, data: { deviceId: device.id } },
        trigger: { seconds: 5, channelId: "sabr-default" },
      });
    }
  }
}
