# Performance Optimization Guide

## Vấn đề hiện tại:
1. **Skipped frames**: App bị drop frame gây lag
2. **Mouse tracker errors**: Lỗi chuột tracking
3. **Firebase Storage lỗi**: Upload ảnh thất bại
4. **Memory issues**: Base64 images quá lớn
5. **Connection lost**: Mất kết nối với device

## Đã sửa:

### 1. Main.dart Optimization
- Chuyển Google Sign In init thành non-blocking
- Thêm lazy loading cho providers
- Thêm MediaQuery optimization
- Thêm Material3 theme với visual density

### 2. Profile Screen Optimization
- Giảm kích thước base64 image limit
- Tránh update Firebase Auth với base64 URLs
- Cải thiện error handling
- Thêm file size validation

### 3. Build Optimization
- Clean build cache
- Refresh dependencies

## Cần làm thêm:

### 1. Giảm animations/effects không cần thiết
### 2. Tối ưu hóa image loading
### 3. Cải thiện network handling
### 4. Memory management

## Commands để run app tối ưu:

```bash
# Clean và rebuild
flutter clean
flutter pub get

# Run với profile mode (better performance)
flutter run --profile

# Hoặc release mode (best performance nhưng không debug được)
flutter run --release
```

## Firebase Storage Setup:
1. Vào Firebase Console
2. Setup Storage rules như trong FIREBASE_STORAGE_RULES.md
3. Hoặc tạm thời dùng base64 fallback (đã implement)

## Monitoring Performance:
- Use Flutter DevTools để monitor performance
- Check memory usage
- Monitor frame rendering times
