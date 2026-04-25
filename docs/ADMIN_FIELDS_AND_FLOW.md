# Admin: How It Works & What Each Field Means

Short guide to the admin flow and every field you add or edit in **Subjects**, **Chapters**, and **Contents**.

---

## 1. How admin works

| Step | What happens |
|------|----------------|
| **Who is admin?** | Only users whose Firestore document `users/{uid}` has **isAdmin: true** (set manually in Firebase Console). |
| **Where to open admin?** | Profile tab (Me) → **Admin Panel** (only visible if you are admin) → opens **Admin Dashboard**. |
| **Dashboard** | Three big cards: **Manage Subjects**, **Manage Chapters**, **Manage Contents**. Tap one to open that screen. |
| **Each screen** | List of items from Firestore + **+ Add** button. Each row has **Edit** and **Delete**. After Add/Edit/Delete, the list refreshes automatically. |

**Flow in the app:**  
Subjects (e.g. Maths, Science) → each subject has **Chapters** (e.g. “Chapter 1: Real Numbers”) → each chapter (or “Library”) can have **Contents** (PDF, video, quiz, etc.).  
**Library** = contents that are not linked to any chapter (standalone).

---

## 2. Subjects – what they are and what each field means

**What is a subject?**  
A subject is a group of chapters (e.g. Maths, Science, English). Students see subjects on **My Class** and **Home → My Subjects**.

| Field | Meaning | Example |
|-------|--------|--------|
| **Name** | Display name of the subject. | `Maths`, `Science` |
| **Board** | Curriculum board. Used for filtering/display. | `CBSE`, `ICSE`, `State`, `Others` |
| **Standard** | Class (grade) this subject is for. | `1` to `12` |
| **Icon URL** | Optional image URL for the subject icon. Paste a link; leave empty for default icon. | `https://...` or empty |
| **Order** | Number used to **sort subjects** in the app (smaller = shown first). | `0`, `1`, `2` |

**Order:** Lower number = appears earlier in the list. Same order = Firestore order.

---

## 3. Chapters – what they are and what each field means

**What is a chapter?**  
A chapter belongs to **one subject** and groups **contents** (notes, PDFs, videos, quiz) for that topic. Students see chapters inside a subject (e.g. Maths → Chapter 1, Chapter 2).

| Field | Meaning | Example |
|-------|--------|--------|
| **Subject** | The subject this chapter belongs to. Required. | Maths, Science |
| **Title** | Chapter name shown in the app. | `Chapter 1: Real Numbers` |
| **Description** | Optional short text about the chapter. | `Introduction to real numbers` |
| **Order** | Number used to **sort chapters** inside the subject (smaller = first). | `0`, `1`, `2` |

**Order:** Lower number = chapter appears earlier in the list under that subject.

---

## 4. Contents – what they are and what each field means

**What is a content?**  
A single learning item: one PDF, one video, one quiz, etc. It can be linked to a **chapter** (shown under that chapter) or to **no chapter** (Library = standalone).

| Field | Meaning | Example |
|-------|--------|--------|
| **Title** | Name of the content. | `Algebra basics PDF` |
| **Type** | Kind of content. | `pdf`, `video`, `audio`, `image`, `html`, `mindmap`, `quiz` |
| **File / URL** | For PDF/video/audio/image: upload a file (you get a URL). Or you can set URL later when editing. | Uploaded file → stored URL |
| **Thumbnail URL** | Optional image URL for the card. | `https://...` or empty |
| **Chapter** | Where this content appears. **Library (no chapter)** = standalone; or pick a chapter. | Library, or “Maths – Chapter 1” |
| **Tags** | Labels for filtering (multi-select). | JEE, NEET, Motivation, Olympiad, etc. |
| **Difficulty** | How hard the content is. | Easy, Medium, Hard |
| **Duration** | Length in **minutes** (e.g. for video or reading). | `10`, `45` |
| **Premium** | If true, content is marked as premium (e.g. for paid users). | On / Off |

**Order:** Contents are listed by **title** (no “order” field). Use title or filters to organize.

---

## 5. Quick reference: where each field is used

| Screen | Add/Edit fields |
|--------|------------------|
| **Subjects** | Name, Board, Standard, Icon URL, Order |
| **Chapters** | Subject, Title, Description, Order |
| **Contents** | Title, Type, File/URL, Thumbnail URL, Chapter, Tags, Difficulty, Duration, Premium |

---

## 6. What “order” means in short

- **Subject order:** Order in which subjects appear (e.g. Maths first, then Science). **Smaller number = first.**
- **Chapter order:** Order in which chapters appear inside a subject. **Smaller number = first.**

Use 0, 1, 2, … or 10, 20, 30 so you can insert new items in between later (e.g. 15 between 10 and 20).
