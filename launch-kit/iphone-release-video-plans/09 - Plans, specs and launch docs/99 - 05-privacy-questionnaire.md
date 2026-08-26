# App Store Privacy Questionnaire — Click-by-Click Answers

In App Store Connect → your app → left sidebar → **App Privacy** → **Get Started**.

Apple walks you through one screen at a time. Here's exactly what to click on each.

---

## Screen 1: "Does your app collect any data?"
**Answer**: ✅ **Yes, we collect data from this app**

---

## Screen 2: Categories — check ALL of these

| Category | ☑ |
|---|---|
| Contact Info | ☑ |
| Health & Fitness | ☑ |
| Sensitive Info | ☑ |
| User Content | ☑ |
| Identifiers | ☑ |
| Usage Data | ☑ |
| Diagnostics | ☑ |
| Location | ☑ |

**Do NOT check** any of these:
- Financial Info
- Browsing History
- Search History
- Audio Data
- Gameplay Content
- Customer Support
- Other Data Types

---

## For each category, Apple asks 3 sub-questions per data type. Below are the answers.

### Contact Info → Name
- Linked to user? **Yes**
- Used for tracking? **No**
- Purposes: ☑ App Functionality

### Contact Info → Email Address
- Linked? **Yes** | Tracking? **No**
- Purposes: ☑ App Functionality, ☑ Account Management

### Contact Info → Phone Number
- Linked? **Yes** | Tracking? **No**
- Purposes: ☑ App Functionality, ☑ Account Management

### Health & Fitness → Health
> "We collect sobriety dates and treatment program type to support recovery tracking."
- Linked? **Yes** | Tracking? **No**
- Purposes: ☑ App Functionality

### Sensitive Info → Sensitive Info
> "Recovery program participation, mental health context in user-generated content."
- Linked? **Yes** | Tracking? **No**
- Purposes: ☑ App Functionality

### User Content → Photos or Videos
- Linked? **Yes** | Tracking? **No**
- Purposes: ☑ App Functionality

### User Content → Other User Content
> "Community posts, comments, chat messages."
- Linked? **Yes** | Tracking? **No**
- Purposes: ☑ App Functionality

### Identifiers → User ID
> "Internal Supabase profile UUID."
- Linked? **Yes** | Tracking? **No**
- Purposes: ☑ App Functionality, ☑ Analytics

### Identifiers → Device ID
> "APNs push notification token."
- Linked? **Yes** | Tracking? **No**
- Purposes: ☑ App Functionality

### Usage Data → Product Interaction
> "Screen views, feature usage events."
- Linked? **Yes** | Tracking? **No**
- Purposes: ☑ Analytics, ☑ App Functionality

### Diagnostics → Crash Data
- Linked? **No** (we don't tie crashes to specific users)
- Tracking? **No**
- Purposes: ☑ App Functionality

### Diagnostics → Performance Data
- Linked? **No** | Tracking? **No**
- Purposes: ☑ Analytics

### Location → Coarse Location
> "Used only when user grants permission for nearby meeting search. Not stored on backend."
- Linked? **No** | Tracking? **No**
- Purposes: ☑ App Functionality

---

## Screen N: "Does your app use any third-party SDKs that combine data with data from other apps for advertising or share data with data brokers?"

**Answer**: ❌ **No**

---

## Screen N+1: "Does your app use third-party SDKs?"

**Answer**: ❌ **No**

(Supabase Swift SDK is a database client, not a third-party tracker. APNs is Apple's own service. BMLT is read-only public API. None of these meet Apple's "third-party SDK" definition for the privacy label.)

---

## Result: Privacy Nutrition Label

After saving, your App Store listing will show:

> **Data Linked to You**
> • Contact Info (Name, Email, Phone)
> • Health & Fitness
> • Sensitive Info
> • User Content (Photos, Videos, Other)
> • Identifiers (User ID, Device ID)
> • Usage Data
>
> **Data Not Linked to You**
> • Diagnostics (Crash Data, Performance Data)
> • Location (Coarse Location)
>
> **Data Used to Track You**
> _None_

This is the cleanest possible label for an app that handles PHI — Apple reviewers will see "no tracking, no advertising" and move on quickly.

---

## ⚠️ If Apple later asks why you said "Sensitive Info"

Recovery / SUD treatment context is sensitive under HIPAA. We disclose it because:
1. The very fact of being a Milton Recovery Centers alumni implies treatment.
2. Posts and chats may contain references to substance use, mental health, or recovery program details.
3. Apple's privacy questionnaire defines "Sensitive Info" broadly — when in doubt, disclose.

This is the conservative, attorney-approvable answer.
