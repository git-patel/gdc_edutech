# Student Learning Platform – Updated Full Product Specification (v2.0)

**Date:** February 2026  
**Product Name (suggested):** LearnFlow / VidyaFlow / EduSphere (you choose)

## 1. Product Vision
A **content-first** learning platform for students Std 1–12 (and lifelong learners) that offers both structured curriculum content and a rich open library.

Students access PDFs, images, notes, HTML lessons, videos, audio explanations, quizzes, mind maps, formula sheets, and previous-year papers — all without forcing them into a rigid “classroom” model.

**Core Philosophy (Non-Negotiable Design Rule)**  
The app is **CONTENT-BASED** with **optional** academic hierarchy.  
Hierarchy (Board → Standard → Subject → Chapter) acts **only as filters**.  
Content can exist completely independently (e.g., career guidance, motivation, Olympiad material, extra topics).

## 2. User Roles (Three Roles)

| Role              | Primary Use Case                          | Key Features                                      |
|-------------------|-------------------------------------------|---------------------------------------------------|
| **Student**       | Daily learning & practice                 | All learning features + progress                  |
| **Parent**        | Monitor child (Std 1–10 mainly)           | Progress reports, time limits, notifications      |
| **Admin/Teacher** | Content creation & management             | CMS, analytics, notifications                     |

**Note:** Parent and Student can use the **same app** with role switching (bottom tab or profile switch).

## 3. Technology Stack (Final Decision)
- **Mobile App**: Flutter (Android + iOS)  
- **Admin Panel**: Flutter Web (single codebase)  
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Messaging)  
- **Payments** (future): Razorpay  
- **AI** (Phase 3): Gemini / Grok API

## 4. App Navigation (Final Structure)
**Bottom Navigation Bar (4 tabs)**  
1. **Home**  
2. **My Class** (structured)  
3. **Library** (unstructured)  
4. **Me** (Profile + Progress)

**Floating Action Button (FAB)** on Home → “Ask Doubt” (future AI)

## 5. Detailed Screen Flow & Wireframe Descriptions

### 5.1 Onboarding Flow (New & Improved)
**Screens:**
1. **Splash** → Logo + tagline “Learn without limits”
2. **Welcome Carousel** (3 slides)  
   - Slide 1: “All your textbooks + extra knowledge in one place”  
   - Slide 2: “Study offline, track progress, improve daily”  
   - Slide 3: “Parents can track everything”
3. **Login** → Google, Phone (OTP), Email  
4. **Quick Profile Setup** (one screen)  
   - Name + profile photo  
   - Board (CBSE / ICSE / State / Others)  
   - Standard (1–12)  
   - Goal (School exams / Olympiads / JEE/NEET / General knowledge)  
   - “Are you a Parent?” → switch to Parent role
5. **Home** (first time)

**Wireframe – Quick Profile Setup**  
[Top] Back    Setup your profile    Skip (optional)

      [Circle avatar] + camera icon

Name: ___________________________

Board:  [CBSE ▼]

Standard:  [Class 9 ▼]

Goal:   [School exams ▼]

[Big green button] Continue

### 5.2 Home Dashboard (Most Important Screen)
**Layout (Top to Bottom)**

- **App Bar**: Logo + Search bar + Notification bell
- **Hero Card – Today’s Focus** (big, colorful)  
  Example: “Finish Photosynthesis (8 min left)” or “Daily Quiz – 5 questions”
- **Study Streak** (flame icon + “7 day streak 🔥”)
- **Continue Learning** (horizontal scroll of last viewed content)
- **Weak Area Booster** (auto-generated from quizzes)
- **My Subjects** (grid – only for student’s class)
- **Recommended for You** (based on goal + progress)
- **Daily Motivation Quote** (swipeable)
- **Announcements** (carousel)

### 5.3 My Class (Structured Path)
Flow: **My Class → Subject Grid → Chapter List → Chapter Detail**

**Chapter Detail Screen** (one beautiful screen)
- Chapter title + progress bar
- Tabs (or segmented control):
  - Notes / PDF
  - Videos
  - Audio
  - Images & Mindmaps
  - Quiz
  - Formula Sheet / PYQ

