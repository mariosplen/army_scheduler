import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ls_ypiresies/core/theme/app_colors.dart';
import 'package:ls_ypiresies/features/assignments/data/datasource/assignments_datasource.dart';
import 'package:ls_ypiresies/features/assignments/data/repository/assignments_repository.dart';
import 'package:ls_ypiresies/features/assignments/domain/repository/assignments_repository.dart';
import 'package:ls_ypiresies/features/assignments/presentation/screen/assignments_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:table_parser/table_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final packageInfo = await PackageInfo.fromPlatform();
  final docsDir = await getApplicationDocumentsDirectory();
  final appDir = Directory(p.join(docsDir.path, packageInfo.appName));

  debugPrint('App data directory: ${appDir.path}');

  if (!await appDir.exists()) {
    await appDir.create(recursive: true);
  }

  // Load the most recent excel.xlsx and tasks.json from persisted monthly folders,
  // falling back to the bundled asset files when no saved data exists yet.
  File? latestExcelFile;
  File? latestJsonFile;

  try {
    final latestMonthDir = _findLatestMonthDir(appDir);
    if (latestMonthDir != null) {
      final potentialExcel =
          File(p.join(latestMonthDir.path, 'excel.xlsx'));
      final potentialJson =
          File(p.join(latestMonthDir.path, 'tasks.json'));

      if (await potentialExcel.exists()) latestExcelFile = potentialExcel;
      if (await potentialJson.exists()) latestJsonFile = potentialJson;
    }
  } catch (e) {
    debugPrint('Error finding latest saved files: $e');
  }

  TableParser excel;
  if (latestExcelFile != null) {
    debugPrint('Loading Excel from: ${latestExcelFile.path}');
    excel = TableParser.decodeBytes(
        await latestExcelFile.readAsBytes(), update: true);
  } else {
    debugPrint('Loading Excel from bundled assets');
    final byteData = await rootBundle.load('assets/excel.xlsx');
    excel =
        TableParser.decodeBytes(byteData.buffer.asUint8List(), update: true);
  }

  String jsonString;
  if (latestJsonFile != null) {
    debugPrint('Loading JSON from: ${latestJsonFile.path}');
    jsonString = await latestJsonFile.readAsString();
  } else {
    debugPrint('Loading JSON from bundled assets');
    jsonString = await rootBundle.loadString('assets/tasks.json');
  }

  runApp(MyApp(
    json: jsonString,
    excel: excel,
    baseDocsPath: appDir.path,
  ));
}

/// Scans [appDir] for `YY_MM` month folders and returns the one with the
/// latest year/month combination.
Directory? _findLatestMonthDir(Directory appDir) {
  final dirs = appDir.listSync().whereType<Directory>().where((d) {
    return RegExp(r'^\d{2}_\d{2}$').hasMatch(p.basename(d.path));
  }).toList();

  if (dirs.isEmpty) return null;

  dirs.sort((a, b) {
    final partsA = p.basename(a.path).split('_').map(int.parse).toList();
    final partsB = p.basename(b.path).split('_').map(int.parse).toList();
    final yearComp = partsB[0].compareTo(partsA[0]);
    return yearComp != 0 ? yearComp : partsB[1].compareTo(partsA[1]);
  });

  return dirs.first;
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.json,
    required this.excel,
    required this.baseDocsPath,
  }) : super(key: key);

  final String json;
  final TableParser excel;
  final String baseDocsPath;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AssignmentsRepository>(
      create: (_) => AssignmentsRepositoryImplementation(
        AssignmentsDataSourceImpl(
          excel: excel,
          json: json,
          baseDocsPath: baseDocsPath,
        ),
      ),
      child: MaterialApp(
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: AppColors.lightGreen),
          useMaterial3: true,
        ),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AssignmentsScreen(),
      ),
    );
  }
}
