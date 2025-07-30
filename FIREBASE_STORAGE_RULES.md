# Hướng dẫn cấu hình Firebase Storage Rules

## Vấn đề hiện tại
- Lỗi: `Object does not exist at location` và `Code: -13010 HttpResult: 404`
- Nguyên nhân: Quy tắc bảo mật Firebase Storage chưa được cấu hình

## Giải pháp

### 1. Truy cập Firebase Console
- Mở https://console.firebase.google.com
- Chọn project `musicapp-2142f`

### 2. Cấu hình Storage Rules
1. Trong menu bên trái, chọn "Storage"
2. Chọn tab "Rules"
3. Thay thế rules hiện tại bằng:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow users to upload/read their own profile images
    match /profile_images/{userId}_{imageId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Alternative: Allow all authenticated users (less secure but works for testing)
    match /profile_images/{allImages=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3. Test Rules (Tạm thời - chỉ để test)
Nếu vẫn gặp lỗi, có thể dùng rules này tạm thời:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 4. Tạo Storage Bucket (nếu chưa có)
1. Trong Storage, click "Get started"
2. Chọn location gần nhất (asia-southeast1 cho Việt Nam)
3. Chọn "Start in test mode" hoặc cấu hình rules như trên

## Backup Solution (đã implement trong code)
- Nếu Firebase Storage fails, app sẽ tự động dùng Base64 encoding
- Ảnh sẽ được lưu trực tiếp trong Firestore (giới hạn 512KB)

## Kiểm tra
- Sau khi cấu hình, restart app và thử upload ảnh
- Check console log để xem thông tin debug
