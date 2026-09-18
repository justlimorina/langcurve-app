# LangCurve - Ứng dụng Học Từ Vựng Tiếng Anh MD3 (Flutter)

> Ứng dụng học từ vựng tiếng Anh theo phương pháp lặp lại ngắt quãng (**Spaced Repetition System - SuperMemo SM-2**), tích hợp **Từ điển thông minh**, **Phát âm kép UK/US**, **Dịch nghĩa tự động**, **Kiểm tra ngữ pháp qua LanguageTool**, **Đường cong học tập (Curve Analytics)** và **Video bài học BBC Learning English**.
> 
> Hỗ trợ đầy đủ đa nền tảng: **Windows Desktop**, **Android**, và **iOS**. Thiết kế chuẩn mực theo ngôn ngữ **Material Design 3 (MD3)** của Google với bảng màu "Tím đất" (`#8D437F`).

---

## 🌟 Tính năng kế thừa trọn vẹn từ [justlimorina/langcurve](https://github.com/justlimorina/langcurve.git)

### 1. 🔍 Từ điển thông minh (Smart Dictionary Engine)
- **Bộ phân tích hình thái (Morphology Lemmatizer):** Nhận diện dạng thì quá khứ, phân từ, số nhiều, so sánh hơn/nhất của động từ, danh từ, tính từ bất quy tắc (`went` ➔ `go`, `children` ➔ `child`, `better` ➔ `good`) và quy tắc biến hình đuôi (`-ing`, `-ed`, `-ies`, `-s`, `-es`).
- **Tra cứu trực tuyến:** Truy vấn Free Dictionary API kết hợp cơ chế fallback dự phòng Google TTS.
- **Phát âm chuẩn kép:** Cung cấp cả ký hiệu phiên âm quốc tế (IPA) và nút nghe phát âm trực tiếp của cả hai giọng:
  - 🇬🇧 **Anh - Anh (UK)**
  - 🇺🇸 **Anh - Mỹ (US)**
- **Phân loại cấp độ CEFR:** Tự động gán nhãn khung tham chiếu Châu Âu từ A1 đến C2 (`A1`, `A2`, `B1`, `B2`, `C1`, `C2`).
- **Dịch song ngữ Anh - Việt:** Tự động dịch nghĩa tiếng Việt cho từ chính và từng câu định nghĩa thông qua Google Translate API & MyMemory.
- **Từ đồng nghĩa & Trái nghĩa:** Trích xuất tự động danh sách từ liên quan để làm giàu vốn từ.
- **Lưu vào Notebook 1 chạm:** Chọn chủ đề hoặc tạo chủ đề mới để lưu từ vào sổ tay ngay lập tức.

### 2. 🧠 Hệ thống Lặp lại ngắt quãng (SuperMemo SM-2 SRS)
- Thuật toán SuperMemo-2 tính toán thời gian ôn tập lý tưởng dựa trên hệ số dễ (**Easiness Factor - EF**), số lần đúng liên tiếp (**Repetitions**) và khoảng cách ngày (**Interval**).
- **Thanh đánh giá 4 mức trực quan:**
  - **Chưa nhớ (0):** Đặt lại chu kỳ về 1 ngày, giảm điểm EF.
  - **Khó (3):** Ghi nhận vượt qua, điều chỉnh EF, cộng **+10 XP**.
  - **Tốt (4):** Bảo toàn chu kỳ ôn tập, cộng **+10 XP**.
  - **Rất dễ (5):** Tăng tốc khoảng cách ôn tập, cộng **+20 XP**.
- **Đếm ngược thời gian ôn tập:** Hiển thị trạng thái "Đến hạn ôn tập", "Còn X giờ", "Còn Y ngày" theo thời gian thực.
- **2 Chế độ luyện tập:**
  - Ôn tập tập trung các từ **đến hạn (SRS Due)**.
  - Ôn tập theo **chủ đề cụ thể** hoặc toàn bộ sổ tay.

### 3. ✍️ Rèn luyện Đặt câu & Kiểm tra ngữ pháp (Grammar Checker)
- Khi ôn tập thẻ từ, ứng dụng khuyến khích người dùng tự viết một câu ví dụ tiếng Anh có chứa từ vựng đang học.
- **Kiểm tra từ khóa thời gian thực:** Thông báo ngay lập tức xem câu của bạn đã chứa từ vựng (hoặc dạng chia thì của từ đó) hay chưa.
- **Tích hợp LanguageTool API:** Bấm "Kiểm tra ngữ pháp" để phân tích lỗi chính tả, ngữ pháp của câu và đưa ra đề xuất sửa lỗi chi tiết.

### 4. 📈 Đường cong học tập (Curve Analytics)
- Thống kê dữ liệu chuỗi thời gian (Time-series) của tất cả các lần ôn tập vào bảng `review_logs`.
- Biểu đồ tương tác thời gian thực (`fl_chart`):
  - Đường hiển thị **số lượt ôn tập / từ vựng đã học** theo từng ngày.
  - Đường nét đứt hiển thị tiến trình biến thiên của **hệ số dễ trung bình (Average EF)**.

### 5. 📺 Video học tập BBC Learning English
- Tự động đồng bộ các video mới nhất từ kênh chính thức **BBC Learning English** thông qua YouTube RSS Feed.
- Thẻ video hiển thị ảnh thu nhỏ (thumbnail), tiêu đề, mô tả bài học và nút phát trực tiếp trên YouTube.

### 6. 📁 Sổ tay từ vựng & Quản lý chủ đề (Notebook)
- Tạo chủ đề không giới hạn, phân loại từ vựng khoa học.
- Tìm kiếm từ vựng nhanh chóng trong từng chủ đề.
- Chỉnh sửa câu ví dụ cá nhân, xóa từ vựng, quản lý tiến trình.

