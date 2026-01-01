# Resume Learning App

A full-stack learning application with "Resume where you left off" functionality, built with Flutter (Frontend) and Go (Backend) with MongoDB database.

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Project Structure](#project-structure)
- [Design Decisions](#design-decisions)
- [Edge Cases Handled](#edge-cases-handled)
- [Future Improvements](#future-improvements)

## ✨ Features

### Core Features
- **Resume Video Playback**: Automatically resume videos from the exact timestamp where you left off
- **Resume Quiz Progress**: Continue quizzes from the exact question you were on
- **Cross-Device Synchronization**: Login from any device and pick up exactly where you left off
- **Auto-Save Progress**: Progress is automatically saved every 5 seconds during video playback
- **Real-time Progress Tracking**: See your completion percentage for each chapter
- **Professional UI/UX**: Clean, modern interface with smooth animations

### User Features
- Simple login/logout system
- User progress visualization
- Chapter completion tracking
- Quiz scoring and results
- Continue card showing most recent activity
- Progress reset functionality

## 🛠 Tech Stack

### Frontend
- **Flutter**: Cross-platform mobile framework
- **Provider**: State management
- **Chewie**: Video player with controls
- **Shared Preferences**: Local storage

### Backend
- **Go (Golang)**: High-performance backend API
- **Gorilla Mux**: HTTP router
- **MongoDB**: NoSQL database for flexible data storage

### DevOps
- **Docker**: Containerization
- **Docker Compose**: Multi-container orchestration

## 🏗 Architecture

```
┌─────────────┐
│   Flutter   │  (Mobile App)
│   Frontend  │
└──────┬──────┘
       │ HTTP REST API
       │
┌──────▼──────┐
│     Go      │  (Backend Server)
│   Backend   │
└──────┬──────┘
       │ MongoDB Driver
       │
┌──────▼──────┐
│   MongoDB   │  (Database)
└─────────────┘
```

### Data Flow
1. User interacts with Flutter UI
2. Flutter app makes HTTP requests to Go backend
3. Go backend processes requests and interacts with MongoDB
4. MongoDB stores/retrieves user data and progress
5. Backend sends response back to Flutter
6. Flutter updates UI based on response

## 📦 Prerequisites

### For Backend
- Go 1.21 or higher
- Docker & Docker Compose (recommended) OR
- MongoDB 7.0+ (if running without Docker)

### For Frontend
- Flutter SDK 3.0.0 or higher
- Android Studio / Xcode (for emulators)
- Android SDK (for Android)
- iOS SDK (for iOS)

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd resume-learning-app
```

### 2. Backend Setup

#### Option A: Using Docker (Recommended)

```bash
cd backend
docker-compose up -d
```

This will start both MongoDB and the Go backend server.

#### Option B: Manual Setup

1. Install MongoDB locally and ensure it's running on port 27017

2. Install Go dependencies:
```bash
cd backend
go mod download
```

3. Run the backend:
```bash
go run main.go
```

The backend will be available at `http://localhost:8080`

### 3. Frontend Setup

```bash
cd frontend
flutter pub get
```

### 4. Configure API URL

Open `lib/services/api_service.dart` and update the `baseUrl`:

```dart
// For Android emulator
static const String baseUrl = 'http://10.0.2.2:8080/api';

// For iOS simulator
static const String baseUrl = 'http://localhost:8080/api';

// For physical device (replace with your computer's IP)
static const String baseUrl = 'http://192.168.1.XXX:8080/api';
```

## 🎮 Running the Application

### Backend

```bash
cd backend
docker-compose up

# OR if running manually
go run main.go
```

The backend will start on `http://localhost:8080`

### Frontend

```bash
cd frontend

# For Android
flutter run

# For iOS
flutter run

# For specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

## 📡 API Documentation

### Base URL
```
http://localhost:8080/api
```

### Endpoints

#### 1. Health Check
```http
GET /api/health
```

Response:
```json
{
  "success": true,
  "message": "Server is running",
  "data": {
    "status": "healthy",
    "time": "2025-01-01T00:00:00Z"
  }
}
```

#### 2. Login
```http
POST /api/login
Content-Type: application/json

{
  "userId": "user123",
  "name": "John Doe"
}
```

Response:
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": "...",
    "userId": "user123",
    "name": "John Doe",
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

#### 3. Get All Chapters
```http
GET /api/chapters
```

Response:
```json
{
  "success": true,
  "message": "Chapters fetched successfully",
  "data": [
    {
      "id": "...",
      "chapterId": "chapter_1",
      "title": "Introduction to Programming",
      "description": "...",
      "videoUrl": "...",
      "duration": 596,
      "quiz": {
        "questions": [...]
      },
      "order": 1
    }
  ]
}
```

#### 4. Get User Progress
```http
GET /api/progress/{userId}
```

Response:
```json
{
  "success": true,
  "progress": [
    {
      "id": "...",
      "userId": "user123",
      "chapterId": "chapter_1",
      "videoProgress": 120,
      "videoCompleted": false,
      "quizProgress": 2,
      "quizAnswers": [0, 2, -1, -1, -1],
      "quizCompleted": false,
      "chapterCompleted": false,
      "lastAccessedAt": "...",
      "updatedAt": "..."
    }
  ]
}
```

#### 5. Update Video Progress
```http
POST /api/progress/video
Content-Type: application/json

{
  "userId": "user123",
  "chapterId": "chapter_1",
  "progress": 120,
  "completed": false
}
```

#### 6. Update Quiz Progress
```http
POST /api/progress/quiz
Content-Type: application/json

{
  "userId": "user123",
  "chapterId": "chapter_1",
  "questionIndex": 2,
  "answer": 1,
  "completed": false
}
```

#### 7. Reset Progress
```http
DELETE /api/progress/{userId}/reset
```

## 📁 Project Structure

```
LearningApp/
├── backend/
│   ├── main.go                 # Main backend application
│   ├── go.mod                  # Go dependencies
│   ├── Dockerfile              # Docker configuration
│   ├── docker-compose.yml      # Docker Compose setup
│   └── .env.example            # Environment variables template
│
└── frontend/
    ├── lib/
    │   ├── main.dart           # App entry point
    │   ├── models/             # Data models
    │   │   ├── user.dart
    │   │   ├── chapter.dart
    │   │   └── progress.dart
    │   ├── providers/          # State management
    │   │   └── app_provider.dart
    │   ├── screens/            # UI screens
    │   │   ├── login_screen.dart
    │   │   ├── home_screen.dart
    │   │   ├── video_player_screen.dart
    │   │   └── quiz_screen.dart
    │   ├── services/           # API & Storage services
    │   │   ├── api_service.dart
    │   │   └── storage_service.dart
    │   ├── widgets/            # Reusable widgets
    │   │   ├── chapter_card.dart
    │   │   └── continue_card.dart
    │   └── utils/              # Utilities & constants
    │       └── app_colors.dart
    └── pubspec.yaml            # Flutter dependencies
```

## 🎯 Design Decisions

### 1. **Automatic Progress Saving**
- Video progress is saved every 5 seconds while playing
- Quiz progress is saved immediately after each answer
- Prevents data loss if app crashes or user exits unexpectedly

### 2. **Resume Logic**
- Video: Resumes from exact second using `VideoPlayerController.seekTo()`
- Quiz: Restores question index and previous answers
- Backend stores timestamp and question index separately

### 3. **State Management**
- Used Provider for simplicity and efficiency
- Single AppProvider manages global app state
- Local state for screen-specific UI

### 4. **Data Synchronization**
- Pull-based synchronization: App fetches latest data on startup
- Push-based updates: Progress is pushed to server immediately
- Cross-device support: Same user ID works across all devices

### 5. **User Experience**
- Loading indicators for async operations
- Error handling with user-friendly messages
- Offline-first approach with local storage backup
- Progress visualization with percentage and status

### 6. **Database Design**
- Separate collections for Users, Chapters, Progress
- Compound index on (userId, chapterId) for fast progress lookup
- Upsert operations to handle create/update in one call

## 🛡 Edge Cases Handled

### 1. **First Time User**
- No progress exists → Returns empty progress
- Starts from beginning (video: 0 seconds, quiz: question 0)

### 2. **User Switches Devices**
- Progress synced from database
- Latest progress displayed on new device

### 3. **Video Completion**
- Detects when video reaches end
- Marks video as completed
- Enables quiz access

### 4. **Quiz Mid-Completion**
- Saves answer for each question immediately
- Can navigate back/forward between questions
- Resumes at exact question on return

### 5. **Network Errors**
- Graceful error handling with retry options
- Local storage fallback for user credentials
- Error messages guide user to resolution

### 6. **Concurrent Updates**
- Last-write-wins strategy
- MongoDB upsert prevents duplicate records
- Timestamp tracks latest update

### 7. **Invalid Data**
- Input validation on both frontend and backend
- Required field checks
- Data type validation

### 8. **Video Player Errors**
- Error detection and user notification
- Fallback UI with retry option
- Handles network video loading failures

## 🔄 Testing Scenarios

### Test Case 1: Resume Video
1. Login as user "test1"
2. Start Chapter 1 video
3. Watch for 30 seconds
4. Close app
5. Reopen app and login as "test1"
6. Open Chapter 1
7. ✅ Video should resume at 30 seconds

### Test Case 2: Resume Quiz
1. Login as user "test2"
2. Complete Chapter 1 video
3. Start quiz and answer 2 questions
4. Close app
5. Reopen and login as "test2"
6. Open Chapter 1 quiz
7. ✅ Should resume at question 3

### Test Case 3: Cross-Device Sync
1. Login as "test3" on Device A
2. Watch video until 1:00
3. Login as "test3" on Device B
4. ✅ Video shows progress at 1:00

### Test Case 4: Multiple Users
1. Login as "user1", make progress
2. Logout and login as "user2"
3. ✅ "user2" starts from scratch
4. Logout and login back as "user1"
5. ✅ "user1" sees their previous progress

## 🚀 Future Improvements

### Features
- [ ] User profiles with avatars
- [ ] Bookmarking specific video timestamps
- [ ] Notes and highlights
- [ ] Downloadable certificates
- [ ] Social features (share progress, leaderboards)
- [ ] Content recommendations
- [ ] Offline video downloads
- [ ] Multiple video quality options
- [ ] Subtitle support

### Technical
- [ ] WebSocket for real-time updates
- [ ] JWT authentication
- [ ] Redis caching layer
- [ ] Video streaming optimization
- [ ] Analytics and tracking
- [ ] Unit and integration tests
- [ ] CI/CD pipeline
- [ ] Performance monitoring
- [ ] Rate limiting
- [ ] API versioning

### UX
- [ ] Dark mode
- [ ] Accessibility improvements
- [ ] Animations and transitions
- [ ] Onboarding tutorial
- [ ] In-app notifications
- [ ] Search functionality
- [ ] Filtering and sorting

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.


---

**Note**: This is an assignment project showcasing full-stack development skills with Flutter, Go, and MongoDB.