import AsyncStorage from "@react-native-async-storage/async-storage";
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";

import {
  AppSettings,
  DEFAULT_SETTINGS,
  DeviceRecord,
  DeviceStatus,
  createEmptyDevice,
  normalizeDevice,
  uid,
} from "@/lib/app-types";

const STORAGE_KEY = "sabr-electronics-local-v1";

type StoreValue = {
  devices: DeviceRecord[];
  settings: AppSettings;
  isHydrated: boolean;
  addDevice: (device: DeviceRecord) => Promise<void>;
  updateDevice: (id: string, patch: Partial<DeviceRecord>) => Promise<void>;
  updateStatus: (id: string, status: DeviceStatus) => Promise<void>;
  archiveDevice: (id: string) => Promise<void>;
  updateSettings: (patch: Partial<AppSettings>) => Promise<void>;
  resetAllData: () => Promise<void>;
  reloadFromStorage: () => Promise<void>;
  createDraft: () => DeviceRecord;
};

type PersistedState = { devices?: DeviceRecord[]; settings?: Partial<AppSettings> };

const AppDataContext = createContext<StoreValue | null>(null);

export function AppDataProvider({ children }: { children: ReactNode }) {
  const [devices, setDevices] = useState<DeviceRecord[]>([]);
  const [settings, setSettings] = useState<AppSettings>(DEFAULT_SETTINGS);
  const [isHydrated, setIsHydrated] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((value) => {
        if (!value) return;
        const parsed = JSON.parse(value) as PersistedState;
        setDevices(Array.isArray(parsed.devices) ? parsed.devices : []);
        setSettings({ ...DEFAULT_SETTINGS, ...(parsed.settings ?? {}) });
      })
      .catch(() => undefined)
      .finally(() => setIsHydrated(true));
  }, []);

  const persist = useCallback(async (nextDevices: DeviceRecord[], nextSettings: AppSettings) => {
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify({ devices: nextDevices, settings: nextSettings }));
  }, []);

  const addDevice = useCallback(async (device: DeviceRecord) => {
    setDevices((current) => {
      const next = [device, ...current];
      void persist(next, settings);
      return next;
    });
  }, [persist, settings]);

  const updateDevice = useCallback(async (id: string, patch: Partial<DeviceRecord>) => {
    setDevices((current) => {
      const next = current.map((item) => item.id === id ? normalizeDevice(patch, item) : item);
      void persist(next, settings);
      return next;
    });
  }, [persist, settings]);

  const updateStatus = useCallback(async (id: string, status: DeviceStatus) => {
    const patch: Partial<DeviceRecord> = { status };
    if (status === "تم التسليم") patch.deliveredAt = new Date().toISOString().slice(0, 10);
    await updateDevice(id, patch);
  }, [updateDevice]);

  const archiveDevice = useCallback(async (id: string) => {
    await updateDevice(id, { isArchived: true });
  }, [updateDevice]);

  const updateSettings = useCallback(async (patch: Partial<AppSettings>) => {
    setSettings((current) => {
      const next = { ...current, ...patch };
      void persist(devices, next);
      return next;
    });
  }, [devices, persist]);

  const resetAllData = useCallback(async () => {
    setDevices([]);
    setSettings(DEFAULT_SETTINGS);
    await AsyncStorage.removeItem(STORAGE_KEY);
  }, []);

  const reloadFromStorage = useCallback(async () => {
    const value = await AsyncStorage.getItem(STORAGE_KEY);
    if (!value) return;
    const parsed = JSON.parse(value) as PersistedState;
    setDevices(Array.isArray(parsed.devices) ? parsed.devices : []);
    setSettings({ ...DEFAULT_SETTINGS, ...(parsed.settings ?? {}) });
  }, []);

  const createDraft = useCallback(() => createEmptyDevice(devices), [devices]);

  const value = useMemo(() => ({ devices, settings, isHydrated, addDevice, updateDevice, updateStatus, archiveDevice, updateSettings, resetAllData, reloadFromStorage, createDraft }), [devices, settings, isHydrated, addDevice, updateDevice, updateStatus, archiveDevice, updateSettings, resetAllData, reloadFromStorage, createDraft]);
  return <AppDataContext.Provider value={value}>{children}</AppDataContext.Provider>;
}

export function useAppData() {
  const value = useContext(AppDataContext);
  if (!value) throw new Error("useAppData must be used inside AppDataProvider");
  return value;
}

export async function importLocalBackup(json: string) {
  const parsed = JSON.parse(json) as PersistedState;
  if (!Array.isArray(parsed.devices)) throw new Error("ملف النسخة الاحتياطية غير صالح");
  const cleaned = parsed.devices.filter((item) => item && typeof item.id === "string").map((item) => ({ ...item, id: item.id || uid() }));
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify({ devices: cleaned, settings: { ...DEFAULT_SETTINGS, ...(parsed.settings ?? {}) } }));
  return cleaned;
}

export async function exportLocalBackup(devices: DeviceRecord[], settings: AppSettings) {
  return JSON.stringify({ version: 1, exportedAt: new Date().toISOString(), devices, settings }, null, 2);
}

export function draftToDevice(draft: DeviceRecord, values: Partial<DeviceRecord>) {
  return normalizeDevice(values, draft);
}
