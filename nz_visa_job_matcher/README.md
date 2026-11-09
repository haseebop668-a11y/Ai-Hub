# NZ Visa Job Matcher

Android-first, local-first job screening and application preparation for Pakistani candidates exploring New Zealand employment and the Accredited Employer Work Visa (AEWV) pathway.

## Implemented in the first mobile build

- Warm professional interface using navy, amber and cream.
- Manual import of vacancies from recruitment portals and recruiter messages.
- Local screening for explicit New Zealand work-right restrictions and sponsorship signals.
- A transparent keyword-overlap indicator based only on skills the candidate enters.
- Employer accreditation and job-check evidence notes, stored separately.
- Candidate profile stored using Android secure storage.
- Optional profile photo saved in app-private storage.
- Job-category-aware CV headings and relevant-skill selection.
- Two-page PDF output: CV and job-specific cover letter.
- Application pipeline: saved, prepared, applied, shortlisted and closed.
- Direct links to official recruitment pages and Immigration New Zealand's employer search.
- Flutter unit tests and GitHub Actions APK build.

## Honest scope

The first build does not scrape websites, log in to recruitment accounts, submit applications, solve CAPTCHAs, intercept OTPs or run background monitoring. Some portals explicitly restrict automated access. Use each employer's own application process and press its final submit button yourself. Future integrations should only be enabled for documented feeds/APIs or written permission.

The app has no external AI API dependency. Job screening and CV keyword alignment run locally. The overlap percentage is not an ATS score, hiring prediction or guarantee. It is a simple explanation of how many of the candidate's own entered skills appear in the imported description.

## Build and download

The GitHub Actions workflow at .github/workflows/build-nz-visa-job-matcher-android.yml creates an Android host project, resolves Flutter dependencies, runs analysis and tests, builds a debug APK, verifies the APK archive and uploads it as a workflow artifact.

1. Open the repository's Actions tab.
2. Select Build NZ Visa Job Matcher Android APK.
3. Open the latest successful workflow run.
4. Download the nz-visa-job-matcher-debug-apk artifact ZIP and extract the APK.
5. On Android, allow installation for the browser/file manager you used, then install the APK.

This is a debug/test build, not a Play Store-signed release. Artifacts are retained for 14 days.

## Privacy

- No personal name, email, telephone, CV or photo is hardcoded in this repository.
- Profile fields are entered on the device and stored with flutter_secure_storage.
- The selected profile photo is copied to app-private storage.
- Imported job data is stored locally with shared_preferences.
- No CV or profile information is sent to an AI provider or backend.
- The source repository is public; do not add private documents, passwords or live credentials to it.

See docs/RESEARCH_AND_LIMITATIONS.md.
