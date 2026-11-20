# Persistent debug APK signing

The Android APK workflow uses a **fixed** debug signing certificate so test
installations of `org.btechmobile.game` can be updated by later APKs. The key
is NOT stored in the repository.

## One-time GitHub Actions setup

Open repository **Settings → Secrets and variables → Actions → New repository
secret** and create both:

| Repository secret | Value |
| --- | --- |
| `BTECH_DEBUG_KEYSTORE_BASE64` | Single-line Base64 encoding of the PKCS12 `BtechMobile-debug.keystore` |
| `BTECH_DEBUG_KEYSTORE_PASSWORD` | Password used to protect that keystore |

Use the **private debug signing kit** delivered separately to the maintainer.
It includes `BTECH_DEBUG_KEYSTORE_BASE64.txt`, `BTECH_DEBUG_KEYSTORE_PASSWORD.txt`,
and a backup of the keystore. Paste the corresponding file contents into GitHub
Secrets. Keep the signing kit privately backed up in a secure location; **never
commit the private key, its Base64, or password to this repository or an issue**.

Key alias: `btechmobile-debug`. The key password and keystore password
are identical for this PKCS12 key.

Pinned certificate SHA-256 (public fingerprint):

```
58:84:80:19:48:84:9F:07:5B:DD:01:7E:3B:DF:BC:23:C8:94:84:2F:47:E3:FB:4C:30:2B:C8:D0:62:10:83:5F
```

The workflow checks the stored key's alias and verifies that the **exported
APK** is signed by this *exact* pinned certificate. If secrets are absent,
damaged, or replaced with another key, the build fails instead of silently
generating an APK that cannot update previous installs.

## Build and install

1. Go to **Actions → Android APK → Run workflow** on `main`.
2. After success, download the `BtechMobile-debug-apk` artifact and extract
   `BtechMobile-debug.apk`.
3. The **first** fixed-key APK cannot update a version signed with the old,
   randomly regenerated CI key. Back up any important local data and uninstall
   that old version **once** before installing the fixed-key APK.
4. Later APKs using this same keystore can update fixed-key installations,
   assuming the package ID stays the same and the Android version-code rules
   are satisfied.

The signing kit and this workflow are for internal **debug APKs only**. A
separate secure release/app-signing strategy is needed before a Play Store
release. If this private key is lost, it cannot be recreated, and users will
need to uninstall before installing APKs signed with a different identity.
