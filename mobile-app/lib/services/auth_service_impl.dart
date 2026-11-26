import 'dart:convert';
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
        data: {'identificador': cpfOuCns, 'dataNascimento': dataNascimento},
      );
      final result = AuthResult.fromJson(response.data);
      await AppStorage.saveToken(result.token);
      await AppStorage.saveUserData(
        jsonEncode({
          'nome': result.nome,
          'usuarioId': result.usuarioId,
          'pacienteId': result.pacienteId,
          'contatoValidado': result.contatoValidado,
          'telefone': result.telefone,
        }),
      );
      return result;
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 400 ||
          dioErr.response?.statusCode == 401 ||
          dioErr.response?.statusCode == 404) {
        throw 'Dados não conferem. Verifique e tente de novo.';
      }
      throw AppHttpClient.parseErrorMessage(dioErr);
    } catch (_) {
      throw 'Dados não conferem. Verifique e tente de novo.';
    }
  }

  @override
  Future<void> validarContato({required String telefone}) async {
    // TODO: Integrar com endpoint PATCH/POST de validação de contato do paciente quando disponível no backend
    final userRaw = await AppStorage.getUserData();
    if (userRaw != null) {
      final Map<String, dynamic> data = jsonDecode(userRaw);
      data['contatoValidado'] = true;
      data['telefone'] = telefone;
      await AppStorage.saveUserData(jsonEncode(data));
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
  bool _mockContatoValidado = false;
  String _mockTelefone = '19999990000';

  @override
  Future<AuthResult> loginCidadao({
    required String cpfOuCns,
    required String dataNascimento,
    String? senha,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final idLimpo = cpfOuCns.replaceAll(RegExp(r'\D'), '');
    final dataLimpa = dataNascimento.trim();

    // Aceita a cidadã do seed (Mariana Souza, CPF 39053344705, nascimento 1958-03-14)
    // ou qualquer teste com identificador preenchido
    final isSeedPatient =
        (idLimpo == '39053344705' || idLimpo == '700000000000001');
    final isSeedBirth =
        (dataLimpa == '1958-03-14' || dataLimpa == '14/03/1958');

    if (isSeedPatient && !isSeedBirth) {
      throw 'Dados não conferem. Verifique e tente de novo.';
    }

    final mockResult = AuthResult(
      token: 'mock_jwt_token_cidadao_americana_39053344705',
      tipo: 'Bearer',
      usuarioId: 3,
      nome: isSeedPatient ? 'Mariana Souza' : 'Maria Silva Oliveira',
      email: isSeedPatient
          ? 'mariana.souza@triasus.local'
          : 'maria.silva@americana.sp.gov.br',
      papeis: const ['CIDADAO'],
      pacienteId: 1,
      contatoValidado: _mockContatoValidado,
      telefone: _mockTelefone,
    );

    await AppStorage.saveToken(mockResult.token);
    await AppStorage.saveUserData(
      jsonEncode({
        'nome': mockResult.nome,
        'usuarioId': mockResult.usuarioId,
        'pacienteId': mockResult.pacienteId,
        'contatoValidado': mockResult.contatoValidado,
        'telefone': mockResult.telefone,
      }),
    );
    return mockResult;
  }

  @override
  Future<void> validarContato({required String telefone}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _mockContatoValidado = true;
    _mockTelefone = telefone;
    final userRaw = await AppStorage.getUserData();
    if (userRaw != null) {
      final Map<String, dynamic> data = jsonDecode(userRaw);
      data['contatoValidado'] = true;
      data['telefone'] = telefone;
      await AppStorage.saveUserData(jsonEncode(data));
    }
  }

  @override
  Future<void> logout() async {
    _mockContatoValidado = false;
    await AppStorage.clearAuth();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await AppStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
