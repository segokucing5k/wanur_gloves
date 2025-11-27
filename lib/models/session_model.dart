class SessionModel {
  final int? id; // ID Unik (Auto Increment)
  final double kg;
  final String date; // Disimpan sebagai String ISO8601
  final String duration;
  final String status; // "Good", "Weak", "Stable"

  SessionModel({
    this.id,
    required this.kg,
    required this.date,
    required this.duration,
    required this.status,
  });

  // Mengubah Object jadi Map (Supaya bisa masuk ke SQL)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kg': kg,
      'date': date,
      'duration': duration,
      'status': status,
    };
  }

  // Mengubah Map jadi Object (Supaya bisa dibaca Flutter)
  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'],
      kg: map['kg'],
      date: map['date'],
      duration: map['duration'],
      status: map['status'],
    );
  }
}