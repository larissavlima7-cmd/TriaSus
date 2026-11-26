import '../models/models.dart';

abstract class IEspecialidadeService {
  Future<List<EspecialidadeModel>> getEspecialidades();
  Future<List<ChecklistItemModel>> getChecklistByEspecialidade(int especialidadeId);
}
