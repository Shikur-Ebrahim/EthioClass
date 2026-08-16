class PaymentModel {
  final String txRef;
  final String status;
  final String? authUrl;

  PaymentModel({
    required this.txRef,
    required this.status,
    this.authUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      txRef: json['tx_ref'] ?? '',
      status: json['status'] ?? 'pending',
      authUrl: json['auth_url'],
    );
  }
}

enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
  expired,
  refunded,
  unknown
}

PaymentStatus parsePaymentStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending': return PaymentStatus.pending;
    case 'processing': return PaymentStatus.processing;
    case 'success': return PaymentStatus.success;
    case 'failed': return PaymentStatus.failed;
    case 'cancelled': return PaymentStatus.cancelled;
    case 'expired': return PaymentStatus.expired;
    case 'refunded': return PaymentStatus.refunded;
    default: return PaymentStatus.unknown;
  }
}
