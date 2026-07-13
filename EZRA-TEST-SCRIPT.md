# Build 16 — full test script (150 steps) · demo data seeded

Every password: **`Milton2026!`** · Every code: **`000000`** · ⭐ = a fix we just shipped (watch these).
Only flag what's **broken/weird**. Wipe the demo data before launch with `launch-kit/CLEANUP-DEMO-CONTENT.sql`.

**Logins**
| Role | Email |
|---|---|
| Alumni (FL) — main test user | `appreviewer@miltonrecovery.com` |
| Alumni (FL) demo | `recovery.warrior@miltondemo.seed` · `grateful.heart@miltondemo.seed` |
| Alumni (OH) demo | `new.chapter.oh@miltondemo.seed` · `steel.city.strong@miltondemo.seed` |
| Super Admin | `super-demo@miltonrecovery.com` |
| FL Admin | `admin@miltonrecovery.com` |
| OH Admin | `admin@miltonjefferson.com` |
| Case Manager | `case-manager-demo@miltonrecovery.com` |
| Therapist | `therapist-demo@miltonrecovery.com` |

## Setup
- [ ] 1. Open Milton Nation (TestFlight, **Build 16**). Icon looks right.
- [ ] 2. Opens <3s → splash → login screen.
- [ ] 3. ⭐ Login screen clean: logo has **NO color-swatch bar**; tagline; Email/Password; Login; Register.
- [ ] 4. iOS notifications prompt → **Allow**.
- [ ] 5. iPhone Settings → Notifications → Milton Nation → ON → back.

## Alumni sign-in — appreviewer@miltonrecovery.com
- [ ] 6. Type "abc" in email → not accepted.
- [ ] 7. Enter appreviewer email; password hides text.
- [ ] 8. WRONG password → "Invalid email or password", no crash.
- [ ] 9. Correct password → advances to code screen.
- [ ] 10. "Enter the 6-digit code…".
- [ ] 11. Wrong code 111111 → error, retry.
- [ ] 12. `000000` → Home (now populated).
- [ ] 13. (later, from login) "Forgot password?" opens a reset flow.
- [ ] 14. No crash through sign-in.

## Home
- [ ] 15. Home loads.
- [ ] 16. Sobriety card shows **~92 days** (real streak now).
- [ ] 17. ⭐ Daily Reflection shows today's quote with a real author — **no "— Unknown"**.
- [ ] 18. Points & Badges shows a total + earned badges (Sprout/Bloom).
- [ ] 19. Go to Community tab.

## Feed / Community
- [ ] 20. Feed shows **~8 Florida posts** (Wins/Struggles/Support/Gratitude), pinned one at top.
- [ ] 21. Pull-to-refresh → spinner → reloads.
- [ ] 22. Scroll to bottom → loads (or ends cleanly).
- [ ] 23. Category chips (All/Wins/Struggles/Support/Gratitude) → each filters.
- [ ] 24. Tap a demo author (e.g. **recovery.warrior**) → their profile → back.
- [ ] 25. Tap a heart on their post → count +1.
- [ ] 26. Pull-to-refresh → like **persisted**.
- [ ] 27. Tap heart again → unlike, −1.
- [ ] 28. Tap a post's comment icon → detail shows post + existing comments.

## Create post
- [ ] 29. Tap + → create sheet.
- [ ] 30. Category picker → pick one.
- [ ] 31. ⭐ Type "Testing Build 16 — win!" → Post.
- [ ] 32. ⭐ Appears at top ~3s (the old Build-10 bug — must work).
- [ ] 33. Shows your name + timestamp.
- [ ] 34. New post → add photo via Camera (allow) → preview.
- [ ] 35. Swap via Library → preview updates.
- [ ] 36. Post → shows image, not distorted.
- [ ] 37. Tap image in feed → fullscreen → close.
- [ ] 38. Empty body can't post.

