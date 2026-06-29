# BetterUS Mobile

Ứng dụng di động của hệ thống **BetterUS** — nền tảng kết nối tình nguyện viên với người có hoàn cảnh khó khăn tại TP. Hồ Chí Minh.

Được xây dựng bằng **Flutter**, hỗ trợ cả Android và iOS.

---

## Tính năng chính

### Xác thực & Hồ sơ
- Đăng ký / Đăng nhập với JWT
- Chọn vai trò: Tình nguyện viên hoặc Người thụ hưởng
- Thiết lập hồ sơ cá nhân đầy đủ (ảnh đại diện, kỹ năng, thông tin liên hệ)

### Yêu cầu hỗ trợ (Người thụ hưởng)
- Tạo yêu cầu cần giúp đỡ theo nhiều danh mục: giáo dục, y tế, thực phẩm, nhà ở, đi lại...
- Theo dõi trạng thái yêu cầu theo thời gian thực
- Nhận phản hồi và đánh giá từ tình nguyện viên

### Hoạt động tình nguyện
- Xem và đăng ký tham gia các hoạt động, chiến dịch
- Bản đồ hiển thị vị trí các hoạt động (Google Maps)
- Theo dõi lịch sử đóng góp và điểm thưởng
- Nhận chứng chỉ tình nguyện

### Nhắn tin & Thông báo
- Chat trực tiếp với tình nguyện viên / người thụ hưởng qua Socket.IO
- Thông báo thời gian thực

### Khẩn cấp
- Gửi yêu cầu khẩn cấp với mức độ ưu tiên cao

---

## 🛠 Công nghệ sử dụng

| Thư viện | Mục đích |
|---|---|
| `flutter` | Framework UI đa nền tảng |
| `dio` | HTTP client nâng cao |
| `socket_io_client` | Kết nối WebSocket (chat real-time) |
| `google_maps_flutter` | Hiển thị bản đồ |
| `flutter_map` + `latlong2` | Bản đồ (fallback) |
| `flutter_secure_storage` | Lưu trữ token bảo mật |
| `shared_preferences` | Lưu trữ dữ liệu nhẹ |
| `image_picker` | Chọn ảnh từ thư viện / camera |
| `flutter_image_compress` | Nén ảnh trước khi upload |
| `google_fonts` | Font chữ (Roboto) |
| `flutter_animate` | Hiệu ứng animation |
| `shimmer` | Loading skeleton effect |
| `intl` | Định dạng ngày giờ (vi_VN) |
| `permission_handler` | Quản lý quyền hệ thống |
| `url_launcher` | Mở link / gọi điện |
| `gal` | Lưu ảnh vào thư viện |
| `flutter_dotenv` | Đọc biến môi trường |

---

## Hướng dẫn cài đặt & chạy

### 1. Clone repository và vào thư mục

```bash
cd mobile
```

### 2. Cấu hình biến môi trường

Tạo file `.env` từ `.env.example`:

```bash
cp .env.example .env
```

Chỉnh sửa file `.env`:

```env
# URL backend (dùng ngrok nếu test trên thiết bị thật)
API_URL=http://10.0.2.2:8080   # Android Emulator
# API_URL=https://xxxx.ngrok-free.app  # Thiết bị thật qua ngrok

GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 3. Cài đặt dependencies

```bash
flutter pub get
```

### 4. Chạy ứng dụng

```bash
# Chạy ở chế độ debug
flutter run

# Chạy trên thiết bị cụ thể
flutter run -d <device_id>

# Xem danh sách thiết bị
flutter devices
```

### 5. Build APK (Android)

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

### 6. Build iOS

```bash
flutter build ios --release
```

---

## Cấu trúc dự án

```
mobile/
├── lib/
│   ├── main.dart               # Entry point
│   ├── data/                   # Dữ liệu toàn cục (notifiers)
│   ├── models/                 # Data models
│   ├── services/               # Giao tiếp với API backend
│   │   ├── auth_service.dart
│   │   ├── request_service.dart
│   │   ├── feedback_service.dart
│   │   ├── emergency_service.dart
│   │   ├── campaign_service.dart
│   │   ├── chat/               # Chat service (Socket.IO)
│   │   └── ...
│   ├── views/
│   │   ├── widget_tree.dart    # Điều hướng chính (auth check)
│   │   ├── welcome_page.dart   # Màn hình chào mừng
│   │   ├── login.dart          # Màn hình đăng nhập
│   │   ├── register.dart       # Màn hình đăng ký
│   │   ├── role_selection_page.dart
│   │   ├── setup_volunteer_profile.dart
│   │   ├── setup_beneficiary_profile.dart
│   │   └── pages/              # Các trang chính
│   │       ├── home/           # Trang chủ
│   │       ├── activities/     # Hoạt động tình nguyện
│   │       ├── chat/           # Nhắn tin
│   │       ├── messages/       # Hộp thư
│   │       ├── emer/           # Khẩn cấp
│   │       └── profile/        # Hồ sơ người dùng
│   ├── helper/                 # Các hàm tiện ích
│   └── utils/                  # Màu sắc, constants
├── assets/
│   ├── images/                 # Hình ảnh tĩnh
│   └── fonts/                  # Font tùy chỉnh
├── android/                    # Cấu hình Android
├── ios/                        # Cấu hình iOS
├── .env                        # Biến môi trường (không commit)
├── .env.example                # Mẫu biến môi trường
└── pubspec.yaml                # Khai báo dependencies
```



## Kết nối với Backend

Ứng dụng mobile kết nối với **Nest_Backend** qua:
- **REST API**: `{API_URL}/api/v1/...`
- **WebSocket**: `{API_URL}` (Socket.IO cho chat real-time)

Nếu chạy backend cục bộ và test trên **Android Emulator**, dùng `http://10.0.2.2:8080`.  
Nếu test trên **thiết bị thật**, dùng **ngrok** để expose port.