### 5.4 Library (Unstructured)
Tabs at top: For You | All | Popular | Recent | Career | Motivation

Filters (bottom sheet):
- Content Type (Video, Audio, Mindmap, Article, PYQ…)
- Tags
- Difficulty
- Language

### 5.5 Content Viewer (Unified Player)
- **PDF**: Zoom, bookmark, night mode, jump to page
- **Video**: Streaming + resume + speed 0.5x–2x + picture-in-picture
- **Audio**: Background play + lock-screen controls
- **Image / Mindmap**: Pinch zoom + gallery swipe
- **HTML Lesson**: Formatted text + embedded images/videos
- **Formula Sheet**: Special scrollable view with copy button

**Progress auto-saves** for all types (last page, last second, % read).

### 5.6 Quiz Module (Enhanced)
- Chapter Quiz
- **Daily Quiz** (5 questions every day → streak)
- **Weak Topic Test** (auto-generated 10 questions)
- Timer (optional)
- Instant feedback + explanation
- **Mastery %** shown on chapter card (0–100%)
- Leaderboard (chapter & global)

**Result Screen** shows:
- Score + rank
- Time taken
- Weak questions review
- “Retry” / “Share score on WhatsApp”

### 5.7 Me / Profile Tab
**Student View**:
- Profile photo + name + class + streak
- Overall progress (circular chart)
- Subject-wise mastery grid
- Settings (theme, font size, download quality, clear cache, change class)
- Parent mode toggle (if parent linked)

**Parent View** (separate dashboard):
- Child selector (if multiple children)
- Weekly report card (shareable PDF)
- Time spent today/this week
- Strong & weak subjects
- Set daily limits + app lock

### 5.8 Admin / Teacher CMS (Web)
**Main Sections**:
- Dashboard (analytics)
- Content Management
- Subjects & Chapters
- Quizzes
- Users & Parents
- Notifications
- Bulk Upload (Excel/CSV)

**Content Upload Form** (improved):
- Title, Description
- Type (pdf/video/audio/image/html/mindmap/pyq/formula)
- File upload (drag & drop)
- Thumbnail (auto-generate or upload)
- Board / Standard / Subject / Chapter (all optional)
- Tags (multi-select)
- Difficulty (Easy/Medium/Hard)
- Language
- Duration / Estimated time
- Premium flag
- Related content IDs

**New**: Approval workflow (Draft → Review → Published)

## 6. Database – Firestore Collections (Updated)

**New/Updated fields in `contents`**:
- `type` → now includes: audio, mindmap, pyq, formula_sheet
- `duration` (seconds)
- `difficulty`
- `language`
- `estimatedTime` (minutes)
- `relatedContentIds` (array)
- `isApproved` (for workflow)

**New collections**:
- `parents` (linked to students)
- `daily_quizzes`
- `user_mastery` (per subject/chapter)

## 7. Gamification & Retention
- Study Streak (daily)
- Mastery badges (80%+ = Gold)
- Weekly reports (auto PDF for parents)
- Shareable score cards

## 8. Offline Support
- Download PDFs, Notes, Images, Audio, Videos (encrypted)
- Progress syncs when online

## 9. Security & Rules
- Students read only content matching their board/standard OR content with no hierarchy
- Parents read only their child’s progress
- Only admins upload/publish

## 10. Phased Roadmap (Realistic)

**MVP (v1.0) – 8–10 weeks**
- Onboarding + 3 roles
- Home, My Class, Library, Content viewers
- Basic Quiz + progress
- Offline downloads
- Admin CMS (basic)
- Notifications

**Phase 2 (v1.5) – next 6–8 weeks**
- Parent dashboard + reports
- Gamification (streak, mastery %, Daily Quiz, Weak Topic Test)
- Audio content + mindmaps
- Bulk upload + approval workflow
- Hindi language support

**Phase 3 (v2.0)**
- AI Doubt Solver (Ask Doubt FAB)
- Full mock test series
- Subscription (premium content + ad-free)
- Leaderboard + school-wise ranking
- Study planner

**This is now a complete, production-ready specification.**