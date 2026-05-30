# PRD Addendum: Technical And Downstream Notes

This addendum captures useful implementation and architecture context that should inform UX, architecture, epics, and stories without bloating the PRD itself.

## Preferred Technical Direction

- Mobile stack: Flutter.
- State management: Riverpod.
- Local database: SQLite, preferably via Drift for type-safe queries, migrations, and transactions.
- Architecture: Clean Architecture with presentation, domain, and data layers.
- MVP platform: Android first.
- Future platform optionality: iOS can be supported later because Flutter is cross-platform.

## Architecture Considerations

- SQLite should be the local source of truth.
- Stock in and stock out must be implemented as atomic database transactions.
- Product IDs should use UUIDs to support future cloud sync.
- Inventory transactions should be append-only where possible.
- Product deletion should be avoided in MVP; archive products instead so history remains intact.
- Future sync can be added through repository implementations without changing UI flows.

## Future Sync Considerations

- Add `syncStatus`, `remoteId`, and `deletedAt` only when cloud sync is introduced.
- Use local-first writes, then background sync later.
- Conflict handling should prioritize transaction history integrity over simple last-write-wins for stock quantities.

## UX Notes For Downstream Design

- The app should feel lightweight, readable, and practical for non-technical users.
- Common actions should take very few taps.
- Avoid interruptions during stock in and stock out flows.
- Use low-stock warnings sparingly and clearly.
- Target low-end Android devices and small screens.

## Monetization Notes

- Ads should never interrupt product creation or stock movement.
- AdMob should start only on low-risk screens such as Dashboard, History, or Settings.
- Premium features can include backup/export, barcode scanning, advanced reports, and cloud sync.
