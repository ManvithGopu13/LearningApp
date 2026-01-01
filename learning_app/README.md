# Resume Learning Frontend

Flutter mobile application for the Resume Learning platform.

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Android Studio / Xcode
- A running backend server

### Installation

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Platform-Specific Setup

#### Android

1. Open Android Studio
2. Start an emulator or connect a device
3. Run: `flutter run`

#### iOS

1. Open Xcode
2. Start a simulator
3. Run: `flutter run`

## 🔧 Configuration

### Backend URL

Update the API base URL in `lib/services/api_service.dart`:

```dart
// For Android emulator
static const String baseUrl = 'http://10.0.2.2:8080/api';

// For iOS simulator  
static const String baseUrl = 'http://localhost:8080/api';

// For physical device (use your computer's IP)
static const String baseUrl = 'http://192.168.1.XXX:8080/api';
```

To find your computer's IP:
```bash
# macOS/Linux
ifconfig | grep inet

# Windows
ipconfig
```

## 📱 App Structure

```
lib/
├── main.dart                    # Entry point
├── models/                      # Data models
│   ├── user.dart
│   ├── chapter.dart
│   └── progress.dart
├── providers/                   # State management
│   └── app_provider.dart
├── screens/                     # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── video_player_screen.dart
│   └── quiz_screen.dart
├── services/                    # API services
│   ├── api_service.dart
│   └── storage_service.dart
├── widgets/                     # Reusable widgets
│   ├── chapter_card.dart
│   └── continue_card.dart
└── utils/                       # Utilities
    └── app_colors.dart
```

## 🎨 Features

### 1. Login Screen
- Simple user authentication
- Persistent login state
- Beautiful gradient UI

### 2. Home Screen
- Chapter list with progress
- Continue card for resuming
- User profile display
- Pull-to-refresh
- Logout functionality

### 3. Video Player Screen
- Resume from last position
- Auto-save progress every 5 seconds
- Full-screen support
- Video controls
- Progress tracking

### 4. Quiz Screen
- Multiple choice questions
- Resume from last question
- Answer tracking
- Real-time progress save
- Results screen with score
- Question navigation

## 🔑 Key Components

### State Management (Provider)

```dart
// Access provider
final provider = Provider.of<AppProvider>(context);

// Update state
provider.loadChapters();
provider.updateVideoProgress(...);
```

### API Service

```dart
final apiService = ApiService();

// Login
await apiService.login(userId, name);

// Get chapters
final chapters = await apiService.getChapters();

// Update progress
await apiService.updateVideoProgress(...);
```

### Storage Service

```dart
final storage = StorageService();

// Save user
await storage.saveUser(user);

// Get user
final user = await storage.getUser();

// Logout
await storage.clearUser();
```

## 🎯 Core Functionality

### Resume Video Logic

```dart
// 1. Get saved progress
final progress = await getChapterProgress(userId, chapterId);

// 2. Resume from timestamp
_videoPlayerController.seekTo(
  Duration(seconds: progress.videoProgress)
);

// 3. Auto-save every 5 seconds
Timer.periodic(Duration(seconds: 5), (timer) {
  final currentPos = _videoPlayerController.value.position.inSeconds;
  updateVideoProgress(chapterId, currentPos, false);
});

// 4. Mark complete when finished
if (position >= duration) {
  updateVideoProgress(chapterId, position, true);
}
```

### Resume Quiz Logic

```dart
// 1. Get saved progress
final progress = await getChapterProgress(userId, chapterId);

// 2. Resume from question index
_currentQuestionIndex = progress.quizProgress;
_answers = progress.quizAnswers;

// 3. Save after each answer
void saveAnswer(int answer) {
  _answers[_currentQuestionIndex] = answer;
  updateQuizProgress(
    chapterId: chapterId,
    questionIndex: _currentQuestionIndex,
    answer: answer,
    completed: isLastQuestion && allAnswered,
  );
}
```

## 🎨 UI/UX Features

### Colors & Theme
- Custom color palette
- Gradient backgrounds
- Material Design 3
- Consistent styling

### Animations
- Smooth transitions
- Loading indicators
- Progress bars
- Card animations

