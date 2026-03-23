import 'helpers.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String method;
  final double amount;
  final String status;
  final String? transactionId;
  final String createdAt;
  final String updatedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.status,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'].toString(),
      orderId: json['order']?.toString() ?? json['order_id']?.toString() ?? '',
      method: json['method'] ?? json['payment_method'] ?? '',
      amount: toSafeDouble(json['amount']),
      status: json['status'] ?? '',
      transactionId: json['transaction_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'method': method,
      'amount': amount,
      'status': status,
      'transaction_id': transactionId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
