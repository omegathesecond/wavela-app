# Wavela KYC API Documentation

## Overview

This document outlines the expected data models and API endpoints needed for the Wavela KYC (Know Your Customer) verification system. The app performs identity verification through document capture, selfie verification, and optional biometric data collection.

## Base URL
```
https://yebo-verify-api-659214682765.europe-west1.run.app
```

## Authentication
All API requests require Bearer token authentication:
```
Authorization: Bearer {token}
```

---

## Data Models

### UserModel
Represents a user undergoing KYC verification.

```json
{
  "id": "string",
  "fullName": "string",
  "idNumber": "string",
  "dateOfBirth": "2024-01-01T00:00:00.000Z",
  "gender": "string",
  "address": "string",
  "phoneNumber": "string",
  "email": "string",
  "idIssueDate": "2024-01-01T00:00:00.000Z",
  "idExpiryDate": "2024-01-01T00:00:00.000Z",
  "idFrontImage": "string (base64 or file path)",
  "idBackImage": "string (base64 or file path)",
  "selfieImage": "string (base64 or file path)",
  "fingerprints": [
    {
      "finger": "string (e.g., 'Right Thumb', 'Left Index')",
      "template": "string (biometric template data)",
      "quality": 0.95,
      "capturedAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "verificationStatus": "pending|in_progress|verified|failed|manual_review",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### JobModel
Represents a verification job with stage tracking.

```json
{
  "id": "string",
  "userId": "string",
  "documentType": "string (e.g., 'National ID', 'Passport', 'Driver License')",
  "status": "pending|in_progress|on_hold|completed|rejected|expired",
  "currentStage": "submitted|document_review|face_verification|fingerprint_analysis|background_check|final_review|completed",
  "stageProgress": [
    {
      "stage": "submitted",
      "isCompleted": true,
      "isActive": false,
      "completedAt": "2024-01-01T00:00:00.000Z",
      "notes": "string (optional)"
    }
  ],
  "userModel": {}, // UserModel object
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z",
  "completedAt": "2024-01-01T00:00:00.000Z", // null if not completed
  "rejectionReason": "string", // null if not rejected
  "progressPercentage": 75
}
```

### JobStage Enum
Available verification stages:
- `submitted` - Job has been submitted
- `document_review` - Reviewing submitted documents
- `face_verification` - Verifying selfie photo
- `fingerprint_analysis` - Analyzing fingerprint biometrics
- `background_check` - Conducting background verification
- `final_review` - Manual review and decision
- `completed` - Verification process completed

### JobStatus Enum
Available job statuses:
- `pending` - Waiting to be processed
- `in_progress` - Currently being processed
- `on_hold` - Temporarily paused
- `completed` - Successfully completed
- `rejected` - Verification failed
- `expired` - Job has expired

### VerificationStatus Enum
- `pending` - Verification not started
- `in_progress` - Verification in process
- `verified` - Successfully verified
- `failed` - Verification failed
- `manual_review` - Requires manual review

---

## API Endpoints

### Authentication

#### POST /auth/login
Login and obtain authentication token.

**Request Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "token": "string",
  "expiresIn": 3600,
  "user": {
    "id": "string",
    "email": "string",
    "role": "string"
  }
}
```

#### POST /auth/logout
Invalidate current authentication token.

**Response:**
```json
{
  "message": "Successfully logged out"
}
```

### Verification Management

#### POST /verifications
Submit a new verification request with all captured data.

