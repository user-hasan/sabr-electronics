import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/local/database_helper.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final DatabaseHelper dbHelper;

  CustomerRepositoryImpl({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<CustomerEntity>> getAllCustomers({int limit = 50, int offset = 0}) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'customers',
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((m) => CustomerEntity.fromMap(m)).toList();
  }

  @override
  Future<CustomerEntity?> getCustomerById(int id) async {
    final db = await dbHelper.database;
    final results = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CustomerEntity.fromMap(results.first);
  }

  @override
  Future<CustomerEntity?> getCustomerByPhone(String phone) async {
    final db = await dbHelper.database;
    final cleanPhone = phone.trim();
    final results = await db.query(
      'customers',
      where: 'phone = ? OR alternatePhone = ?',
      whereArgs: [cleanPhone, cleanPhone],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CustomerEntity.fromMap(results.first);
  }

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    final db = await dbHelper.database;
    final cleanQuery = '%${query.trim()}%';
    final results = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ? OR alternatePhone LIKE ?',
      whereArgs: [cleanQuery, cleanQuery, cleanQuery],
      limit: 20,
    );
    return results.map((m) => CustomerEntity.fromMap(m)).toList();
  }

  @override
  Future<int> createCustomer(CustomerEntity customer) async {
    final db = await dbHelper.database;
    return await db.insert('customers', customer.toMap());
  }

  @override
  Future<bool> updateCustomer(CustomerEntity customer) async {
    if (customer.id == null) return false;
    final db = await dbHelper.database;
    final rows = await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    return rows > 0;
  }

  @override
  Future<bool> deleteCustomer(int id) async {
    final db = await dbHelper.database;
    // القيود تمنع الحذف إذا كان مرتبطاً بأجهزة عبر ON DELETE RESTRICT
    final rows = await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    return rows > 0;
  }

  @override
  Future<int> getCustomerCount() async {
    final db = await dbHelper.database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return (res.first['count'] as int?) ?? 0;
  }

  @override
  Future<Map<String, dynamic>> getCustomerStats(int customerId) async {
    final db = await dbHelper.database;
    final deviceRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM devices WHERE customerId = ?',
      [customerId],
    );
    final repairRes = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(totalAmount - paidAmount) as debt FROM repair_records WHERE customerId = ?',
      [customerId],
    );

    final deviceCount = (deviceRes.first['count'] as int?) ?? 0;
    final repairCount = (repairRes.first['count'] as int?) ?? 0;
    final debt = (repairRes.first['debt'] as num?)?.toDouble() ?? 0.0;

    return {
      'deviceCount': deviceCount,
      'repairCount': repairCount,
      'debt': debt > 0 ? debt : 0.0,
    };
  }
}
