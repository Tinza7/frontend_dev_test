# Solutions

## Bug fixes

### RES-101 — Search shows results for the wrong query

**Root cause:** Every character typed immediately triggers a separate search request without waiting for earlier ones. For example, typing "sushi" sends separate searches for "s", "su", "sus", "sush" and "sushi". A request sent earlier but answered later can overwrite the results of the latest query.

**Fix:** The controller assigns a generation number to every search, and only accepts results from the latest generation. If results from an earlier query arrive late, they are discarded immediately.

**Why this fix:** Search stays as responsive as before while the screen never shows wrong results. Debouncing only reduces the number of requests; it cannot fix responses arriving out of order.

**Edge cases:** Clearing the text or closing the search screen while a request is in flight invalidates that request immediately. If a search fails, the error is logged but the existing results on screen are not cleared.

### RES-102 — Crash after leaving My orders

**Root cause:** The pickup countdown timer (`PickupCountdown`) on the My orders screen fires every second. After the user leaves the screen, the timer keeps running in the background. When it tries to update the UI of a screen that has already been closed, the app crashes.

**Fix:** The timer is tied to the screen's lifecycle. As soon as the user leaves My orders, the timer is cancelled, and before updating the UI we check that the screen is still mounted.

**Why this fix:** Cancelling the timer on dispose fixes the crash at its source. It also saves battery and resources, since the app no longer does pointless background work.

**Edge cases:** Whether the user goes back, leaves the screen, or the order is removed, the timer is cancelled correctly. While the screen is open, the countdown and its update frequency behave exactly as before.

### RES-103 — Requests pile up after browsing deal pages

**Root cause:** Opening a deal details page registers a listener on the bag, but the listener is not removed when the page is closed. The more deals are opened, the more listeners accumulate, so each bag change fires duplicate fetches, one per deal opened earlier.

**Fix:** Keep a reference to the listener and dispose it when leaving the deal details page.

**Why this fix:** It fixes the leak at its source, so the listener only runs while its page is open.

**Edge cases:** While the page is open it works as normal. After it is closed, no new requests are fired. (A request already in flight before closing cannot be cancelled, but it will not be repeated.)

### RES-104 — Duplicate deals in the home feed

**Root cause:** Loading the next page modifies `_page` before knowing whether the request succeeded. If a refresh happens in the meantime, it resets the feed to the first page but does not invalidate the older in-flight request. When the old load-more request finishes later, it appends data from before the refresh to the feed, and the cursor may no longer match the list.

**Fix:** Add a generation counter for feed requests. A refresh increments the generation so that stale load-more results are discarded, and no load-more can start while a refresh is running. The cursor only advances to a page that was returned successfully. The load-more state is cleared in `finally`, even if the response is stale or the request fails.

**Why this fix:** The backend has no API to cancel requests, so stale results are rejected with a generation check instead of cancelling the request. Updating the cursor only after success also prevents the page number from drifting when a request fails.

**Edge cases:** A failed refresh keeps the existing items and cursor and reports a refresh failure. An old load-more that finishes after a refresh does not modify the feed. When the controller is closed, it no longer updates a `RefreshController` that has already been disposed.

### RES-106 — Wrong pickup times and Pickup today filter

**Root cause:** The API sends ISO-8601 UTC instants, but `PickupWindowModel` formatted the UTC values directly, so it displayed UTC time instead of the market's time in Bangkok (UTC+7). `isToday` compared only the day number against the device's local time, without comparing month/year and without converting the instant to the market's date.

**Fix:** Convert instants to market time using the fixed UTC+7 offset defined by the backend contract before formatting, and compute "today" in the same offset, comparing year, month and day in full. The checks for whether a store is open and the time remaining are computed explicitly on UTC instants.

**Why this fix:** I used the market offset instead of `toLocal()`, because the device's time zone may not be Asia/Bangkok, and pickup times must stay correct regardless of the user's device time zone.

**Edge cases:** Adding UTC+7 can cross a day, month or year boundary, so formatting is done from the market date after conversion and the full date is compared. I added tests covering the UTC 23:00–02:30 window, which must display as 06:00–09:30, and the same day-of-month in different years. Time zones with daylight saving are not supported, because the market in this assignment is defined as fixed UTC+7.

### RES-107 — Deep link opens to a crash

**Root cause:** When a deal page is opened from inside the app, the full deal data (`DealModel`) is always passed to the page. A deep link only contains the deal ID. When the page could not find the full data, it threw an error and crashed before the page could open.

**Fix:** Check whether the full deal data was passed. If the page was opened from a link containing only an ID, fetch the full deal from the server using that ID. A loading screen is shown while fetching, a Retry button is shown if it fails, and adding to the bag is disabled until the data is fully loaded.

**Why this fix:** An external link should work with just an ID by fetching the real data, rather than depending on data that only exists when navigating inside the app. Once the data is fetched, the page should work normally instead of showing an error screen.

**Edge cases:** Opening from inside the app is as fast as before. An invalid or non-numeric ID does not crash the app. Closing the page or pressing Retry does not cause stale-versus-fresh data conflicts.

## Features

### F-1 — Live flash-sale countdowns

**Root cause:** The flash-sale rail displayed a static "Ends soon" label, and the cards and details page had no real countdown or mechanism to turn a deal into an expired state.

**Fix:** Added a central `FlashSaleService` that tracks end times and updates a per-deal Rx countdown every second, plus a separate `RxBool` per deal for the expired state. The `FlashSaleCountdown` widget reads only its own deal's Rx, so only the changing `Text` rebuilds. Countdowns are shown in the flash rail, deal cards and the details screen. When time runs out, the service marks the deal as expired, disables tapping the card and the Add to bag button, and removes the deal from the bag with a snackbar notification.

**Why this fix:** One central timer replaces one timer per card, and the time signal is separated from the expired signal, which changes only once. This avoids rebuilding the card or list every second. A second expiry check in the controller prevents adding to the bag in the gap before the next tick.

**Edge cases:** A deal that has already expired before being displayed is marked expired immediately. The "removed from bag" notice only appears if the item was actually in the bag. Under one hour the countdown shows `mm:ss`, from one hour up it shows `hh:mm:ss`, and at zero it shows `Expired`.

## AI usage log

I used three main AI tools:

1. **GPT 6 Luna in VS Code** — mainly for editing code and explaining the different fixes.
2. **Claude** — for research and asking follow-up questions.
3. **Gemini** — for summarizing the solutions to the various problems.

## Design questions

**Q1:** It is like telling the program to start a task but never telling it to stop when it is no longer needed, so it keeps running until an error occurs.

**Q2:** When an `Obx` wraps too large a subtree, every rebuild uses too many resources.

**Q3:** Separate the time logic into functions that can be tested without opening the app, and make the comparison between UTC and Thai time explicit.

## Time spent

Roughly 2+ days. With more time, I would study Flutter in more depth.