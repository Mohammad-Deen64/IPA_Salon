class Appointment {
  const Appointment({
    required this.id,
    required this.salonId,
    required this.salonName,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    this.customerId = '',
    this.duration = 0,
    this.arriveBy,
    this.waitMinutes,
  });

  final String id;
  final String salonId;
  final String salonName;
  final String serviceName;
  final String date;
  final String time;
  final double price;
  final String status;
  final String customerName;
  final String customerPhone;
  final String customerId;
  final int duration;
  final String? arriveBy;
  final int? waitMinutes;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      salonId: json['salon_id'] as String,
      salonName: json['salon_name'] as String,
      serviceName: json['service_name'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      arriveBy: json['arrive_by'] as String?,
      waitMinutes: (json['wait_minutes'] as num?)?.toInt(),
    );
  }
}
