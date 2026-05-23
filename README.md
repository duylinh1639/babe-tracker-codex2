# BabyHealthTracker iOS

Native SwiftUI prototype based on the PRD files in `../.prd`.

## Open in Xcode

1. Open `BabyHealthTracker.xcodeproj`.
2. Select the `BabyHealthTracker` scheme.
3. Choose an iPhone simulator running iOS 16 or newer.
4. Press Run.

The app seeds a demo baby profile, recent logs, growth measurements, a Vietnam EPI vaccine schedule, medication data, symptoms, and a doctor visit. Data is stored locally with `UserDefaults` so the app runs without any backend setup.

## Implemented MVP Surface

- Five native SwiftUI tabs: Home, Sleep, Growth, Vaccines, Profile
- Quick logs for sleep, diapers, medication, and symptoms
- Sleep timer with live count-up and manual sleep entries
- Last 7 days sleep chart with WHO recommendation band
- Growth history and lightweight chart preview
- Vietnam EPI vaccine schedule with due/overdue/completed states
- Double-dose medication warning before saving a duplicate dose
- Doctor visit log and shareable health summary text
- English and Vietnamese localization resource files for core labels
- iOS 16 deployment target, iPhone-first layout, dark mode-aware colors

## Next Production Steps

- Replace local `UserDefaults` storage with Firebase Firestore or Supabase sync.
- Add push notification scheduling for medication, vaccine, diaper, and daily summary reminders.
- Replace demo percentile calculations with official WHO LMS data.
- Generate real PDF reports instead of the current shareable text summary.
- Add real app icon image assets before App Store/TestFlight distribution.