### Responsive Design
- Adapts to screen sizes
- Safe areas handled
- Keyboard awareness

## 🧪 Testing

### Manual Testing

1. **Test Login**
   ```
   - Enter userId: "test1"
   - Verify login successful
   - Check home screen loads
   ```

2. **Test Video Resume**
   ```
   - Play video for 30 seconds
   - Close app
   - Reopen and login
   - Verify video resumes at 30s
   ```

3. **Test Quiz Resume**
   ```
   - Answer 2 questions
   - Close app
   - Reopen and login
   - Verify quiz resumes at question 3
   ```

4. **Test Cross-Device**
   ```
   - Login on Device A
   - Make progress
   - Login on Device B
   - Verify same progress
   ```

### Test Users

Create these test users:
- `test1` - For video testing
- `test2` - For quiz testing
- `test3` - For cross-device testing

## 🐛 Common Issues

### 1. Cannot Connect to Backend

**Problem**: App can't reach backend API

**Solutions**:
- Check backend is running: `curl http://localhost:8080/api/health`
- Verify correct URL in `api_service.dart`
- For Android: Use `10.0.2.2` not `localhost`
- For physical device: Use computer's IP address
- Check firewall settings

### 2. Video Won't Play

**Problem**: Video player shows error

**Solutions**:
- Check internet connection
- Verify video URL is accessible
- Check video format compatibility
- View logs: `flutter logs`

### 3. Progress Not Saving

**Problem**: Progress resets after closing app

**Solutions**:
- Check network connection
- Verify backend is receiving requests
- Check browser console for errors
- Verify MongoDB is running

### 4. Build Errors

**Problem**: Flutter build fails

**Solutions**:
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Update Flutter
flutter upgrade

# Check for issues
flutter doctor
```

## 📦 Dependencies

### Core
- `flutter`: SDK
- `provider`: State management

### UI
- `google_fonts`: Custom fonts
- `cupertino_icons`: iOS icons

### Video
- `video_player`: Video playback
- `chewie`: Video player UI

### Network
- `http`: HTTP client

### Storage
- `shared_preferences`: Local storage

### Utilities
- `intl`: Internationalization

## 🚀 Build & Deploy

### Android APK

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

### iOS App

```bash
# Build iOS
flutter build ios --release

# Or open in Xcode
open ios/Runner.xcworkspace
```

### App Bundle (Play Store)

```bash
flutter build appbundle --release
```

## 📊 Performance

### Optimization Tips

1. **Video Loading**
   - Use appropriate video quality
   - Implement video caching
   - Show loading indicators

2. **Network Calls**
   - Implement request debouncing
   - Cache API responses
   - Handle offline mode

3. **State Management**
   - Use `const` constructors
   - Minimize rebuilds
   - Use `Consumer` wisely

4. **Images & Assets**
   - Optimize image sizes
   - Use lazy loading
   - Cache network images

## 🎨 Customization

### Change Colors

Edit `lib/utils/app_colors.dart`:

```dart
class AppColors {
  static const Color primary = Color(0xFF6C5CE7);
  // Change to your brand color
  static const Color primary = Color(0xFFYOURCOLOR);
}
```

### Add New Screen

1. Create file in `lib/screens/`
2. Add route navigation
3. Update state if needed

### Modify Video Player

Edit `lib/screens/video_player_screen.dart`:
- Change controls
- Add features
- Customize UI

## 📝 Code Style

### Follow Flutter Best Practices

- Use `const` constructors
- Avoid nested ternaries
- Use meaningful names
- Add comments for complex logic
- Handle null safety
- Catch exceptions

### Example

```dart
// Good ✅
const Text('Hello', style: TextStyle(fontSize: 16))

// Bad ❌
Text('Hello', style: TextStyle(fontSize: 16))
```

## 🤝 Contributing

1. Follow Flutter style guide
2. Test on both Android & iOS
3. Update documentation
4. Add comments
5. Create pull request

## 📄 License

MIT License

## 📞 Support

For issues:
1. Check this README
2. Check Flutter docs
3. Open an issue on GitHub

---

Happy Coding! 🚀