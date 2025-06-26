import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Authenticated HTTP client using headers from GoogleSignIn
class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleSheetsService {
  final GoogleSignInAccount googleUser;
  final GoogleSignIn _googleSignIn;
  late sheets.SheetsApi sheetsApi;
  late String spreadsheetId;

  GoogleSheetsService._(this.googleUser, this._googleSignIn);

  /// Factory method to create instance from signed-in user
  static Future<GoogleSheetsService> fromGoogleSignIn(GoogleSignInAccount user) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/spreadsheets',
        'https://www.googleapis.com/auth/drive.file',
      ],
    );

    final service = GoogleSheetsService._(user, googleSignIn);
    await service._initSheetsApi();
    return service;
  }

  Future<void> _initSheetsApi() async {
    final authHeaders = await googleUser.authHeaders;
    final client = _AuthenticatedClient(authHeaders);
    sheetsApi = sheets.SheetsApi(client);
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Create a new spreadsheet with attendance-related sheets
  Future<String> createAttendanceSheet(String businessName) async {
    final spreadsheet = sheets.Spreadsheet.fromJson({
      "properties": {"title": "$businessName Attendance"},
      "sheets": [
        {"properties": {"title": "Attendance"}},
        {"properties": {"title": "Roles"}},
        {"properties": {"title": "Settings"}},
      ],
    });

    final response = await sheetsApi.spreadsheets.create(spreadsheet);
    spreadsheetId = response.spreadsheetId!;
    return spreadsheetId;
  }

  /// Initialize roles, settings and attendance sheet
  Future<void> initializeSheet(
      String spreadsheetId,
      List<Map<String, String>> employees,
      String adminEmail,
      Map<String, bool> settings,
      ) async {
    // Roles sheet
    final rolesValues = [
      ['Email', 'Name', 'Role'],
      [adminEmail, 'Admin User', 'Admin'],
    ];

    final rolesRequest = sheets.ValueRange(values: rolesValues);
    await sheetsApi.spreadsheets.values.update(
      rolesRequest,
      spreadsheetId,
      'Roles!A1:C',
      valueInputOption: 'RAW',
    );

    // Attendance sheet header
    final attendanceHeader = [
      ['Date', 'Employee Email', 'Attendance (Yes/No)', 'Location', 'Task'],
    ];
    final attendanceRequest = sheets.ValueRange(values: attendanceHeader);
    await sheetsApi.spreadsheets.values.update(
      attendanceRequest,
      spreadsheetId,
      'Attendance!A1:E1',
      valueInputOption: 'RAW',
    );

    // Settings sheet
    final settingsValues = [
      ['Require Photo', settings['requirePhoto'] == true ? 'TRUE' : 'FALSE'],
      ['Require Location', settings['requireLocation'] == true ? 'TRUE' : 'FALSE'],
      ['Enable Task Entry', settings['enableTaskEntry'] == true ? 'TRUE' : 'FALSE'],
    ];
    final settingsRequest = sheets.ValueRange(values: settingsValues);
    await sheetsApi.spreadsheets.values.update(
      settingsRequest,
      spreadsheetId,
      'Settings!A1:B3',
      valueInputOption: 'RAW',
    );
  }

  /// Check if admin setup already exists
  Future<bool> checkIfSetupExists(String spreadsheetId, String adminEmail) async {
    try {
      final response = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Roles!A2:A',
      );
      final emails = response.values?.expand((row) => row).cast<String>().toList() ?? [];
      return emails.contains(adminEmail);
    } catch (e) {
      return false;
    }
  }

  /// Static helper: store spreadsheet ID in SharedPreferences for persistence
  static Future<void> storeSpreadsheetId(String spreadsheetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spreadsheetId', spreadsheetId);
  }

  /// Static helper: get stored spreadsheet ID
  static Future<String?> getStoredSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('spreadsheetId');
  }
}
