import '../entities/spare_part_entity.dart';

abstract class SparePartRepository {
  Future<List<SparePartEntity>> getAllSpareParts();
  Future<SparePartEntity?> getSparePartById(int id);
  Future<SparePartEntity?> getSparePartByCode(String code);
  Future<List<SparePartEntity>> searchSpareParts(String query, {String? category});
  Future<List<SparePartEntity>> getLowStockParts();
  Future<int> insertSparePart(SparePartEntity part);
  Future<int> updateSparePart(SparePartEntity part);
  Future<int> deleteSparePart(int id);
  Future<bool> adjustStock(int id, int quantityDelta);
}