## Crisis + disclaimers
- [ ] 39. + → type `I want to end my life` → try Post.
- [ ] 40. ⭐ Crisis sheet pops **immediately**, before posting.
- [ ] 41. ⭐ Red disclaimer: "not an emergency service… not 24/7… 988/911".
- [ ] 42. Lists 988, 741741, SAMHSA 1-800-662-4357, Milton FL (844) 406-4325, OH (740) 715-4673, 911.
- [ ] 43. Tap 988 → dialer → cancel.
- [ ] 44. Tap Milton FL → dialer → cancel.
- [ ] 45. Dismiss.
- [ ] 46. `I shot heroin today` → sheet.
- [ ] 47. `I made myself throw up` → sheet.
- [ ] 48. `He hit me again` → sheet.
- [ ] 49. ⭐ `I haven't relapsed in 5 years` → posts normally, **no sheet**.
- [ ] 50. Post crisis twice → sheet **both** times.
- [ ] 51. Tap "I'm Struggling" → modal opens.
- [ ] 52. ⭐ Modal shows disclaimer + resources; numbers dial.

## Report / Block / Unblock (target a demo alumnus)
- [ ] 53. On **recovery.warrior**'s post → tap ••• (top-right).
- [ ] 54. ⭐ Report Post → confirm → "Thanks for reporting."
- [ ] 55. Open comments → ••• on someone's comment → Report Comment → success.
- [ ] 56. ⭐ On YOUR OWN post/comment → **no ••• menu**.
- [ ] 57. On recovery.warrior's post → ••• → Block → confirm.
- [ ] 58. ⭐ Their post **vanishes** immediately + "…has been blocked."
- [ ] 59. Scroll → none of recovery.warrior's posts/comments show.
- [ ] 60. Settings → Privacy → Blocked Users → recovery.warrior listed.
- [ ] 61. Unblock → row gone.
- [ ] 62. Feed → pull-to-refresh → their posts are back.
- [ ] 63. Block via a comment's ••• too → same behavior.

## Profile / sobriety / badges
- [ ] 64. Profile → name, @username, email.
- [ ] 65. Points/Badges bar + tiers (Seedling→Legend); Sprout/Bloom earned.
- [ ] 66. "How to Earn Badges" list.
- [ ] 67. Avatar camera → set photo → updates.
- [ ] 68. Edit a field → save → persists.
- [ ] 69. Update recovery date → days recalc.
- [ ] 70. Milestones (30/60/90) reflect.
- [ ] 71. Home sobriety card reflects the change.
- [ ] 72. Earned badge shows if threshold met.
- [ ] 73. No layout breaks.

## Meetings
- [ ] 74. Meetings tab → **5 meetings** load.
- [ ] 75. Milton / Nearby toggle (allow location) → both populate.
- [ ] 76. Search a meeting → filters.
- [ ] 77. Tap a meeting → detail (title/desc/time/location).
- [ ] 78. RSVP → confirmation → persists.
- [ ] 79. Un-RSVP → updates.
- [ ] 80. Virtual meeting shows Virtual badge / join.
- [ ] 81. In-person shows address (tap → Maps).
- [ ] 82. Scroll → no broken cards.

## Chat (care team)
- [ ] 83. Chat tab → **2 conversations** (case manager + therapist).
- [ ] 84. Open one → messages render.
- [ ] 85. Type a message → Send → appears.
- [ ] 86. Re-open → persisted.
- [ ] 87. Timestamps + names correct.
- [ ] 88. Back → count sane.
- [ ] 89. No crash.

## Settings
- [ ] 90. Open Settings.
- [ ] 91. Profile section correct.
- [ ] 92. Notifications → toggle a type off → saves.
- [ ] 93. Face ID / app-lock toggle.
- [ ] 94. ⭐ Terms → opens app-terms-of-use.
- [ ] 95. ⭐ Privacy → opens milton-nation-privacy.
- [ ] 96. Support → mail composer to support address.
- [ ] 97. Phone number change → flow completes.
- [ ] 98. Screenshot protection behaves.
- [ ] 99. Sign Out → login → sign back in (7–12).
- [ ] 100. No crash.
- [ ] 101. About / version shows **1.0 (16)**.
- [ ] 102. Return Home.

