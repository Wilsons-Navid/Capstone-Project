import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../presentation/models/education_models.dart';

class CertificateService {
  static const String _certificateTemplate = 'RethicSec Cybersecurity Certificate';
  
  /// Generate a professionally designed certificate for course completion
  static Future<Uint8List> generateCertificate({
    required String userName,
    required EducationCategory category,
    required DateTime completionDate,
    required String certificateId,
    required int totalPoints,
  }) async {
    final pdf = pw.Document();
    
    // Load custom fonts for better presentation
    final boldFont = await PdfGoogleFonts.openSansBold();
    final regularFont = await PdfGoogleFonts.openSansRegular();
    final italicFont = await PdfGoogleFonts.openSansItalic();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape, // Landscape orientation for certificates
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (context) => _buildCertificateContent(
          userName: userName,
          category: category,
          completionDate: completionDate,
          certificateId: certificateId,
          totalPoints: totalPoints,
        ),
      ),
    );
    
    return pdf.save();
  }
  
  /// Build the main certificate content with professional design
  static pw.Widget _buildCertificateContent({
    required String userName,
    required EducationCategory category,
    required DateTime completionDate,
    required String certificateId,
    required int totalPoints,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [
            PdfColor.fromInt(0xFF1E3A8A), // Deep blue
            PdfColor.fromInt(0xFF3B82F6), // Lighter blue
          ],
        ),
      ),
      child: pw.Container(
        margin: const pw.EdgeInsets.all(20),
        padding: const pw.EdgeInsets.all(30),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(15),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColors.grey300,
              offset: const PdfPoint(5, 5),
              blurRadius: 15,
            ),
          ],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Header with logo placeholder and title
            _buildCertificateHeader(),
            
            pw.SizedBox(height: 30),
            
            // Certificate title
            pw.Text(
              'CERTIFICATE OF COMPLETION',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1E3A8A),
                letterSpacing: 2,
              ),
              textAlign: pw.TextAlign.center,
            ),
            
            pw.SizedBox(height: 20),
            
            // Decorative line
            pw.Container(
              width: 200,
              height: 3,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [
                    PdfColor.fromInt(0xFFEF4444), // Red
                    PdfColor.fromInt(0xFFF59E0B), // Yellow
                    PdfColor.fromInt(0xFF10B981), // Green
                  ],
                ),
              ),
            ),
            
            pw.SizedBox(height: 30),
            
            // Main certificate text
            pw.Text(
              'This certifies that',
              style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
            ),
            
            pw.SizedBox(height: 15),
            
            // User name (prominently displayed)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xFF1E3A8A), width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                userName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1E3A8A),
                  letterSpacing: 1.5,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Course completion text
            pw.Text(
              'has successfully completed the cybersecurity training program',
              style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
            
            pw.SizedBox(height: 15),
            
            // Course name
            pw.Text(
              category.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFFEF4444),
              ),
              textAlign: pw.TextAlign.center,
            ),
            
            pw.SizedBox(height: 10),
            
            // Course details
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildCertificateDetail('Modules Completed', '${category.moduleCount}'),
                  _buildCertificateDetail('Duration', category.estimatedTime),
                  _buildCertificateDetail('Difficulty Level', category.difficulty),
                  _buildCertificateDetail('Points Earned', '$totalPoints'),
                ],
              ),
            ),
            
            pw.Spacer(),
            
            // Footer with date, signatures, and certificate ID
            _buildCertificateFooter(completionDate, certificateId),
          ],
        ),
      ),
    );
  }
  
  /// Build certificate header with logo and organization info
  static pw.Widget _buildCertificateHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        // Logo placeholder (you can replace with actual logo)
        pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF1E3A8A),
            borderRadius: pw.BorderRadius.circular(30),
          ),
          child: pw.Center(
            child: pw.Text(
              'R',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        
        pw.SizedBox(width: 15),
        
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'RethicSec',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1E3A8A),
              ),
            ),
            pw.Text(
              'Cybersecurity Education Platform',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.Text(
              'Protecting Africa from Cyber Threats',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey500,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Build individual certificate detail item
  static pw.Widget _buildCertificateDetail(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF1E3A8A),
          ),
        ),
      ],
    );
  }
  
  /// Build certificate footer with date and signatures
  static pw.Widget _buildCertificateFooter(DateTime completionDate, String certificateId) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Date
            pw.Column(
              children: [
                pw.Container(
                  width: 150,
                  height: 1,
                  color: PdfColors.grey400,
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Date of Completion',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  _formatDate(completionDate),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
            
            // Digital signature placeholder
            pw.Column(
              children: [
                pw.Container(
                  width: 150,
                  height: 1,
                  color: PdfColors.grey400,
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Director of Education',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  'RethicSec Team',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Certificate ID and verification
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF1F5F9),
            borderRadius: pw.BorderRadius.circular(20),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'Certificate ID: ',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                certificateId,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 10),
        
        // Verification note
        pw.Text(
          'Verify this certificate at: app.rethicsec.com/verify/${certificateId}',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey500,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  /// Save certificate to device and return file path
  static Future<String> saveCertificateToDevice(Uint8List pdfBytes, String fileName) async {
    Directory directory;
    if (Platform.isAndroid) {
      // Save to Downloads folder on Android
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback to external storage directory
        directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } else {
      // Use Documents directory for other platforms
      directory = await getApplicationDocumentsDirectory();
    }
    
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }
  
  /// Share certificate via sharing sheet
  static Future<void> shareCertificate(Uint8List pdfBytes, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(pdfBytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'I completed my cybersecurity training with RethicSec! 🛡️🎓',
      subject: 'My RethicSec Cybersecurity Certificate',
    );
  }
  
  /// Print certificate directly
  static Future<void> printCertificate(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
  
  /// Generate unique certificate ID
  static String generateCertificateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'CERT-${userId.substring(0, 8).toUpperCase()}-$random';
  }
  
  /// Format date for certificate display
  static String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Certificate data model for storing certificate information
class CertificateData {
  final String id;
  final String userId;
  final String userName;
  final String categoryId;
  final String categoryTitle;
  final DateTime completionDate;
  final int totalPoints;
  final String filePath;
  final bool isShared;
  
  const CertificateData({
    required this.id,
    required this.userId,
    required this.userName,
    required this.categoryId,
    required this.categoryTitle,
    required this.completionDate,
    required this.totalPoints,
    required this.filePath,
    this.isShared = false,
  });
  
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'category_id': categoryId,
      'category_title': categoryTitle,
      'completion_date': completionDate.toIso8601String(),
      'total_points': totalPoints,
      'file_path': filePath,
      'is_shared': isShared,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
  
  factory CertificateData.fromFirestore(Map<String, dynamic> data) {
    return CertificateData(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      categoryId: data['category_id'] ?? '',
      categoryTitle: data['category_title'] ?? '',
      completionDate: DateTime.parse(data['completion_date'] ?? DateTime.now().toIso8601String()),
      totalPoints: data['total_points'] ?? 0,
      filePath: data['file_path'] ?? '',
      isShared: data['is_shared'] ?? false,
    );
  }
}