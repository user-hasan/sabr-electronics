export const DEVICE_STATUSES = [
  "تم الاستلام",
  "قيد الفحص",
  "بانتظار موافقة الزبون",
  "قيد الإصلاح",
  "جاهز للتسليم",
  "تم التسليم",
  "لم يتم الإصلاح",
  "ملغي",
] as const;

export type DeviceStatus = (typeof DEVICE_STATUSES)[number];

export type DeviceRecord = {
  id: string;
  orderNumber: string;
  customerName: string;
  customerPhone: string;
  deviceType: string;
  deviceModel: string;
  status: DeviceStatus;
  inspectionFee: number;
  totalAmount: number;
  paidAmount: number;
  receivedAt: string;
  expectedDeliveryAt: string;
  deliveredAt?: string;
  notes: string;
  imageUris: string[];
  createdAt: string;
  updatedAt: string;
  isArchived: boolean;
};

export type AppSettings = {
  pinEnabled: boolean;
  pin: string;
  biometricEnabled: boolean;
  notifyReady: boolean;
  notifyOverdue: boolean;
  whatsappReady: boolean;
  whatsappOverdue: boolean;
  currency: string;
};

export const DEFAULT_SETTINGS: AppSettings = {
  pinEnabled: false,
  pin: "",
  biometricEnabled: false,
  notifyReady: true,
  notifyOverdue: true,
  whatsappReady: false,
  whatsappOverdue: false,
  currency: "د.ع",
};

export const STATUS_COLORS: Record<DeviceStatus, string> = {
  "تم الاستلام": "#64748B",
  "قيد الفحص": "#2563EB",
  "بانتظار موافقة الزبون": "#C98B32",
  "قيد الإصلاح": "#7C3AED",
  "جاهز للتسليم": "#2E8B70",
  "تم التسليم": "#0F766E",
  "لم يتم الإصلاح": "#C25B56",
  "ملغي": "#94A3B8",
};

export function todayISO() {
  const date = new Date();
  const offset = date.getTimezoneOffset();
  return new Date(date.getTime() - offset * 60_000).toISOString().slice(0, 10);
}