## OH alumnus — facility isolation (⭐ the PHI fix)
- [ ] 103. Sign out → sign in as **new.chapter.oh@miltondemo.seed** → 000000.
- [ ] 104. ⭐ Feed shows the **4 Ohio posts** — and **NOT** the Florida posts you saw as appreviewer.
- [ ] 105. Confirm the reverse: nothing FL-specific leaks in.
- [ ] 106. (Contrast) super-demo will see BOTH — you'll confirm that in step 119.

## Download data / Delete (back as appreviewer)
- [ ] 107. Sign in as appreviewer → Settings → Download My Data.
- [ ] 108. ⭐ Export includes your posts, comments, **messages**.
- [ ] 109. ⭐ Wifi off → retry → "Export Failed" alert (not silent).
- [ ] 110. Wifi on.
- [ ] 111. ⭐ Delete Account → copy = 30-day grace + HIPAA retention.
- [ ] 112. Confirm → logged out.
- [ ] 113. ⭐ Re-login as appreviewer → **BLOCKED** ("deactivated").
- [ ] 114. ⭐ Tell me → I re-activate appreviewer.

## Registration / consent
- [ ] 115. Login → Register → fill the form.
- [ ] 116. ⭐ "I agree" checkbox — Register **disabled** until checked; Terms/Privacy links open.
- [ ] 117. Username with your real name → error. Tick consent → Register → "pending approval."

## Super Admin — super-demo@miltonrecovery.com
- [ ] 118. Sign out → sign in → 000000.
- [ ] 119. ⭐ Dashboard sees **BOTH** facilities (FL + OH data + your OH/FL posts).
- [ ] 120. ⭐ **No fake data** (no "Jordan Test", no fake reflections, no fake "I relapsed…" chat).
- [ ] 121. User Management → all users incl. the demo alumni.
- [ ] 122. Open a user → details.
- [ ] 123. Audit Log → entries.
- [ ] 124. Cross-facility announcement → posts.
- [ ] 125. User View → alumni experience → Back to Admin.
- [ ] 126. No crash.

## FL Admin — admin@miltonrecovery.com
- [ ] 127. Sign out → sign in → 000000.
- [ ] 128. Dashboard shows **Florida**.
- [ ] 129. ⭐ Pending Approvals → **3 applicants** (your reg + Chris + eswag59).
- [ ] 130. ⭐ **Approve** one → succeeds.
- [ ] 131. ⭐ **Reject** one → succeeds (the prod-bug fix — status 'rejected').
- [ ] 132. ⭐ Content Flags → **4 flags** incl. your report + the seeded user_report + crisis flag.
- [ ] 133. Open a flag → review / escalate / dismiss.
- [ ] 134. ⭐ Chat Monitor → the seeded **flagged crisis message** shows (real, not fake).
- [ ] 135. Announcements → create → appears.
- [ ] 136. Meeting Management → edit a meeting → saves (real created-by).
- [ ] 137. Community Moderation → the flagged_for_crisis post shows → approve/reject.
- [ ] 138. Invite Alumni → uses **EMAIL** (SMS off for v1).

## OH Admin — admin@miltonjefferson.com (⭐ isolation)
- [ ] 139. Sign out → sign in → 000000.
- [ ] 140. Dashboard shows **Ohio**.
- [ ] 141. ⭐ FL posts/alumni/flags do **NOT** appear here.
- [ ] 142. ⭐ Only Ohio content shows.
- [ ] 143. ⭐ vs super-demo (saw both) = isolation holds.

## Care team — case-manager-demo / therapist-demo
- [ ] 144. Sign in case-manager-demo → 000000 → care view + demo caseload load.
- [ ] 145. Open the appreviewer conversation → messages render.
- [ ] 146. ⭐ (2nd device) alumnus taps "Notify care team" → care-team device gets push "A member has requested care team support" (**no name**).
- [ ] 147. Sign in therapist-demo → 000000 → loads.
- [ ] 148. Care-team chat send/receive works.
- [ ] 149. ⭐ High-risk crisis post as an alumnus → admins/care team get the crisis push.

## Wrap
- [ ] 150. Airplane mode → open app → graceful offline (no crash). Dark Mode → readable. Sign out clean. ✅ **Done — report anything broken.**
