import '../database/database_helper.dart';
import '../models/drug_model.dart';

class DrugRepository {
  final DatabaseHelper _db;
  DrugRepository(this._db);

  Future<List<Drug>> search(String query) => _db.search(query);
  Future<Drug?> getById(int id) => _db.getDrugById(id);
  Future<List<Drug>> getByCategory(String category) =>
      _db.getByCategory(category);

  Future<List<Drug>> getByClasses(List<String> classes) =>
      _db.getByClasses(classes);

  Future<List<Drug>> getByPharmClass(String pharmClass) =>
      _db.getByPharmClass(pharmClass);
}
