# iOS release secrets & variables — setup guide

How to populate the GitHub secrets and variables the TestFlight workflows need
(`.github/workflows/release_ios_internal.yml`, `.github/workflows/release_ios_external.yml`).

> This file describes **how to obtain the values** — never paste actual secret
> contents into it.

## What you're setting up

**3 Variables** (Settings → Secrets and variables → Actions → **Variables** tab):

| Name | Example |
|---|---|
| `IOS_APP_STORE_CONNECT_KEY_ID` | `ABC123XYZ9` |
| `IOS_APP_STORE_CONNECT_ISSUER_ID` | `69a6de70-1234-…` (UUID) |
| `IOS_TESTFLIGHT_EXTERNAL_GROUPS` | `Beta Testers,Power Users` (only for the external lane) |

**5 Secrets** (same page, **Secrets** tab):

| Name | What |
|---|---|
| `IOS_CERT_P12_BASE64` | Apple Distribution cert + private key, exported as .p12, base64-encoded |
| `IOS_CERT_PASSWORD` | Password used during .p12 export |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile for `app.zamaj`, base64-encoded |
| `IOS_APP_STORE_CONNECT_KEY_CONTENT` | `.p8` private key for the App Store Connect API key, base64-encoded |
| `IOS_KEYCHAIN_PASSWORD` | Random password for the ephemeral CI keychain |

Bundle id (`app.zamaj`) and Team ID (`9DV3BTZ69W`) are already wired into
`mobile/ios/fastlane/Appfile` — no env config needed for those.

## Recommended order

1. Apple Developer Program + register App ID + create app in App Store Connect.
2. Distribution certificate → produces `.p12` → sets 2 secrets.
3. Provisioning profile → sets 1 secret.
4. App Store Connect API key → sets 2 variables + 1 secret.
5. Random keychain password → sets 1 secret.
6. (Only when ready for external testing) Create TestFlight external group → sets 1 variable.

---

## 0. Prerequisites

