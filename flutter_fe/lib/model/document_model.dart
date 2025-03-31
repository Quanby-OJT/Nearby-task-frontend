class DocumentInfo {
  final String? tesdaDocumentLink;
  final bool valid;

  DocumentInfo({this.tesdaDocumentLink, required this.valid});

  // Optional: Factory constructor to create from a map
  factory DocumentInfo.fromMap(Map<String, dynamic> map) {
    return DocumentInfo(
      tesdaDocumentLink: map['tesda_document_link'] as String?,
      valid: map['valid'] as bool,
    );
  }
}
