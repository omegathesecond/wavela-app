# YeboVerify - KYC Android App for Eswatini

A secure KYC (Know Your Customer) verification application built with Flutter for Android devices, featuring OCR document scanning, biometric verification, and fingerprint authentication.

## 🚀 Features

### Core KYC Flow
- **Document Scanning**: OCR-powered ID card extraction (front & back)
- **Face Matching**: Selfie comparison with ID photo
- **Liveness Detection**: Anti-spoofing measures
- **Fingerprint Verification**: External reader support with deduplication
- **Secure Processing**: End-to-end encrypted verification pipeline

### Technical Highlights
- **GetX Architecture**: Reactive state management and dependency injection
- **Offline Capability**: Data capture works without internet connection
- **Biometric Security**: Face and fingerprint template matching
- **Quality Assurance**: Real-time image and data quality checks
- **Compliance Ready**: Audit trails and regulatory compliance features

## 📱 App Structure

```
lib/
├── core/
│   ├── bindings/         # Dependency injection
│   ├── theme/           # App theming
│   └── utils/           # Routes and utilities
├── data/
│   ├── models/          # Data models (User, Fingerprint, etc.)
│   ├── services/        # Core services (Camera, OCR, Biometric, etc.)
│   └── repositories/    # Data layer abstraction
└── presentation/
    ├── controllers/     # GetX controllers
    ├── pages/          # UI screens
    └── widgets/        # Reusable components
```

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK ^3.19.0
- Android SDK (API level 21+)
- Android device with camera
- External fingerprint reader (optional)

### Installation
1. **Clone and Setup**
   ```bash
   cd yebo_verify
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Build for Release**
   ```bash
   flutter build apk --release
   ```

### Required Permissions
The app requests the following permissions:
- Camera access (for document and selfie capture)
- Storage access (for temporary file storage)
- USB access (for external fingerprint readers)

## 🔧 Configuration

### API Integration
Update the base URL in `lib/data/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-api-endpoint.com/v1';
```

### Fingerprint SDK
To integrate with real fingerprint hardware:
1. Add your fingerprint SDK to `android/app/build.gradle`
2. Update `lib/data/services/fingerprint_service.dart` with actual SDK calls
3. Configure device communication protocols

## 📊 KYC Verification Flow

1. **Onboarding**: User introduction and permissions
2. **Document Type**: Select ID type (National ID)
3. **ID Capture**: Front and back scanning with quality checks
4. **OCR Processing**: Text extraction and validation
5. **Selfie Capture**: Face detection with liveness checks
6. **Fingerprint**: Multiple finger capture with quality assessment
7. **Review**: Data verification and user confirmation
8. **Processing**: Backend verification and duplicate checking
9. **Results**: Success/failure with detailed feedback

## 🔐 Security Features

- **AES-256 Encryption**: All data encrypted at rest
- **TLS 1.3**: Secure data transmission
- **Template Storage**: Only biometric templates stored, no raw images
- **Device Binding**: Keys tied to specific devices
- **Audit Logging**: Comprehensive verification trails
- **Anti-Spoofing**: Multiple liveness detection methods

## 📋 Current Status

### ✅ Completed
- Complete Flutter app architecture with GetX
- All KYC verification pages and controllers
- OCR and biometric service integration
- Fingerprint capture and deduplication logic
- Security and storage services
- UI/UX with consistent theming

### 🔄 Next Steps
1. **Hardware Integration**: Connect real fingerprint readers
2. **API Backend**: Implement server-side verification
3. **Testing**: Device and accuracy testing
4. **Deployment**: Play Store publication
5. **Enhancements**: Advanced ML models and additional document types

## 📚 Documentation

- [PRD.md](../PRD.md): Product Requirements Document
- [plan.md](../plan.md): Technical Architecture & Timeline
- [FEATURES.md](../FEATURES.md): Feature Specifications
- [PAGES.md](../PAGES.md): UI Structure Details

## 🤝 Support

For implementation support or questions:
- Technical issues: Review diagnostic messages in your IDE
- Integration help: Consult the service files in `lib/data/services/`
- UI customization: Modify themes in `lib/core/theme/app_theme.dart`

## 📄 License

This KYC verification app is designed for Eswatini regulatory compliance and should be used in accordance with local data protection and financial services regulations.
