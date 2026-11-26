import 'package:dio/dio.dart';
import '../core/http_client.dart';
import '../core/storage.dart';
import '../models/models.dart';
import 'auth_service.dart';

class RealAuthService implements IAuthService {
  final Dio _dio = AppHttpClient.dio;

  @override
  Future<AuthResult> loginCidadao({
    required String cpfOuCns,
    required String dataNascimento,
    String? senha,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/cidadao',
        data: {
          'identificador': cpfOuCns,
          'dataNascimento': dataNascimento,
          'senha': senha,
        },
      );
      final result = AuthResult.fromJson(response.data);
      await AppStorage.saveToken(result.token);
      return result;
    } catch (e) {
      throw AppHttpClient.parseErrorMessage(e);
    }
  }

  @override
  Future<void> logout() async {
    await AppStorage.clearAuth();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await AppStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}

class MockAuthService implements IAuthService {
  @override
  Future<AuthResult> loginCidadao({
    required String cpfOuCns,
    required String dataNascimento,
    String? senha,
  }) async {
    // Simula atraso de rede
    await Future.delayed(const Duration(milliseconds: 600));

    // Valida preenchimento básico
    if (cpfOuCns.trim().isEmpty || dataNascimento.trim().isEmpty) {
      throw 'Preencha o CPF ou Cartão SUS e a data de nascimento.';
    }

    const mockResult = AuthResult(
      token: 'mock_jwt_token_cidadao_americana_12345',
      tipo: 'Bearer',
      usuarioId: 1,
      nome: 'Maria Silva Oliveira',
      email: 'maria.silva@americana.sp.gov.br',
      papeis: ['CIDADAO'],
    );

    await AppStorage.saveToken(mockResult.token);
    return mockResult;
  }

  @override
  Future<void> logout() async {
    await AppStorage.clearAuth();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await AppStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
