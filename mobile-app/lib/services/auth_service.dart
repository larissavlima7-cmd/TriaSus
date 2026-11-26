import '../models/models.dart';

abstract class IAuthService {
  Future<AuthResult> loginCidadao({
    required String cpfOuCns,
    required String dataNascimento,
    String? senha,
  });

  Future<void> validarContato({
    required String telefone,
  });

  Future<void> logout();

  Future<bool> isAuthenticated();
}
