# Icon & Visual Assets Management — دليل إدارة الأيقونات والوسائط البصرية

## 1. Objective & Scope

When developing **صبر إلكترونكس** (Sabr Electronics), use modern, professional, high-performance, and consistent icons and visual assets that strictly align with the application's UI/UX design.

Because the application is built with **Flutter** for fast-paced workshop and POS environments, all icons and visual assets must adhere to strict performance, memory, and Arabic RTL architectural standards.

---

## 2. Standardized Single Icon Family (تثبيت عائلة الأيقونات الواحدة)

> [!IMPORTANT]
> **Strict Anti-Fragmentation Rule:** Do NOT mix different icon families with mismatched stroke weights and corner radii. The application must use **one primary icon family for at least 95% of all UI elements**.

### Primary Standard: Flutter Material 3 Rounded (`Icons.<name>_rounded`)
- **المعيار الحصري المعتمد:** حزمة `Icons.<name>_rounded` المدمجة أصلاً بنواة Flutter بنسبة 100%.
- **السبب الفني:** أعلى سرعة عرض معتمدة على الـ GPU Font Glyph Cache، حجم حزمة خفيف جداً، صفر بطء، وعدم الاعتماد على مكاتب خارجية.
- **Corner Style:** Rounded دائري وناعم متناسق مع هوية الورشة.

---

## 3. Strict Ban on SVG for Repeated/List Icons (قواعد حظر الـ SVG للأيقونات المتكررة)

> [!CAUTION]
> **Performance Rule:** Do NOT use `.svg` files for repeated list icons, table rows, standard buttons, or action chips.

### Technical Rationale (Flutter Runtime Performance):
- Rendering `.svg` files via `flutter_svg` requires parsing XML data, computing Bézier curves, and rasterizing vectors on the CPU at runtime.
- Using SVG icons across long scrolling lists of repair records, devices, or inventory parts causes **frame drops (Jank)** and wastes CPU/RAM cycles.
- In contrast, **`Icon(IconData)`** renders glyphs directly through the GPU cache (Font Glyph Cache) at a constant 60/120 FPS with virtually zero memory overhead.

### Clear Permitted Asset Usage:
| Asset Type | Permitted Format | Usage Context |
| :--- | :--- | :--- |
| **Repeated UI Icons** (Buttons, Lists, Inputs, Badges) | **`Icon(IconData)`** (Font Glyph) | 100% of interactive & list icons across the app |
| **Brand & Workshop Logos** | **`.svg`** (Vector) | App logo (`sabr_logo_gate.svg`), print headers, splash screen |
| **Multi-Colored Illustrations** | **`.svg`** or compressed **`.webp`** | Empty-state graphics, success screens, onboarding |
| **Third-Party Brand Badges** | **`.svg`** or compressed **`.png`** | Payment providers (Kuraimi, Jawali, Bank transfers), device OEM logos |

---

## 4. Arabic RTL & Directional Mirroring Rules (قواعد الاتجاه والانعكاس)

The application is built primarily for **Arabic (Right-to-Left - RTL)**. Icons must follow strict directional categorization:

### Category A: Navigational & Sequential Icons (MUST Mirror in RTL)
These icons convey flow, sequence, or time progression that reverses when reading right-to-left:
- **Icons to mirror:** Back arrows, Forward arrows, Next/Previous chevrons, Multi-step wizard pointers, Undo/Redo, Send message icons.
- **Implementation:** Always use `matchTextDirection: true` or directional constructors:
  ```dart
  Icon(
    Icons.arrow_back_rounded,
    matchTextDirection: true, // Automatically flips in Arabic RTL
  )
  ```

### Category B: Physical Tools & Real-World Devices (STRICTLY NEVER Mirror)
Physical objects, workshop tools, and electronics do not change their physical reality when spoken in Arabic:
- **Icons that MUST NEVER mirror:**
  - Screwdrivers (`wrench`, `screwdriver`, `handyman`)
  - Microchips and circuit boards (`memory`, `cpu`)
  - Batteries and charging ports (`battery_charging_full`, `power`)
  - Cameras and barcode scanners (`qr_code_scanner`, `photo_camera`)
  - Search magnifying glass (`search`)
  - Clocks and timers (`schedule`, `timer`)
  - Trash cans and edit pencils (`delete`, `edit`)