- [Apple Developer Program](https://developer.apple.com/programs/) membership ($99/year).
- App ID `app.zamaj` registered at
  [developer.apple.com → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
  (Identifier = `app.zamaj`, Team = the one with ID `9DV3BTZ69W`).
- App created in [App Store Connect](https://appstoreconnect.apple.com) →
  My Apps → **New App**, bundle id `app.zamaj`.

## 1. `IOS_CERT_P12_BASE64` + `IOS_CERT_PASSWORD`

The Apple Distribution certificate, exported with its private key.

### A. Create a CSR
On your Mac: **Keychain Access → Certificate Assistant → Request a Certificate
From a Certificate Authority**.
- Email: your Apple ID email.
- Common Name: anything.
- Request: **Saved to disk**. → produces a `.certSigningRequest` file.

### B. Create the cert in Apple Developer
1. [developer.apple.com → Certificates → +](https://developer.apple.com/account/resources/certificates/list).
2. Choose **Apple Distribution** → Continue.
3. Upload the CSR → Continue → Download the `.cer`.
4. Double-click the `.cer` to install it into your login Keychain.

### C. Export to .p12
1. Open **Keychain Access** → login keychain → **My Certificates** category.
2. Find the new "Apple Distribution: <Your Team>" entry — expand it ▶ and
   confirm a private key is attached underneath.
3. Right-click the certificate (the top row, not the key) → **Export "Apple
   Distribution…"** → File Format `.p12` → Save as `zamaj-dist.p12`.
4. When prompted, set an export password — pick a strong random one:

   ```bash
   openssl rand -base64 24
   ```

   → that string is **`IOS_CERT_PASSWORD`**.

### D. Base64 + paste

```bash
base64 -i zamaj-dist.p12 | tr -d '\n' | pbcopy
```

Paste into **`IOS_CERT_P12_BASE64`** (Secrets tab).

> Keep `zamaj-dist.p12` and its password somewhere safe (password manager).
> If lost, you can regenerate the cert but old TestFlight builds remain signed
> by the old one until they expire.

## 2. `IOS_PROVISIONING_PROFILE_BASE64`

App Store provisioning profile for `app.zamaj`, bound to the cert from step 1.

1. [developer.apple.com → Profiles → +](https://developer.apple.com/account/resources/profiles/list).
2. Distribution → **App Store** → Continue.
3. App ID: `app.zamaj` → Continue.
4. Certificate: pick the **Apple Distribution** cert from step 1 → Continue.
5. Provisioning Profile Name: e.g. `Zamaj App Store`. The fastlane lane reads
   this name from the profile bytes at runtime, so you don't need to set it
   as a separate variable.
6. Generate → **Download** the `.mobileprovision` file.

```bash
base64 -i Zamaj_App_Store.mobileprovision | tr -d '\n' | pbcopy
```

Paste into **`IOS_PROVISIONING_PROFILE_BASE64`** (Secrets tab).

> If you ever revoke / regenerate the distribution cert, regenerate this
> profile too and update the secret.

## 3. `IOS_APP_STORE_CONNECT_KEY_ID` + `IOS_APP_STORE_CONNECT_ISSUER_ID` + `IOS_APP_STORE_CONNECT_KEY_CONTENT`

App Store Connect API key — fastlane uses this to upload to TestFlight without
an Apple ID password.

1. [App Store Connect → Users and Access → Integrations tab](https://appstoreconnect.apple.com/access/integrations/api).
2. Click **+** to generate a key.
3. Name: `ci-testflight`. **Access**: **App Manager** is the safe default
   (Developer also works but can hit edge-case permission errors).
4. Generate. The row now shows:
   - **Key ID** (10 chars, e.g. `ABC123XYZ9`)
     → set as **`IOS_APP_STORE_CONNECT_KEY_ID`** in the **Variables** tab.
   - At the top of the page: **Issuer ID** (UUID like `69a6de70-…`)
     → set as **`IOS_APP_STORE_CONNECT_ISSUER_ID`** in the **Variables** tab.
5. Click **Download API Key** → `AuthKey_ABC123XYZ9.p8`.
   **You can only download this once.** Save a copy to your password manager.

```bash
base64 -i AuthKey_ABC123XYZ9.p8 | tr -d '\n' | pbcopy
```

Paste into **`IOS_APP_STORE_CONNECT_KEY_CONTENT`** (Secrets tab).

## 4. `IOS_KEYCHAIN_PASSWORD`

A random password used to create the throwaway keychain the CI job uses to
import the .p12. Never reused; deleted at job end.

```bash
openssl rand -base64 32 | pbcopy
```

Paste into **`IOS_KEYCHAIN_PASSWORD`** (Secrets tab).

## 5. `IOS_TESTFLIGHT_EXTERNAL_GROUPS` (only needed for the external lane)

The names of the TestFlight external tester groups each external build should
be distributed to.

1. [App Store Connect](https://appstoreconnect.apple.com) → your app →
   **TestFlight** tab → **External Testing** in the sidebar.
2. If no groups exist yet, click **+** under External Testing → create one
   (e.g. `Beta Testers`). Add testers by email.
3. Set the variable to comma-separated group names (no quotes, no leading
   spaces):

   ```text
   Beta Testers,Power Users
   ```

   Single group is fine: `Beta Testers`.

Set as **`IOS_TESTFLIGHT_EXTERNAL_GROUPS`** in the **Variables** tab.

> The first external build will trigger Apple's beta review (usually < 24h).
> Release notes are required for external (the workflow enforces this).

---

## Verifying

After all secrets/variables are in place:

1. Actions tab → **Release • TestFlight • Internal Testing** → **Run workflow**.
2. Leave runner on its default; leave release notes empty (internal doesn't
   require them).
3. The job should checkout, build, sign, upload, and the build should appear
   in App Store Connect → TestFlight → Builds within ~5–15 minutes (processing
   time on Apple's side).
4. Once internal works end-to-end, do the same for **External Testing** with
   release notes filled in.

## Common pitfalls

- **".p12 won't import"** → almost always a base64 encoding issue. Make sure
  you used `tr -d '\n'` to strip newlines before pasting.
- **"No matching provisioning profile"** → the cert in the .p12 and the cert
  the profile was generated against must match. If you re-created the cert,
  regenerate and re-upload the profile.
- **"Authentication failed" from App Store Connect** → key was revoked,
  Issuer ID is wrong, or the .p8 content was truncated. Verify each value.
- **Build number conflict** → if you somehow trigger two builds within the
  same minute they'll get identical build numbers (epoch minutes). Just
  re-run.
