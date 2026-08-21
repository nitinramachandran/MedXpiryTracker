# Quickstart: Manually Validate Medicine Expiry Tracker

Build and run on an iPhone or simulator (portrait, light mode).

## 1. Add manually
1. Type a name in **Medicine name**.
2. Tap **Set manually** on Manufacturing date → pick a date → **Okay**.
3. Tap **Set manually** on Expiry date → pick a later date → **Okay**.
4. Choose a **Remind before expiry** value → tap **Save medicine**.
   - ✅ The medicine appears under **Saved medicines** with its dates, reminder time, and lead.

## 2. Validation
1. Set an expiry date earlier than the manufacturing date and Save.
   - ✅ Save is blocked; "Expiry date must be after the manufacturing date." shows.

## 3. Scan (device only)
1. Tap **Scan medicine name**, aim at a label, tap the best text, confirm.
   - ✅ Name field fills (capitalized).
2. Tap **Scan** on a date row, aim at a printed date (e.g. `DEC-2026` or `05/2026`), tap it.
   - ✅ The field shows the parsed date. Unreadable text shows the "edit it manually" message.

## 4. Reminder
1. Save a medicine whose reminder time is essentially now (near-future fallback fires within a minute).
   - ✅ A notification arrives with **Snooze** and **Cancel** actions.
2. Tap the notification body.
   - ✅ The app opens a details popup with **Delete** / **Cancel**.

## 5. Edit & delete
1. Swipe a saved row → **Edit** → change the lead → **Save**. ✅ Row updates; reminder reschedules.
2. Swipe a saved row → **Delete**. ✅ Row and its pending reminder are removed.

## 6. Backup round-trip
1. **Export medicines** → save/AirDrop the JSON file.
2. Delete all medicines, then **Import from backup** → pick the file → confirm replace.
   - ✅ The medicines return and reminders are rescheduled.
3. (Compatibility) Import a pre-v1.2 backup. ✅ Imports fine; missing leads default to 1 day.

## 7. Automated checks
Run the `Medicine Date Alerter.xctestplan` (unit + UI). ✅ All green.
