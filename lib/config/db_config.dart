import 'package:flutter_dotenv/flutter_dotenv.dart';

class DbConfig {
  static String get mysqlHost => dotenv.env['MYSQL_HOST'] ?? '';
  static int get mysqlPort => int.tryParse(dotenv.env['MYSQL_PORT'] ?? '3306') ?? 3306;
  static String get mysqlDatabase => dotenv.env['MYSQL_DATABASE'] ?? '';
  static String get mysqlUser => dotenv.env['MYSQL_USER'] ?? '';
  static String get mysqlPassword => dotenv.env['MYSQL_PASSWORD'] ?? '';
}
