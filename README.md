# Damla • Günlük Takip

Minimal, mobile-first daily medicine and reward tracker.

## Features
- Add each medicine once; it appears every day.
- Mark a medicine as taken once per day (+10 points).
- Create and delete rewards from the hidden management screen (PIN: 3310).
- Redeem rewards using accumulated points.
- Optional reminder time for each medicine.
- Local browser storage; no account or server database required.
- Installable PWA shell for iPhone home screen.

## Publish with GitHub Pages
1. Open **Settings → Pages** in this repository.
2. Under **Build and deployment**, choose **GitHub Actions** as the source.
3. The workflow publishes the site after each push. Open the Pages URL on iPhone using Safari and choose **Share → Add to Home Screen**.

## Important notes
- Medicine entries and points are stored on the device/browser where the app is used. They are not synchronized between phones and can be lost if browser data is cleared.
- The reminder timer in this starter version runs while the app is open. Reliable reminders while the app is closed require a web-push server and a subscription flow; a service worker alone cannot schedule daily notifications.
- The 3310 screen is a convenience gate, not strong security: the PIN is in client-side code. Do not store sensitive information in this app.
- The app does not recommend doses or change prescribed schedules. Add only the medicine and schedule provided by the prescribing clinician.
