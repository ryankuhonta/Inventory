# Private APK Test Notes - 2026-07-26

**APK under test:** `tindatrack-0.1.0+1-debug.apk`
**Artifact path:** `_bmad-output/implementation-artifacts/apk/tindatrack-0.1.0+1-debug.apk`
**Build type:** Debug APK for personal smoke testing, not the final signed release candidate.

## Observations

### 1. App exit/back has no confirmation

**Screen/area:** App-level navigation / Android back behavior

**What happened:** When exiting or pressing back from the app, there is no confirmation asking whether the user wants to exit.

**Expected:** Show a confirmation prompt before closing the app, so accidental exits are prevented.

**Steps to reproduce:**
1. Open the app.
2. Navigate to a main tab or stay on the initial screen.
3. Press the Android back button or use the exit/back behavior.

**Severity:** Important UX polish

**Suggested change:** Add an app-exit confirmation dialog on root-level back navigation.


### 2. Barcode field appears on Edit Product but not Add Product

**Screen/area:** Products / Add Product and Edit Product

**What happened:** The Add Product screen does not show a barcode field, but the Edit Product screen does.

**Expected:** Barcode handling should be consistent. If barcode is supported as manual entry, the Add Product screen should allow entering it during product creation too.

**Steps to reproduce:**
1. Open Products.
2. Tap Add Product.
3. Check the fields shown on the Add Product form.
4. Save or open an existing product via Edit Product.
5. Compare fields shown on the Edit Product form.

**Severity:** Important product-flow fix

**Suggested change:** Add the barcode field to Add Product, reusing the same validation and duplicate-barcode behavior already available in Edit Product.

### 3. Reuse previous same-field values as autocomplete suggestions

**Screen/area:** Repeated text-entry fields across the app, starting with Stock In / Stock Out notes

**What happened:** Repeated entries such as stock movement notes require typing the same words again, even when the value was already used before.

**Expected:** When typing into a field, the app should suggest previous values used for that same field type. For example, if a prior Stock Out note was consumed, typing co in a Stock Out note field should suggest consumed.

**Scope rule:** Suggestions should come from the same field context only. A note field should suggest prior notes, a barcode field should suggest prior barcodes only if that makes sense, and product-name/category-like fields should not mix values with unrelated fields.

**Steps to reproduce:**
1. Create a stock movement with a note such as consumed.
2. Create another stock movement of the same note context.
3. Type the beginning of the prior value, such as co.
4. Observe that no previous-value suggestion appears.

**Severity:** Nice-to-have productivity improvement

**Suggested change:** Add local-only autocomplete backed by distinct recent or frequent values per field context, with tap-to-fill suggestions and no cloud dependency.

### 4. App still uses a generic icon

**Screen/area:** Android app launcher / installed app identity

**What happened:** The installed app appears to use a generic/default app icon.

**Expected:** The app should have a custom icon that fits the inventory/store-helper purpose and makes the APK feel identifiable during testing.

**Steps to reproduce:**
1. Install the APK on an Android device.
2. Look for the app in the launcher or recent apps.
3. Observe the app icon.

**Severity:** Important release polish

**Suggested change:** Create and configure a custom TindaTrack app icon for Android launcher assets before wider private testing or Play Store internal testing.

### 5. Back from History exits instead of returning to Dashboard

**Screen/area:** History tab / Android back navigation

**What happened:** After navigating to View History, pressing the Android back button exits the app.

**Expected:** Pressing back from History should return to the previous screen or tab, such as Dashboard, instead of immediately exiting the app.

**Steps to reproduce:**
1. Open the app on Dashboard.
2. Go to View History / History tab.
3. Press the Android back button.
4. Observe that the app exits instead of returning to Dashboard.

**Severity:** Important navigation fix

**Suggested change:** Adjust root/tab back handling so secondary tabs return to the previous selected tab or Dashboard before app exit confirmation is shown.

### 6. Settings screen behaves more like app info than editable settings

**Screen/area:** Settings tab

**What happened:** The Settings screen shows currency, backup/export, app version, and local data information, but there are no actual user-editable settings to update.

**Expected:** The screen name and contents should match user expectations. If nothing can be configured yet, it may be clearer as About, App Info, or a combined Settings/About screen with explicit read-only status messaging.

**Steps to reproduce:**
1. Open Settings.
2. Review the available sections: currency, backup/export, app version, and local data.
3. Notice that the items are informational rather than configurable.

**Severity:** UX/content architecture polish

**Suggested change:** Decide whether to rename the tab/screen to About or App Info for MVP, or add at least one real configurable setting if it should remain Settings. Keep backup/export clearly marked as future/not available until implemented.

### 7. App version displays raw Flutter plus-build format

**Screen/area:** Settings / App version

**What happened:** The app version is shown with a plus sign, such as `0.1.0+1`.

**Expected:** The version should be shown in a clearer user-facing format, such as `Version 0.1.0 (Build 1)`.

**Steps to reproduce:**
1. Open Settings.
2. Look at the App Version section.
3. Observe the raw version/build format.

**Severity:** Nice-to-have display polish

**Suggested change:** Parse the Flutter version string into version name and build number before displaying it in the UI.