### 7. 💾 Sao lưu & Phục hồi toàn diện (JSON Backup & Restore)
- Xuất toàn bộ tiến trình học tập (Điểm XP, Chủ đề, Từ vựng, Lịch sử ôn tập) ra file `.json` để lưu giữ an toàn.
- Khôi phục tiến trình từ file sao lưu với cơ chế cảnh báo ghi đè an toàn.

### 8. 🎨 Giao diện Material Design 3 (MD3) thích ứng
- Bảng màu **Tím đất** (`#8D437F`) nguyên bản từ LangCurve web app.
- Hỗ trợ đầy đủ **Chế độ Sáng (Light Mode)** và **Chế độ Tối (Dark Mode)**.
- **Responsive Layout:**
  - Màn hình rộng (Windows Desktop / Tablet ngang): Sử dụng thanh bên `NavigationRail`.
  - Màn hình nhỏ (Android / iOS điện thoại): Sử dụng thanh đáy `NavigationBar`.

---

## 🛠 Cấu trúc thư mục mã nguồn

```
d:\langcurve-app\
├── pubspec.yaml                           # Khai báo thư viện & dependencies
├── README.md                              # Tài liệu hướng dẫn
├── lib/
│   ├── main.dart                          # Khởi chạy ứng dụng & Thiết lập MultiProvider
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart         # Free Dictionary, Google Translate, LanguageTool, BBC RSS
│   │   │   └── app_constants.dart         # Hằng số, điểm XP, danh mục chủ đề mẫu
│   │   ├── theme/
│   │   │   ├── color_schemes.dart         # Bảng màu MD3 Tím đất Light & Dark
│   │   │   └── app_theme.dart             # Cấu hình ThemeData chuẩn MD3
│   │   └── utils/
│   │       ├── lemmatizer.dart            # Phân tích hình thái từ bất quy tắc & tiếp vĩ ngữ
│   │       └── cefr_classifier.dart       # Phân loại cấp độ CEFR A1 - C2
│   ├── models/
│   │   ├── topic.dart                     # Model Chủ đề học
│   │   ├── vocabulary.dart                # Model Từ vựng kèm tham số SM-2
│   │   ├── review_log.dart                # Model Lịch sử ôn tập
│   │   ├── user_profile.dart              # Model Điểm kinh nghiệm XP & cấp bậc
│   │   ├── dictionary_entry.dart          # Model Chi tiết kết quả tra từ điển
│   │   ├── curve_data_point.dart          # Model Điểm dữ liệu biểu đồ học tập
│   │   ├── bbc_video.dart                 # Model Video BBC Learning English
│   │   └── grammar_match.dart             # Model Kết quả kiểm tra lỗi ngữ pháp
│   ├── services/
│   │   ├── database_service.dart          # SQLite cục bộ (hỗ trợ Windows FFI + Mobile)
│   │   ├── dictionary_service.dart        # Tra cứu từ điển & tự động dịch nghĩa
│   │   ├── translation_service.dart       # Dịch thuật Google Translate & MyMemory
│   │   ├── srs_service.dart               # Thuật toán SuperMemo SM-2 & cộng điểm XP
│   │   ├── tracking_service.dart          # Thống kê Time-series đường cong học tập
│   │   ├── grammar_service.dart           # LanguageTool API kiểm tra ngữ pháp
│   │   ├── bbc_service.dart               # Đồng bộ video YouTube RSS của BBC
│   │   ├── audio_service.dart             # Trình phát âm thanh UK & US
│   │   └── backup_service.dart            # Xuất / Nhập file JSON sao lưu
│   ├── providers/
│   │   ├── app_state_provider.dart        # Quản lý State toàn cục ứng dụng
│   │   └── theme_provider.dart            # Quản lý chuyển đổi giao diện Sáng / Tối
│   ├── views/
│   │   ├── dashboard/                     # Màn hình Dashboard (Thống kê, Biểu đồ, Video)
│   │   ├── dictionary/                    # Màn hình Tra từ điển thông minh
│   │   ├── notebook/                      # Màn hình Quản lý chủ đề & Thẻ từ
│   │   ├── practice/                      # Màn hình Ôn tập Flashcard + SM-2
│   │   └── settings/                      # Hộp thoại Cài đặt & Sao lưu
│   └── widgets/
│       ├── responsive_scaffold.dart       # Khung layout thích ứng Desktop / Mobile
│       ├── cefr_badge.dart                # Huy hiệu CEFR phong cách MD3
│       └── audio_button.dart              # Nút phát âm thanh giọng UK / US
├── android/                               # Cấu hình dự án Android
├── ios/                                   # Cấu hình dự án iOS
└── windows/                               # Cấu hình dự án Windows Desktop
```

---

## 🚀 Hướng dẫn cài đặt & Khởi chạy

### 1. Chuẩn bị môi trường
- Đảm bảo máy tính đã cài đặt **Flutter SDK** (>= 3.0.0). Nếu chưa có, bạn tải tại: [flutter.dev](https://flutter.dev).
- Thêm đường dẫn `flutter/bin` vào biến môi trường **PATH** của hệ thống.

### 2. Cài đặt thư viện dependencies
Mở terminal / PowerShell tại thư mục dự án và chạy:
```bash
cd d:\langcurve-app
flutter pub get
```

### 3. Chạy ứng dụng trên các nền tảng

#### Chạy trên Windows Desktop:
```bash
flutter run -d windows
```

#### Chạy trên thiết bị Android:
```bash
flutter run -d android
```

#### Chạy trên iOS Simulator (trên macOS):
```bash
flutter run -d ios
```

#### Chạy trên trình duyệt Web:
```bash
flutter run -d chrome
```