export function formatDate(value?: string) {
  if (!value) return "—";
  const date = new Date(`${value}T00:00:00`);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("ar-IQ", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(date);
}

export function isOverdue(device: DeviceRecord) {
  return (
    !device.isArchived &&
    device.status !== "تم التسليم" &&
    device.status !== "ملغي" &&
    device.expectedDeliveryAt < todayISO()
  );
}

export function remainingAmount(device: DeviceRecord) {
  return Math.max(device.totalAmount - device.paidAmount, 0);
}

export function makeOrderNumber(devices: DeviceRecord[]) {
  const highest = devices.reduce((max, item) => {
    const value = Number.parseInt(item.orderNumber.replace(/\D/g, ""), 10);
    return Number.isFinite(value) ? Math.max(max, value) : max;
  }, 0);
  return `SE-${String(highest + 1).padStart(4, "0")}`;
}

export function uid() {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
}

export const DEVICE_TYPES = ["معدات طبية", "شاشات سيارات", "شاشات منزلية", "صوتيات", "مضخمات", "أخرى"];

export function matchesDevice(device: DeviceRecord, query: string) {
  const normalized = query.trim().toLocaleLowerCase("ar");
  if (!normalized) return true;
  return [device.customerName, device.customerPhone, device.deviceType, device.deviceModel, device.orderNumber]
    .join(" ")
    .toLocaleLowerCase("ar")
    .includes(normalized);
}

export function statusLabel(status: DeviceStatus) {
  return status;
}

export function createEmptyDevice(devices: DeviceRecord[]): DeviceRecord {
  const now = new Date().toISOString();
  return {
    id: uid(),
    orderNumber: makeOrderNumber(devices),
    customerName: "",
    customerPhone: "",
    deviceType: "أخرى",
    deviceModel: "",
    status: "تم الاستلام",
    inspectionFee: 0,
    totalAmount: 0,
    paidAmount: 0,
    receivedAt: todayISO(),
    expectedDeliveryAt: todayISO(),
    notes: "",
    imageUris: [],
    createdAt: now,
    updatedAt: now,
    isArchived: false,
  };
}

export function normalizeDevice(input: Partial<DeviceRecord>, fallback: DeviceRecord): DeviceRecord {
  return {
    ...fallback,
    ...input,
    inspectionFee: Number(input.inspectionFee ?? fallback.inspectionFee) || 0,
    totalAmount: Number(input.totalAmount ?? fallback.totalAmount) || 0,
    paidAmount: Number(input.paidAmount ?? fallback.paidAmount) || 0,
    imageUris: input.imageUris ?? fallback.imageUris,
    updatedAt: new Date().toISOString(),
  };
}

export function isDeviceRecord(value: unknown): value is DeviceRecord {
  return Boolean(value && typeof value === "object" && "id" in value && "customerName" in value);
}

export function sanitizeDeviceForExport(device: DeviceRecord) {
  return {
    "رقم الطلب": device.orderNumber,
    "اسم الزبون": device.customerName,
    "رقم الهاتف": device.customerPhone,
    "نوع الجهاز": device.deviceType,
    "الموديل": device.deviceModel,
    "الحالة": device.status,
    "مبلغ الفحص": device.inspectionFee,
    "المبلغ الإجمالي": device.totalAmount,
    "المبلغ المدفوع": device.paidAmount,
    "المبلغ المتبقي": remainingAmount(device),
    "تاريخ الاستلام": device.receivedAt,
    "التسليم المتوقع": device.expectedDeliveryAt,
    "تاريخ التسليم": device.deliveredAt ?? "",
    "الملاحظات": device.notes,
    "عدد الصور": device.imageUris.length,
  };
}

export function escapeCsv(value: unknown) {
  const text = String(value ?? "").replace(/"/g, '""');
  return `"${text}"`;
}

export function devicesToCsv(devices: DeviceRecord[]) {
  const rows = devices.map(sanitizeDeviceForExport);
  if (!rows.length) return "";
  const headers = Object.keys(rows[0]);
  return [headers.map(escapeCsv).join(","), ...rows.map((row) => headers.map((key) => escapeCsv(row[key as keyof typeof row])).join(","))].join("\n");
}

export function csvWithUtf8Bom(csv: string) {
  return `\uFEFF${csv}`;
}

export function devicesToReportHtml(devices: DeviceRecord[], currency: string) {
  const rows = devices.map((device) => `<tr><td>${device.orderNumber}</td><td>${device.customerName}</td><td>${device.deviceModel}</td><td>${device.status}</td><td>${device.totalAmount.toLocaleString()} ${currency}</td><td>${formatDate(device.receivedAt)}</td></tr>`).join("");
  return `<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8" /><style>body{font-family:Arial,sans-serif;color:#1f2937;padding:28px}h1{color:#8a5b1b}table{width:100%;border-collapse:collapse;margin-top:20px}th,td{border:1px solid #ded8cc;padding:8px;text-align:right;font-size:11px}th{background:#f5efe5}</style></head><body><h1>صبر إلكترونكس</h1><h2>تقرير الأجهزة</h2><p>عدد السجلات: ${devices.length}</p><table><thead><tr><th>رقم الطلب</th><th>الزبون</th><th>الجهاز</th><th>الحالة</th><th>الإجمالي</th><th>الاستلام</th></tr></thead><tbody>${rows}</tbody></table></body></html>`;
}

export function customerWhatsappMessage(device: DeviceRecord) {
  return `صبر إلكترونكس\nمرحبًا ${device.customerName}، جهازك ${device.deviceModel || device.deviceType} أصبح جاهزًا للتسليم. رقم الطلب: ${device.orderNumber}. ننتظركم في المحل.`;
}

export function customerWhatsappOverdueMessage(device: DeviceRecord) {
  return `صبر إلكترونكس\nمرحبًا ${device.customerName}، نود إبلاغكم بأن جهازكم ${device.deviceModel || device.deviceType} تجاوز موعد التسليم المتوقع. رقم الطلب: ${device.orderNumber}. سنتواصل معكم عند اكتمال العمل.`;
}
