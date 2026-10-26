# NaanStock Manager

Offline-first single-branch Android app for flour/maida stock and naan production. Existing Ai-Hub files remain unchanged.

Features: stock receipts, manual kitchen usage, recipe-based flour/maida deduction on production, sold/issued/wasted/leftover counts, daily reports, CSV export and JSON backup/restore. Data stays in this device's WebView local storage; there is no cloud sync.

Build: GitHub Actions → Build NaanStock Android APK → Run workflow. Download artifact `naanstock-debug-apk`, extract `app-debug.apk`. Debug APK is for testing, not Play Store release signing. Verify recipe quantities with your kitchen before operational use.
