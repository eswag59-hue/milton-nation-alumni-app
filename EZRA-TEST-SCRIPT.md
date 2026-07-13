# Build 16 — full test script (150 steps)

All passwords: **`Milton2026!`** · All codes: **`000000`** · ⭐ = a fix we just shipped.
Only flag what's **broken/weird** — anything broken, tell Claude, he fixes it.

Logins: Super `super-demo@miltonrecovery.com` · FL Admin `admin@miltonrecovery.com` · OH Admin `admin@miltonjefferson.com` · Case Mgr `case-manager-demo@miltonrecovery.com` · Therapist `therapist-demo@miltonrecovery.com` · Alumni(FL) `appreviewer@miltonrecovery.com`

## Setup
- [ ] 1. Open the Milton Nation app (TestFlight, Build 16). Icon looks right (wordmark + brand color).
- [ ] 2. App opens in <3s; brief splash → login screen.
- [ ] 3. Login screen clean: logo (⭐ NO color-swatch bar), tagline, Email/Password, Login, Forgot password, Register.
- [ ] 4. iOS asks for notifications → tap Allow.
- [ ] 5. iPhone Settings → Notifications → Milton Nation → Allow Notifications ON → back to app.

## Alumni sign-in — appreviewer@miltonrecovery.com
- [ ] 6. Type invalid email "abc" → flagged / not accepted.
- [ ] 7. Enter appreviewer email; password field hides text.
- [ ] 8. WRONG password → Login → clean "Invalid email or password", no crash.
- [ ] 9. Correct password `Milton2026!` → Login → advances to code screen.
- [ ] 10. Code screen says "Enter the 6-digit code…".
- [ ] 11. Wrong code 111111 → error, can retry.
- [ ] 12. Enter `000000` → Home feed.
- [ ] 13. (later) "Forgot password?" opens a reset flow.
- [ ] 14. No crash through sign-in.

## Home / Feed
- [ ] 15. Home tab loads.
- [ ] 16. Sobriety "Your Journey" card shows days.
- [ ] 17. ⭐ Daily Reflection shows a quote — NO "— Unknown" author line.
- [ ] 18. Points & Badges shows a total.
- [ ] 19. Go to Community tab.
- [ ] 20. Feed shows post cards (author, photo/initials, time, content, like+comment counts).
- [ ] 21. Pull-to-refresh → spinner → posts reload.
- [ ] 22. Scroll to bottom → next page loads.
- [ ] 23. Category chips (All/Wins/Struggles/Support/Gratitude) → each filters.
- [ ] 24. Tap an author name → their profile → back.
- [ ] 25. Tap a heart → count +1.
- [ ] 26. Pull-to-refresh → like PERSISTED.
- [ ] 27. Tap heart again → unlike, −1.
- [ ] 28. Tap comment icon → post detail (full post + comments).

## Create post
- [ ] 29. Tap + → create sheet appears.
- [ ] 30. Category picker: Wins/Struggles/Support/Gratitude/General → pick one.
- [ ] 31. ⭐ Type "Testing Build 16 — win!" → Post.
- [ ] 32. ⭐ Post appears at top within ~3s (the old Build-10 bug — must work).
- [ ] 33. Your post shows your name + timestamp.
- [ ] 34. New post → add photo via Camera (allow) → preview shows.
- [ ] 35. Swap photo via Library → preview updates.
- [ ] 36. Post → uploads → shows with image, not distorted.
- [ ] 37. Tap image in feed → fullscreen → close.
- [ ] 38. Category picker doesn't let you post an empty body.

