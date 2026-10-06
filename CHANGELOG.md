# Changelog

## v1.1.0 - 2026-10-06

**Added**

- "Turn off today at": pick a time and it switches itself off then. It's just for today and wins over the weekly schedule, so it works for leaving early or staying late.
- Weekly schedule: set your hours for each day and it turns on and off by itself. Turning it on or off by hand holds until the next start or end time.
- Option to start the app with Windows, so the schedule keeps working after a restart.
- Dark mode, with a moon/sun switch in the top corner. It follows your Windows setting until you pick one, then remembers it.

**Changed**

- The status line now says what happens next, like "On - until 16:00" or "Off - turns on tomorrow 08:00".
- Cleaner checkboxes and time pickers that match the rest of the window.
- Settings are now saved in `%APPDATA%\StayAvailable`.

## v1.0.0 - 2026-10-06

First full release. The beta was tried for real and works, so the "not tested" note is gone. No changes to the app itself.

## v0.1.0 beta - 2026-10-06

First version.

- One window with a Turn on / Turn off button.
- While on, presses F15 once a minute so Teams stays green, and keeps the computer from sleeping or locking (including Win+L).
- Turning it off or closing the window puts everything back to normal.