**Request Body:**
```json
{
  "documentType": "National ID",
  "fullName": "John Doe",
  "idNumber": "123456789",
  "dateOfBirth": "1990-01-01T00:00:00.000Z",
  "gender": "Male",
  "address": "123 Main St, City",
  "phoneNumber": "+268 1234 5678",
  "email": "john@example.com",
  "idIssueDate": "2020-01-01T00:00:00.000Z",
  "idExpiryDate": "2030-01-01T00:00:00.000Z",
  "idFrontImage": "base64_encoded_image",
  "idBackImage": "base64_encoded_image",
  "selfieImage": "base64_encoded_image",
  "fingerprints": [
    {
      "finger": "Right Thumb",
      "template": "biometric_template_data",
      "quality": 0.95,
      "capturedAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

**Response:**
```json
{
  "id": "VER_1234567890",
  "status": "processing",
  "message": "Verification submitted successfully",
  "submittedAt": "2024-01-01T00:00:00.000Z",
  "jobId": "JOB001"
}
```

#### GET /verifications/{id}
Get verification details by ID.

**Response:**
```json
{
  "id": "string",
  "status": "processing|completed|failed",
  "userModel": {}, // UserModel object
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### Job Management

#### GET /jobs
Get list of verification jobs with filtering and pagination.

**Query Parameters:**
- `status` (optional): Filter by job status
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `sortBy` (optional): Sort field (default: 'createdAt')
- `sortOrder` (optional): 'asc' or 'desc' (default: 'desc')

**Response:**
```json
{
  "jobs": [], // Array of JobModel objects
  "totalCount": 150,
  "currentPage": 1,
  "totalPages": 8,
  "hasNextPage": true,
  "hasPrevPage": false
}
```

#### GET /jobs/{id}
Get specific job details by ID.

**Response:**
```json
{} // JobModel object
```

#### PUT /jobs/{id}/stage
Update job stage progress (Admin/System use).

**Request Body:**
```json
{
  "stage": "document_review",
  "isCompleted": true,
  "notes": "Documents verified successfully"
}
```

**Response:**
```json
{
  "message": "Job stage updated successfully",
  "job": {} // Updated JobModel object
}
```

#### PUT /jobs/{id}/status
Update job status (Admin use).

**Request Body:**
```json
{
  "status": "completed|rejected|on_hold",
  "rejectionReason": "string", // Required if status is 'rejected'
  "notes": "string" // Optional
}
```

**Response:**
```json
{
  "message": "Job status updated successfully",
  "job": {} // Updated JobModel object
}
```

### File Upload

#### POST /files/upload
Upload single file (images, documents).

**Request:** `multipart/form-data`
- `file`: File to upload
- `type`: File type ('id_front', 'id_back', 'selfie', 'document')

**Response:**
```json
{
  "fileId": "string",
  "filename": "string",
  "url": "string",
  "size": 1024576,
  "uploadedAt": "2024-01-01T00:00:00.000Z"
}
```

#### POST /files/upload-multiple
Upload multiple files in a single request.

**Request:** `multipart/form-data`
- `files`: Array of files to upload
- `types`: Array of file types corresponding to each file

**Response:**
```json
{
  "files": [
    {
      "fileId": "string",
      "filename": "string",
      "url": "string",
      "size": 1024576,
      "uploadedAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

### User Management

#### GET /users/{id}
Get user details by ID.

**Response:**
```json
{} // UserModel object
```

#### PUT /users/{id}
Update user information.

**Request Body:**
```json
{} // Partial UserModel object with fields to update
```

**Response:**
```json
{
  "message": "User updated successfully",
  "user": {} // Updated UserModel object
}
```

### Statistics & Reporting

#### GET /stats/dashboard
Get dashboard statistics for admin users.

**Response:**
```json
{
  "totalJobs": 1250,
  "pendingJobs": 45,
  "inProgressJobs": 120,
  "completedJobs": 1000,
  "rejectedJobs": 85,
  "todaysSubmissions": 25,
  "averageProcessingTime": 24.5, // hours
  "successRate": 0.92
}
```

#### GET /stats/processing-times
Get processing time analytics.

**Response:**
```json
{
  "averageByStage": {
    "document_review": 2.5, // hours
    "face_verification": 1.2,
    "fingerprint_analysis": 3.1,
    "background_check": 18.0,
    "final_review": 4.2
  },
  "totalAverageTime": 24.5
}
```

---

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "error": "Bad Request",
  "message": "Invalid request data",
  "details": {
    "field": "validation error message"
  }
}
```

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "Invalid or missing authentication token"
}
```

### 403 Forbidden
```json
{
  "error": "Forbidden",
  "message": "Insufficient permissions to access this resource"
}
```

### 404 Not Found
```json
{
  "error": "Not Found",
  "message": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred"
}
```

---

## Implementation Notes

### File Handling
- Images should be uploaded as base64 encoded strings in the verification submission
- Alternative file upload endpoints are provided for larger files
- Supported image formats: JPEG, PNG
- Maximum file size: 10MB per image
- Images should be compressed before upload to optimize bandwidth

### Biometric Data
- Fingerprint templates should be stored as encrypted binary data
- Quality scores range from 0.0 to 1.0 (higher is better)
- Minimum quality threshold for acceptance: 0.7
- Support for multiple fingerprints per user

### Security Considerations
- All sensitive data should be encrypted at rest
- API endpoints should implement rate limiting
- File uploads should be scanned for malware
- Audit logging for all verification activities
- Data retention policies should be implemented

### Real-time Updates
- Consider implementing WebSocket connections for real-time job status updates
- Push notifications for mobile app when verification status changes
- Webhook support for third-party integrations

### Compliance
- GDPR compliance for data handling
- Data anonymization options
- Right to deletion implementation
- Consent management for data processing