## Crisis detection + disclaimers
- [ ] 39. + → new post → type `I want to end my life` → try Post.
- [ ] 40. ⭐ Crisis sheet appears IMMEDIATELY, before posting.
- [ ] 41. ⭐ Red disclaimer on it: "not an emergency service… not 24/7… 988/911."
- [ ] 42. Shows 988 (call+text), 741741, SAMHSA 1-800-662-4357, Milton FL (844) 406-4325, OH (740) 715-4673, 911.
- [ ] 43. Tap 988 → dialer opens correct number → cancel.
- [ ] 44. Tap Milton FL number → dialer → cancel.
- [ ] 45. Dismiss sheet.
- [ ] 46. Type `I shot heroin today` → crisis sheet.
- [ ] 47. Type `I made myself throw up` → crisis sheet.
- [ ] 48. Type `He hit me again` → crisis sheet.
- [ ] 49. ⭐ Type `I haven't relapsed in 5 years` → posts normally, NO sheet.
- [ ] 50. Post crisis content twice → sheet appears BOTH times.
- [ ] 51. Tap "I'm Struggling" → struggling modal opens.
- [ ] 52. ⭐ Modal shows disclaimer banner + resources; numbers dial.

## Report / Block / Unblock
- [ ] 53. On someone else's post → tap ••• (top-right).
- [ ] 54. ⭐ "Report Post" → confirm → "Thanks for reporting…".
- [ ] 55. Open comments → ••• on someone's comment → Report Comment → success.
- [ ] 56. ⭐ On YOUR OWN post/comment → NO ••• Report/Block menu.
- [ ] 57. Another user's post → ••• → "Block [name]" → confirm.
- [ ] 58. ⭐ Their post disappears immediately + "…has been blocked."
- [ ] 59. Scroll → none of that user's posts/comments show.
- [ ] 60. Settings → Privacy → Blocked Users → they're listed.
- [ ] 61. Unblock → row disappears.
- [ ] 62. Feed → pull-to-refresh → their posts are back.
- [ ] 63. Block via a comment's ••• too → same behavior.

## Profile / sobriety / badges
- [ ] 64. Profile tab → name, @username, email.
- [ ] 65. Points & Badges bar + tiers (Seedling→Legend) render.
- [ ] 66. "How to Earn Badges" list shows.
- [ ] 67. Avatar camera icon → set a photo → updates.
- [ ] 68. Edit a profile field → save → persists.
- [ ] 69. Update recovery date → picker → days recalc.
- [ ] 70. Milestones update with the new date.
- [ ] 71. Home sobriety card reflects the change.
- [ ] 72. An earned milestone badge shows if threshold met.
- [ ] 73. No layout breaks on Profile.

## Meetings
- [ ] 74. Meetings tab → list loads.
- [ ] 75. Toggle Milton / Nearby (Nearby → Allow location) → both populate.
- [ ] 76. Search a meeting → filters.
- [ ] 77. Tap a meeting → detail (title/desc/time/location).
- [ ] 78. RSVP → confirmation → persists.
- [ ] 79. Un-RSVP → updates.
- [ ] 80. Virtual meeting shows Virtual badge / join.
- [ ] 81. In-person shows address (tappable → Maps).
- [ ] 82. Scroll → no broken cards.

## Chat
- [ ] 83. Chat tab → conversations (or empty state).
- [ ] 84. Open a conversation → messages render.
- [ ] 85. Type a message → Send → appears.
- [ ] 86. Re-open → message persisted.
- [ ] 87. Timestamps + sender names correct.
- [ ] 88. Empty state (if any) is friendly.
- [ ] 89. Back out → chat count sane.

## Settings
- [ ] 90. Open Settings.
- [ ] 91. Profile section shows your info.
- [ ] 92. Notifications → toggle a type off → saves.
- [ ] 93. Privacy/Security → Face ID / app-lock toggle → toggles.
- [ ] 94. ⭐ Legal → Terms of Service → opens app-terms-of-use page.
- [ ] 95. ⭐ Legal → Privacy Policy → opens milton-nation-privacy page.
- [ ] 96. Support → contact → opens mail to support address.
- [ ] 97. Phone number change → enter new number → flow completes.
- [ ] 98. Screenshot protection behaves as designed on a sensitive screen.
- [ ] 99. Sign Out → login screen. Sign back in (steps 7–12).
- [ ] 100. No setting caused a crash.
- [ ] 101. About / version info shows Build 16 (1.0).
- [ ] 102. Return to Home.

