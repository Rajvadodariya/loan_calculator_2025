# LoanPro+ Pro Subscription Setup Guide

## Prerequisites

> **You need an Apple Developer Account ($99/year)** to create subscription products in App Store Connect and submit to the App Store. Without it, you can only test locally using a StoreKit configuration file in Xcode.

---

## 1. App Store Connect — Create Subscription Products

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app → **Monetization** → **Subscriptions**
3. Create a **Subscription Group** named `LoanPro Pro`
4. Add **two** auto-renewable subscription products:

   | Product ID | Duration | Suggested Price |
   |---|---|---|
   | `loanpro_monthly` | 1 Month | $2.99 |
   | `loanpro_yearly` | 1 Year | $19.99 |

5. For each product, fill in:
   - **Display Name** — e.g., "LoanPro+ Monthly"
   - **Description** — e.g., "Ad-free calculations, unlimited saves, free exports"
   - **Price** — set in all territories you support
   - **Status** — set to "Ready to Submit"

> ⚠️ Product IDs must **exactly match** the values in `StoreKitManager.swift`:
> - `loanpro_monthly`
> - `loanpro_yearly`

---

## 2. Xcode — Add In-App Purchase Capability

1. Open Xcode → select your **project target**
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Search and add **In-App Purchase**

Without this capability, StoreKit will not work at all.

---

## 3. StoreKit Testing in Xcode (Local — No Developer Account Needed)

This lets you test purchases on the **Simulator** without a real Apple ID or App Store Connect products.

### Create a StoreKit Configuration File

1. In Xcode: **File → New → File**
2. Search for **StoreKit Configuration File**
3. Name it `LoanProProducts.storekit`
4. Uncheck "Sync this file with an app in App Store Connect" (unless you already have products set up)
5. Click **Create**

### Add Products to the Configuration

1. Open `LoanProProducts.storekit`
2. Click the **+** button → **Add Auto-Renewable Subscription**
3. Create a subscription group: `LoanPro Pro`
4. Add first product:
   - **Reference Name**: LoanPro+ Monthly
   - **Product ID**: `loanpro_monthly`
   - **Price**: $2.99
   - **Subscription Duration**: 1 Month
5. Add second product:
   - **Reference Name**: LoanPro+ Yearly
   - **Product ID**: `loanpro_yearly`
   - **Price**: $19.99
   - **Subscription Duration**: 1 Year

### Enable in Your Scheme

1. **Product → Scheme → Edit Scheme** (or `Cmd + <`)
2. Select **Run** → **Options** tab
3. Under **StoreKit Configuration**, select `LoanProProducts.storekit`
4. Build and run — products will now load in the paywall!

### Testing Tips

- Purchases complete instantly in StoreKit testing (no real charges)
- Subscriptions renew quickly for testing (configurable in the `.storekit` file)
- Use **Debug → StoreKit → Manage Transactions** to view/refund test purchases
- You can test expiration, renewal failure, and grace periods

---

## 4. Sandbox Testing (On Real Device)

For testing on a **physical device** before going live (requires Developer Account):

### Create Sandbox Tester

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **Users and Access** → **Sandbox** → **Testers**
3. Click **+** to create a new Sandbox Apple ID
   - Use a **test email** (doesn't need to be a real inbox)
   - Set a password you'll remember
   - Select any territory

### Sign In on Device

1. On your iPhone/iPad: **Settings → App Store**
2. Scroll down to **Sandbox Account**
3. Sign in with the sandbox Apple ID you just created
4. **Do NOT sign in with the sandbox account as your main Apple ID**

### Test

1. Build & run from Xcode onto your device
2. Navigate to the LoanPro+ paywall
3. Tap Subscribe — it will use the sandbox environment
4. **No real charges** will occur

### Sandbox Subscription Durations

In sandbox, subscriptions auto-renew at an accelerated rate:

| Real Duration | Sandbox Duration |
|---|---|
| 1 Month | 5 minutes |
| 1 Year | 1 hour |
| Auto-renewal | Renews up to 6 times, then stops |

---

## 5. Supabase Setup

### Ensure `is_pro` Column Exists

If you ran the original SQL migration, the `profiles` table already has `is_pro`. Verify by checking the Table Editor in Supabase.

The `StoreKitManager` automatically syncs the `is_pro` status to Supabase when a subscription is purchased or changes.

### Verify RLS Policies

The existing RLS policies allow users to update their own profile (including `is_pro`):

```sql
-- These should already exist from the M2 migration
CREATE POLICY "Users can read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
```

---

## 6. What Pro Unlocks (Feature Summary)

| Feature | Free | Pro |
|---|---|---|
| All calculators | ✅ | ✅ |
| Ads (banner, interstitial, native) | Shown | **Hidden** |
| PDF/CSV export | Costs coins | **Free** |
| Full amortization schedule | Watch reward ad | **Always available** |
| Saved calculations | Max 5 | **Unlimited** |
| Calculation history | Max 10 | **Unlimited** |

---

## 7. Pre-Submission Checklist

Before submitting to the App Store, verify:

- [ ] Apple Developer Account is active ($99/year)
- [ ] In-App Purchase capability added in Xcode
- [ ] Subscription products created in App Store Connect
- [ ] Product IDs match code (`loanpro_monthly`, `loanpro_yearly`)
- [ ] Sandbox tester created and tested on device
- [ ] Restore Purchases button works correctly
- [ ] Terms of Service URL is valid (currently Apple's standard EULA)
- [ ] Privacy Policy URL is valid
- [ ] `is_pro` column exists in Supabase `profiles` table
- [ ] Subscription description is clear about auto-renewal
- [ ] App Review Information includes subscription details

---

## 8. Files Involved

| File | Role |
|---|---|
| `Services/StoreKitManager.swift` | StoreKit 2 subscription logic |
| `Views/Pro/ProUpgradeView.swift` | Paywall UI |
| `Services/AdService.swift` | Skips ads when `isPro` |
| `Services/CoinManager.swift` | Bypasses coin costs when `isPro` |
| `Views/Results/ResultsView.swift` | Free exports & schedule access for Pro |
| `Views/Main/SettingsView.swift` | LoanPro+ upgrade card |
| `Services/CalculationStorageService.swift` | Unlimited saves/history for Pro |

---

## Quick Start (Fastest Way to Test)

1. Create the `.storekit` configuration file (Step 3)
2. Add In-App Purchase capability (Step 2)
3. Set the StoreKit config in your Run scheme
4. Build & run on Simulator
5. Navigate to Settings → "Upgrade to LoanPro+" → Subscribe!
