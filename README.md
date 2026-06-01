# monitorbg

## Kitchen Owner

### 1. Struktur Firestore Report
Saat membuat laporan, gunakan struktur field berikut:

```
await FirebaseFirestore.instance.collection('reports').add({
  'kitchenId':          '...',
  'kitchenName':        '...',
  'ownerUid':           FirebaseAuth.instance.currentUser!.uid,
  'date':               Timestamp.fromDate(DateTime.now()),
  'menuItems': [
    {'name': 'Nasi Putih', 'portionCount': 50},
  ],
  'totalBeneficiaries': 100,
  'distributionTime':   '10:00',
  'proofImageUrls':     [], // diisi setelah upload MinIO
  'status':             'draft',
  'rejectionReason':    null,
  'verifiedBy':         null,
  'verifiedAt':         null,
  'isHoliday':          false, // diisi oleh Dev 3
  'createdAt':          FieldValue.serverTimestamp(),
  'updatedAt':          FieldValue.serverTimestamp(),
});
```

### 2. Upload Foto Bukti ke MinIO
```
import '../services/minio_service.dart';

final objectPath = await MinioService().uploadFile(
  objectPath: 'reports/$kitchenId/${DateTime.now().millisecondsSinceEpoch}.jpg',
  fileStream: Stream.value(Uint8List.fromList(imageBytes)),
);
// Simpan objectPath ke field proofImageUrls di Firestore
```

### 3. Jadwalkan Reminder Saat Login
```
import '../services/notification_service.dart';

await NotificationService().scheduleDailyReminder();
```

### 4. Cancel Reminder Saat Laporan Disubmit
```
await NotificationService().cancelReminder();
```

### 5. Ganti Placeholder di `main.dart`
```dart
// Sekarang
// TODO: replace with KitchenOwnerShell

// Ganti dengan
return const KitchenOwnerShell();
```

---

## Holiday API

### 1. Cancel Reminder Jika Hari Libur
```
import '../services/notification_service.dart';

final isHoliday = await HolidayService().checkIsHoliday(DateTime.now());
if (isHoliday) await NotificationService().cancelReminder();
```

### 2. Isi Field `isHoliday` Saat Laporan Dibuat
Field ini diimplementasi oleh Dev 1 di create report screen,
nilai `isHoliday`-nya diambil dari service milik Dev 3:

```
'isHoliday': await HolidayService().checkIsHoliday(DateTime.now()),
```