- **Implementation:** Always leave `matchTextDirection: false` (the default).

---

## 5. Master Icon Sizing System (نظام القياسات الموحد)

To avoid arbitrary sizing, every icon must use one of the standard design tokens:

| Token | Size | Target Elements |
| :--- | :---: | :--- |
| **`IconSize.xs`** | `14px - 16px` | Inline badges, small status chips, table metadata tags |
| **`IconSize.sm`** | `18px - 20px` | Form field prefix/suffix icons, compact dropdown menus |
| **`IconSize.md`** | `24px` | Standard AppBar actions, Bottom Navigation bars, primary buttons |
| **`IconSize.lg`** | `32px` | Quick Action counter tiles, intake wizard step indicators |
| **`IconSize.xl`** | `48px - 64px` | Empty states, diagnostic inspection headers, file dropzones |

---

## 6. Application-Specific Domain Icons Mapping

For electronic workshop workflows, use these consistent mappings:

| Workshop Concept | Semantic Meaning | Recommended Glyph |
| :--- | :--- | :--- |
| **Workshop Intake** | Check-in new device | `Icons.add_task_rounded` / `PhosphorIcons.trayArrowDown` |
| **Hardware & Devices** | Electronic devices | `Icons.devices_other_rounded` / `PhosphorIcons.devices` |
| **Physical Condition** | Scratches, cracks | `Icons.broken_image_rounded` / `PhosphorIcons.shieldWarning` |
| **Diagnostic Notes** | Technical inspection | `Icons.biotech_rounded` / `PhosphorIcons.stethoscope` |
| **Internal Hardware** | Motherboards, ICs | `Icons.memory_rounded` / `PhosphorIcons.cpu` |
| **Spare Parts Inventory** | Stockroom parts | `Icons.inventory_2_rounded` / `PhosphorIcons.package` |
| **Labor & Services** | Hands-on repair work | `Icons.handyman_rounded` / `PhosphorIcons.wrench` |
| **Thermal Printing** | ESC/POS Receipts | `Icons.print_rounded` / `PhosphorIcons.printer` |
| **Barcode / QR** | Fast ticket scanner | `Icons.qr_code_scanner_rounded` / `PhosphorIcons.qrCode` |
| **Payments & Cash** | Cashier & installments | `Icons.payments_rounded` / `PhosphorIcons.wallet` |
| **Security & PIN Lock** | Technician switch | `Icons.lock_person_rounded` / `PhosphorIcons.lockKey` |
| **WhatsApp Notice** | Customer notifications | `Icons.chat_bubble_rounded` / `PhosphorIcons.chatTeardropDots` |

---

## 7. Asset Directory Structure

All static visual assets must be structured in the project repository as follows:

```text
assets/
├── icons/               # Only custom monochrome icons if strictly missing from fonts
├── images/              # Logos, banners, illustrations
│   ├── app_logo.jpg     # High-res master raster logo
│   ├── sabr_logo_gate.svg # Precision vector XOR gate + SE monogram logo
│   ├── splash_banner.jpg # Workshop splash screen banner
│   └── empty_state.jpg  # All-clear empty state illustration
└── fonts/               # Offline typography (e.g. Cairo or Readex Pro for Arabic)
```

---

## 8. Quality Assurance & Checklist

Before completing any UI screen or feature:
- [ ] Are all list and table icons using `Icon(IconData)` and NOT `.svg` files?
- [ ] Do directional icons mirror properly in Arabic (`matchTextDirection: true`)?
- [ ] Do physical tool icons (screwdrivers, batteries) stay unflipped in Arabic?
- [ ] Do all icons adhere to the 16px / 20px / 24px / 32px sizing scale?
- [ ] Are icons clearly legible in both Light Mode (`#0F172A`) and Dark Mode (`#F8FAFC`) with appropriate contrast?
- [ ] Does every interactive icon have a touch target of at least 44×44px?
