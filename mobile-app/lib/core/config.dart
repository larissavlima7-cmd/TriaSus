/// Configurações gerais da aplicação móvel TriaSUS
class AppConfig {
  /// URL base da API REST do backend Spring Boot
  ///
  /// IMPORTANTE:
  /// - Para o Emulador Android oficial do Google: usar `http://10.0.2.2:8080/api`
  ///   (10.0.2.2 mapeia diretamente para o localhost da máquina host).
  /// - Para Celular Físico conectado via Wi-Fi: trocar pelo IP local da sua máquina,
  ///   por exemplo `http://192.168.1.100:8080/api`.
  /// - Para emulador iOS / macOS / Web: `http://localhost:8080/api`.
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  /// Flag para alternar entre dados simulados (mock) e chamadas reais à API REST.
  /// Útil para testes rápidos ou quando o backend não estiver em execução.
  static const bool useMock = true;

  /// Nome do aplicativo
  static const String appTitle = 'TriaSUS Americana';
}
