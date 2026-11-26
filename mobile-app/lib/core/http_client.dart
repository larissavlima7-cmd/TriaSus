import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import 'storage.dart';

/// Cliente HTTP Dio configurado com interceptores de autenticação e tratamento de erros
class AppHttpClient {
  static Dio? _dioInstance;
  static VoidCallback? onUnauthorized;

  static Dio get dio {
    _dioInstance ??= _createDio();
    return _dioInstance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AppStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Tratamento para 401 Unauthorized: expiração ou ausência de token
          if (error.response?.statusCode == 401) {
            await AppStorage.clearAuth();
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Converte exceções DioException em mensagens claras em PT-BR para o usuário
  static String parseErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null && error.response?.data != null) {
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          // Formato padrão ErroRespostaDTO: { "mensagem": "...", "status": 400 }
          if (data['mensagem'] != null) {
            return data['mensagem'].toString();
          }
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Tempo de conexão esgotado. Verifique sua conexão com a internet.';
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          if (code == 401) return 'Sessão expirada. Por favor, acesse novamente.';
          if (code == 403) return 'Acesso não autorizado para esta funcionalidade.';
          if (code == 404) return 'Recurso não encontrado no servidor.';
          if (code == 400) return 'Dados inválidos. Confira os campos preenchidos.';
          return 'Serviço temporariamente indisponível ($code).';
        case DioExceptionType.connectionError:
          return 'Não foi possível conectar ao servidor da UBS. Verifique se o backend está em execução.';
        default:
          return 'Ocorreu um erro inesperado ao se comunicar com o sistema.';
      }
    }
    return error?.toString() ?? 'Ocorreu um erro desconhecido.';
  }
}
