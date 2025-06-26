import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart'  as sheets;
import 'package:googleapis/drive/v3.dart'   as drive;
import 'package:http/http.dart'            as http;
import 'package:shared_preferences/shared_preferences.dart';

class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _base = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _base.send(request);
  }
}

class GoogleSheetsService {
  final GoogleSignInAccount googleUser;
  final GoogleSignIn _googleSignIn;
  late final sheets.SheetsApi sheetsApi;
  late final drive.DriveApi  driveApi;

  GoogleSheetsService._(this.googleUser, this._googleSignIn);

  /* ───────────────────────── factory ───────────────────────── */

  static Future<GoogleSheetsService> fromGoogleSignIn(
      GoogleSignInAccount user) async {
    final service = GoogleSheetsService._(
      user,
      GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/spreadsheets',
          'https://www.googleapis.com/auth/drive.file',
        ],
      ),
    );
    await service._initApis();
    return service;
  }

  Future<void> _initApis() async {
    final authHeaders = await googleUser.authHeaders;
    final client      = _AuthenticatedClient(authHeaders);
    sheetsApi = sheets.SheetsApi(client);
    driveApi  = drive.DriveApi(client);
  }

  /* ───────────────────────── helpers ───────────────────────── */

  /// 1 → A, 2 → B, … 27 → AA
  String _columnLetter(int index) {
    var i = index;
    String col = '';
    while (i > 0) {
      i--;
      col = String.fromCharCode(65 + (i % 26)) + col;
      i ~/= 26;
    }
    return col;
  }

  /* ─────────────────── Drive lookup ─────────────────── */

  static const _postfix = '-attcontrol';         // folder
  static const _fileSuffix = '-attcontrol-file'; // spreadsheet

  /// Find an attendance folder & spreadsheet (returns null if none).
  Future<Map<String, String>?> findExistingAttendanceFolder() async {
    final res = await driveApi.files.list(
      q: "name contains '$_postfix' "
          "and mimeType='application/vnd.google-apps.folder' "
          "and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    if (res.files == null || res.files!.isEmpty) return null;

    final folder      = res.files!.first;
    final folderId    = folder.id!;
    final folderName  = folder.name!;                      // e.g. QCT-attcontrol
    final business    = folderName.replaceFirst(_postfix, '');
    final sheetName   = '$business$_fileSuffix';

    final sheetRes = await driveApi.files.list(
      q: "'$folderId' in parents "
          "and name='$sheetName' "
          "and mimeType='application/vnd.google-apps.spreadsheet' "
          "and trashed=false",
      spaces: 'drive',
      $fields: 'files(id)',
    );
    if (sheetRes.files == null || sheetRes.files!.isEmpty) return null;

    return {
      'folderId'      : folderId,
      'spreadsheetId' : sheetRes.files!.first.id!,
      'businessName'  : business,
    };
  }

  /* ─────────────────── Drive create ─────────────────── */

  /// Create folder  <Business>-attcontrol
  /// + spreadsheet  <Business>-attcontrol-file
  /// Spreadsheet gets 2 tabs: Roles & adminSheetName
  Future<Map<String, String>> createFolderAndSheet(
      String business,
      String adminSheetName,
      ) async {
    /* Folder */
    final folderFile = drive.File()
      ..name     = '$business$_postfix'
      ..mimeType = 'application/vnd.google-apps.folder';

    final folder   = await driveApi.files.create(folderFile);
    final folderId = folder.id!;

    /* Spreadsheet */
    final spreadsheet = sheets.Spreadsheet.fromJson({
      'properties': {'title': '$business$_fileSuffix'},
      'sheets': [
        {'properties': {'title': 'Roles'}},
        {'properties': {'title': adminSheetName}},
      ],
    });
    final sheetRes      = await sheetsApi.spreadsheets.create(spreadsheet);
    final spreadsheetId = sheetRes.spreadsheetId!;

    /* Move spreadsheet into folder */
    await driveApi.files.update(
      drive.File(),
      spreadsheetId,
      addParents   : folderId,
      removeParents: 'root',
    );

    return {
      'folderId'      : folderId,
      'spreadsheetId' : spreadsheetId,
      'businessName'  : business,
    };
  }

  /* ─────────────────── Sheet init ─────────────────── */

  Future<void> initializeSheet(
      String spreadsheetId,
      String adminEmail,
      String adminName,
      Map<String, bool> settings,
      ) async {
    /* Roles */
    final roles = [
      ['Email', 'Name', 'Role'],
      [adminEmail, adminName, 'Admin'],
    ];
    await sheetsApi.spreadsheets.values.update(
      sheets.ValueRange(values: roles),
      spreadsheetId,
      'Roles!A1:C',
      valueInputOption: 'RAW',
    );

    /* Admin sheet header */
    final header = ['Date', 'Attendance (Yes/No)'];
    if (settings['enableTaskEntry'] == true) header.add('Task');
    if (settings['requireLocation'] == true) header.add('Location');
    if (settings['requirePhoto']    == true) header.add('PhotoURL');

    final endCol = _columnLetter(header.length);
    await sheetsApi.spreadsheets.values.update(
      sheets.ValueRange(values: [header]),
      spreadsheetId,
      '$adminName!A1:$endCol' '1',
      valueInputOption: 'RAW',
    );
  }

  /* ─────────────────── misc ─────────────────── */

  Future<void> signOut() async => _googleSignIn.signOut();

  static Future<void> storeSpreadsheetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spreadsheetId', id);
  }

  static Future<String?> getStoredSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('spreadsheetId');
  }
}
