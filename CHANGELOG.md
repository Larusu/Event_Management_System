# Changelog

All notable changes to the Campus Event App are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.1.0] - 2026-07-22

### Added
- Auto-refresh for the Dashboard, Events, and Calendar screens on tab focus and app resume.
- Rejection reason now shown on rejected events in the Created Events cards.

### Fixed
- Pull-to-refresh added to the Dashboard.
- Replaced the untappable "Edit notifications" card in Settings with a "More settings coming soon" line.
- Prevented overflow in the dashboard registered-events list.
- Contact emails are validated, and long names in the header account pill are truncated.
- Header account pill right-aligned so the name hugs the right edge.
- Reset the owned-events cache on user change, fixing the "Event Owner" state bleeding across sessions.
- Bleachers map corrected to show the Bleachers + Cinema Lab rooms only.
- `GET /events/next-registered` now skips already-ended events using campus-local time (UTC+8).

### Changed
- Cleaned `flutter analyze` and `dart analyze` output to zero issues.

## [v1.0.0] - 2026-07-21

- Initial release: authentication and roles, event browsing/search/filtering, event creation with Cloudinary cover images and an approval workflow, registration, dashboard, calendar, indoor wayfinding maps, and the admin management area.

[v1.1.0]: https://github.com/Larusu/campus_event_app/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/Larusu/campus_event_app/releases/tag/v1.0.0
