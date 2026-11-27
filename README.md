# AI Resume Analyzer

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Gemini](<https://img.shields.io/badge/Google%20Gemini-4285F4?logo=google&logoColor=white>)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)

A mobile app that analyzes a CV (resume), scores it, shows **missing skills**, suggests **improvements**, and can generate an **improved resume as a downloadable PDF**. Built with **Flutter**, **Firebase** and **Google Gemini**.

---

## Table of Contents

1. [Features](#features)
2. [Screenshots](#screenshots)
3. [Tech Stack and Libraries](#tech-stack-and-libraries)
4. [How It Works](#how-it-works)
5. [Project Structure](#project-structure)
6. [Database Structure](#database-structure)
7. [Getting Started](#getting-started)
8. [Configuration](#configuration)
9. [Build the APK](#build-the-apk)
10. [Security Notes](#security-notes)
11. [Limitations](#limitations)
12. [Troubleshooting](#troubleshooting)
13. [Future Improvements](#future-improvements)
14. [License and Credits](#license-and-credits)

---

## Features

**Authentication**

- Register and log in with email and password (Firebase Authentication)
- **Email verification required**: a new account cannot use the app until the user clicks the link sent to their email
- Resend verification email, forgot password, logout

**Resume analysis**

- Upload a **PDF** resume or paste the resume text
- Optional **target job role** (for example Flutter Developer, Data Analyst)
- Overall **score out of 100**
- **Strengths**, **skills found**, **missing skills** and **suggested improvements**
- Two analysis modes:
  - **Gemini AI**: deep, role-specific review
  - **Offline analyzer**: built-in keyword and structure checks, used when no API key is set or the AI is unavailable
- Automatic **model fallback**: if one Gemini model is busy or retired, the app retries and tries the next model in the list

**Improved resume**

- One tap creates an improved, ATS-friendly version of the CV using only facts from the original resume
- Preview inside the app
- **Download PDF** (system "Save as PDF"), **Share**, or **Copy text**

**History**

- Every analysis is saved to Cloud Firestore for the logged-in user
- Open or delete old analyses

---

---

## Screenshots

### 1. Login & Email Verification

|          Login Screen          |                   Verify Email                   |
| :-----------------------------: | :-----------------------------------------------: |
| ![Login](Screenshoot/Login.png) | ![Verify Email](<Screenshoot/Verify%20Email.png>) |

### 2. Home Screen

![Home Screen](Screenshoot/Home.png)

### 3. Resume Analysis

![Analysis Result](<Screenshoot/Analysis%20Result.png>)

![Missing Skills and Tips](<Screenshoot/Missing%20Skills%20and%20Tips.png>)

### 4. Improved Resume

![Improved Resume](<Screenshoot/Improved%20Resume.png>)

### 5. Download Resume as PDF

![Save as PDF](<Screenshoot/Save%20as%20PDF.png>)

### 6. Past Analyses

![Past Analyses](Screenshoot/History.png)

## Tech Stack and Libraries

| Technology                        | Purpose                                                               |
| --------------------------------- | --------------------------------------------------------------------- |
| **Flutter / Dart**          | Cross-platform app framework (Material 3 UI)                          |
| **Firebase Authentication** | Email/password login and email verification                           |
| **Cloud Firestore**         | Stores each user's saved analyses                                     |
| **Google Gemini API**       | AI resume analysis and resume rewriting (called through the REST API) |

**Packages used (`pubspec.yaml`)**

| Package                    | Used for                                                |
| -------------------------- | ------------------------------------------------------- |
| `firebase_core`          | Initializes Firebase                                    |
| `firebase_auth`          | Registration, login, password reset, email verification |
| `cloud_firestore`        | Saving and loading analysis history                     |
| `file_picker`            | Choosing a PDF file from the device                     |
| `syncfusion_flutter_pdf` | Extracting text from the uploaded PDF                   |
| `http`                   | Calling the Gemini REST API                             |
| `pdf`                    | Creating the improved resume PDF                        |
| `printing`               | Download (Save as PDF) and share the generated PDF      |

---

## How It Works

```
Upload PDF / paste text  ->  extract text  ->  analyze  ->  show result  ->  save to Firestore
                                                  |
                          Gemini key set? -- yes --> Gemini AI (tries each model in the list)
                                          -- no  --> Offline analyzer
                                                  |
                                   (tap "Create improved resume")
                                                  |
                          Gemini rewrites CV (JSON)  ->  preview  ->  PDF (download / share)
```

**Offline analyzer scoring (out of 100)**

| Part                                                                 | Max points |
| -------------------------------------------------------------------- | ---------- |
| Skill match for the chosen role                                      | 45         |
| Standard sections (Summary, Education, Experience, Projects, Skills) | 20         |
| Contact details and links (email, phone, LinkedIn/GitHub)            | 15         |
| Measurable results (numbers, percentages)                            | 10         |
| Resume length                                                        | 10         |

The offline analyzer only matches words and is not real AI. Add a Gemini API key for a more accurate review.

**Improved resume rules**

- Uses only information from the original CV
- Does not invent jobs, dates, degrees, skills or numbers
- Does not add the "missing skills" to the resume (they are learning suggestions)

---

## Project Structure

```
resume_analyzer/
├── lib/
│   ├── main.dart                         # App start, auth routing
│   ├── config.dart                       # Gemini API key and model list
│   ├── firebase_options.dart             # Generated by flutterfire configure
│   ├── models/
│   │   ├── analysis_result.dart          # Score, skills, improvements
│   │   └── improved_resume.dart          # Structured improved resume
│   ├── services/
│   │   ├── ai_service.dart               # Gemini analysis + offline analyzer
│   │   ├── resume_writer_service.dart    # Gemini resume rewriting
│   │   ├── pdf_service.dart              # Extract text from PDF
│   │   ├── pdf_builder.dart              # Build the improved resume PDF
│   │   └── firestore_service.dart        # Save / read / delete history
│   └── screens/
│       ├── login_screen.dart
│       ├── verify_email_screen.dart
│       ├── home_screen.dart
│       ├── result_screen.dart
│       ├── improved_resume_screen.dart
│       └── history_screen.dart
├── firestore.rules                       # Database security rules
├── screenshots/                          # App screenshots for this README
└── pubspec.yaml
```

---

## Database Structure

```
users (collection)
└── {uid} (document)
    └── analyses (collection)
        └── {analysisId} (document)
            ├── score            number
            ├── summary          string
            ├── targetRole       string
            ├── strengths        array of strings
            ├── detectedSkills   array of strings
            ├── missingSkills    array of strings
            ├── improvements     array of strings
            ├── source           string (which analyzer produced the result)
            ├── fileName         string
            ├── resumeText       string (needed to create the improved resume)
            └── createdAt        timestamp
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (run `flutter doctor` and fix any red items)
- Android Studio (Android SDK, command-line tools, an emulator or a real phone)
- VS Code with the **Flutter** extension (or Android Studio)
- [Node.js](https://nodejs.org) (needed for the Firebase CLI)
- A Google account (Firebase and Gemini)

### 1. Get the code

```bash
git clone <your-repository-url>
cd resume_analyzer
flutter pub get
```

If the project has no `android` folder, generate it first:

```bash
flutter create --project-name resume_analyzer --platforms=android .
```

### 2. Create the Firebase project

1. Go to the [Firebase console](https://console.firebase.google.com) and create a project.
2. **Authentication** -> Sign-in method -> enable **Email/Password**.
3. **Firestore Database** -> Create database (production mode).
4. **Firestore -> Rules**: paste the content of `firestore.rules` and press **Publish**.

### 3. Connect the app to Firebase

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Select your project and the Android platform. This generates `lib/firebase_options.dart` and `android/app/google-services.json`.

### 4. Add the Gemini API key

1. Create a free key at [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Open `lib/config.dart` and paste it between the quotes:
   ```dart
   static const String geminiApiKey = 'YOUR_KEY_HERE';
   ```

Without a key, the app still works using the offline analyzer.

### 5. Android settings

- Add the internet permission in `android/app/src/main/AndroidManifest.xml`, above `<application`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```
- Set the app name (the label shown on the phone) in the same file:
  ```xml
  android:label="Resume Analyzer"
  ```
- If the build says `minSdk` is too low, set `minSdk = 23` in `android/app/build.gradle(.kts)`.

### 6. Run

```bash
flutter run
```

---

## Configuration

`lib/config.dart`

| Setting          | Description                                                                                                                        |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `geminiApiKey` | Your Google AI Studio API key                                                                                                      |
| `geminiModels` | List of Gemini models, tried from top to bottom. If one is busy (503), rate limited (429) or not found (404), the next one is used |

Gemini model names change over time. Check the current names at the [Gemini models page](https://ai.google.dev/gemini-api/docs/models) and update the list when needed.

---

## Build the APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The file is created at `build/app/outputs/flutter-apk/app-release.apk`. You can rename it, for example to `Resume_Analyzer.apk`. Rebuild the APK every time you change the code.

---

## Security Notes

- **Email verification** is required before the app can be used, and the Firestore rules also require a verified email.
- **Firestore rules** allow each user to read and write only their own analyses.
- The Gemini API key is stored **inside the app**, so it could be extracted by someone who inspects the APK. This is acceptable for a learning or demo project. For production, call Gemini from a backend (for example Firebase Cloud Functions) and keep the key on the server.
- **Never commit your real API key** to a public repository. Remove it from `lib/config.dart` before pushing, or keep the file out of version control.
- Analysis history includes the CV text, so it contains personal data. Keep your Firestore rules strict.

---

## Limitations

- Scanned (image-only) PDFs cannot be read. Paste the text instead.
- The generated PDF supports basic Latin characters only (no Urdu or other scripts).
- The offline analyzer is keyword based and covers a limited set of roles.
- AI output can contain mistakes. The improved resume is a draft, and the user should review every detail.
- The Gemini free tier has usage limits and can be busy at times.

---

## Troubleshooting

| Problem                                              | Solution                                                                                                                                                                |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Firebase is not configured yet"                     | Run `flutterfire configure`                                                                                                                                           |
| `permission-denied` when saving or opening history | Publish `firestore.rules` and make sure the email is verified. Log out and log in again                                                                               |
| `operation-not-allowed` when registering           | Enable Email/Password in Firebase Authentication                                                                                                                        |
| Verification email not arriving                      | Check the Spam folder, then use **Resend email**                                                                                                                  |
| Source says "Offline analyzer (Gemini failed...)"    | Read the text after "failed". 404 means a model name is retired, so update `geminiModels`. 503 means Google is busy, so try again. 400/403 means the API key is wrong |
| Gradle or NDK download errors                        | Check your internet connection, install the NDK from Android Studio SDK Manager (SDK Tools), then `flutter clean` and `flutter run`                                 |
| Red "MaterialLocalizations" error screen             | Stop the app and run `flutter run` again (do not only hot reload)                                                                                                     |
| Release APK cannot reach the internet                | Add the `INTERNET` permission to `AndroidManifest.xml`                                                                                                              |

---

## Future Improvements

- Match a resume against a pasted job description
- More roles and larger skill databases for the offline analyzer
- Multiple resume templates and colors
- Urdu and multi-language support
- iOS and web builds
- Move the AI calls to a secure backend

---

## License and Credits

- Built by **[Your Name]** as a learning project. Add your preferred license here (for example MIT).
- PDF text extraction uses `syncfusion_flutter_pdf`, which is free under the Syncfusion Community License for eligible individuals and small companies. Check their terms for commercial use.
- AI features use the Google Gemini API.