## Download data / Delete account (end of this account)
- [ ] 103. Settings → Download My Data.
- [ ] 104. ⭐ Export includes your posts, comments, AND messages.
- [ ] 105. ⭐ Turn OFF wifi/data → retry → "Export Failed" alert (not silent).
- [ ] 106. Data back on.
- [ ] 107. ⭐ Delete Account → copy = 30-day grace + permanent removal + HIPAA retention.
- [ ] 108. Confirm → logged out immediately.
- [ ] 109. ⭐ Try to log back in as appreviewer → BLOCKED ("account has been deactivated").
- [ ] 110. ⭐ Tell Claude → he re-activates appreviewer for the rest of testing.

## Registration / consent
- [ ] 111. Login → Register.
- [ ] 112. Fill name, username, email, phone, password, facility, dates.
- [ ] 113. ⭐ "I agree to Terms & Privacy" checkbox — Register button DISABLED until checked.
- [ ] 114. Tap Terms link → opens; Privacy link → opens.
- [ ] 115. Username containing your real name → error "Username cannot contain your real name."
- [ ] 116. Tick consent → Register → "pending approval" message.

## Super Admin — super-demo@miltonrecovery.com
- [ ] 117. Sign out → sign in as super-demo → 000000.
- [ ] 118. Admin dashboard loads → role = Super Admin.
- [ ] 119. ⭐ Sees BOTH facilities (FL + OH).
- [ ] 120. ⭐ NO fake data (no "Jordan Test", no fake reflections, no fake "I relapsed…" chat).
- [ ] 121. User Management → all users across facilities.
- [ ] 122. Open a user → details render.
- [ ] 123. Audit Log → opens, has entries.
- [ ] 124. Cross-facility announcement → posts.
- [ ] 125. "User View" → alumni experience → "Back to Admin" returns.
- [ ] 126. No crash across super-admin.

## FL Admin — admin@miltonrecovery.com
- [ ] 127. Sign out → sign in as admin@miltonrecovery.com → 000000.
- [ ] 128. Dashboard shows Florida.
- [ ] 129. ⭐ Pending Approvals → your reg (step 116) + `eswag59` appear.
- [ ] 130. ⭐ Approve one → succeeds (no silent failure).
- [ ] 131. ⭐ Reject one → succeeds (tests the status='rejected' prod-bug fix).
- [ ] 132. ⭐ Content Flags → your report (step 54) appears (type User Report).
- [ ] 133. Open a flag → review / escalate / dismiss work.
- [ ] 134. ⭐ Chat Monitor → REAL flagged messages or clean empty — NOT the fake crisis line.
- [ ] 135. Announcements → create → appears.
- [ ] 136. Meeting Management → create/edit → saves (real created-by).
- [ ] 137. Community Moderation → approve/reject a post.
- [ ] 138. Invite Alumni → uses EMAIL (SMS off for v1).

## OH Admin — admin@miltonjefferson.com (⭐ facility isolation)
- [ ] 139. Sign out → sign in as admin@miltonjefferson.com → 000000.
- [ ] 140. Dashboard shows Ohio.
- [ ] 141. ⭐ The FL post/data from earlier does NOT appear here.
- [ ] 142. ⭐ FL approvals / FL flags do NOT show for OH admin.
- [ ] 143. ⭐ (Contrast) super-demo saw both; OH admin sees only Ohio = PHI isolation holds.

## Care team — case-manager-demo / therapist-demo
- [ ] 144. Sign in as case-manager-demo → 000000 → care-team view loads.
- [ ] 145. Assigned alumni / care surfaces render (no fake data).
- [ ] 146. ⭐ (needs appreviewer active + a 2nd device) alumnus taps "Notify care team" → care-team device gets push "A member has requested care team support" (NO name).
- [ ] 147. Sign in as therapist-demo → 000000 → therapist view loads.
- [ ] 148. Care-team chat with an alumnus → send/receive works.
- [ ] 149. ⭐ High-risk crisis post as an alumnus → admins/care team get the crisis push.

## Edge + wrap
- [ ] 150. Airplane mode → open app → graceful offline (no crash). Dark Mode → readable. Sign out cleanly. ✅ Done — report anything broken.
