class GeneratedDocument {
  final int id;
  final int template;
  final String templateName;
  final String templateNameSw;
  final String language;
  final String status;
  final String documentTitle;
  final String? generatedFile;
  final String? downloadUrl;
  final bool isPaid;
  final String paymentAmount;
  final int downloadCount;
  final String? lastDownloadedAt;
  final String createdAt;
  final String updatedAt;
  final String? errorMessage;

  GeneratedDocument({
    required this.id,
    required this.template,
    required this.templateName,
    required this.templateNameSw,
    required this.language,
    required this.status,
    required this.documentTitle,
    this.generatedFile,
    this.downloadUrl,
    required this.isPaid,
    required this.paymentAmount,
    required this.downloadCount,
    this.lastDownloadedAt,
    required this.createdAt,
    required this.updatedAt,
    this.errorMessage,
  });

  factory GeneratedDocument.fromJson(Map<String, dynamic> json) {
    return GeneratedDocument(
      id: json['id'] as int,
      template: json['template'] as int,
      templateName: json['template_name'] as String,
      templateNameSw: json['template_name_sw'] as String,
      language: json['language'] as String,
      status: json['status'] as String,
      documentTitle: json['document_title'] as String,
      generatedFile: json['generated_file'] as String?,
      downloadUrl: json['download_url'] as String?,
      isPaid: json['is_paid'] as bool,
      paymentAmount: json['payment_amount'] as String,
      downloadCount: json['download_count'] as int,
      lastDownloadedAt: json['last_downloaded_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      errorMessage: json['error_message'] as String?,
    );
  }

  bool get isFree => isPaid && paymentAmount == '0.00';

  bool get canDownload =>
      status == 'completed' && downloadUrl != null && isFree;

  bool get needsPayment => status == 'completed' && !isFree && !isPaid;

  String getStatusLabel() {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  String getFormattedDate() {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }
}
