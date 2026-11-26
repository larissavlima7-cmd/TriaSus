import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/base_screen_layout.dart';

enum TipoDocumentoLogin { cpf, cns }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _senhaController = TextEditingController();

  TipoDocumentoLogin _tipoDocumento = TipoDocumentoLogin.cpf;
  bool _isLoading = false;
  bool _obscureSenha = true;
  String? _errorMessage;

  // Máscaras de entrada
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _cnsFormatter = MaskTextInputFormatter(
    mask: '###############',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _dataNascimentoFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _docController.dispose();
    _nascimentoController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _onTipoDocumentoChanged(TipoDocumentoLogin tipo) {
    if (_tipoDocumento == tipo) return;
    setState(() {
      _tipoDocumento = tipo;
      _docController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _fazerLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<IAuthService>();
      final docLimpo = DocumentValidators.apenasDigitos(_docController.text);
      final dataIso = DocumentValidators.converterParaIso(_nascimentoController.text) ??
          _nascimentoController.text;

      final result = await authService.loginCidadao(
        cpfOuCns: docLimpo,
        dataNascimento: dataIso,
        senha: _senhaController.text.trim().isNotEmpty ? _senhaController.text : null,
      );

      if (!mounted) return;

      // RF08: Validação de contato (Telefone / WhatsApp) antes de liberar acesso à tela inicial
      if (!result.contatoValidado) {
        await _exibirDialogoConfirmacaoContato(result.telefone ?? '');
      } else {
        context.go('/inicio');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exibirDialogoConfirmacaoContato(String telefoneAtual) async {
    final telController = TextEditingController(text: telefoneAtual);
    final telMask = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {'#': RegExp(r'[0-9]')},
    );
    final formContatoKey = GlobalKey<FormState>();
    bool validando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formContatoKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.phone_android_rounded,
                            color: Color(0xFF007A48),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Confirme seu WhatsApp',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Para combater faltas e enviar avisos sobre seus encaminhamentos, confirme seu número de telefone ou WhatsApp ativo:',
                      style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: telController,
                      inputFormatters: [telMask],
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Número do WhatsApp',
                        hintText: '(19) 99999-9999',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (val) {
                        final digitos = DocumentValidators.apenasDigitos(val);
                        if (digitos.length < 10 || digitos.length > 11) {
                          return 'Informe um telefone válido com DDD.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: validando
                          ? null
                          : () async {
                              if (!formContatoKey.currentState!.validate()) return;
                              setModalState(() => validando = true);
                              final auth = context.read<IAuthService>();
                              final router = GoRouter.of(context);
                              try {
                                await auth.validarContato(
                                  telefone: DocumentValidators.apenasDigitos(
                                      telController.text),
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                router.go('/inicio');
                              } catch (e) {
                                setModalState(() => validando = false);
                              }
                            },
                      child: validando
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirmar e Continuar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'TriaSus • Americana',
      showBackButton: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cabeçalho institucional do Card conforme protótipo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: Color(0xFF007A48),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TriaSus • Americana',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF007A48),
                                  ),
                                ),
                                Text(
                                  'Saúde Pública Municipal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF007A48),
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Título e Subtítulo
                        const Text(
                          'Entrar na sua conta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Acesse serviços, agendamentos e consultas de Americana',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Card com formulário
                        Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Mensagem de erro amigável em caso de falha
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFDAD6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBA1A1A)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: Color(0xFFBA1A1A), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: Color(0xFFBA1A1A),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Alternador simples de documento: CPF vs Cartão SUS
                                const Text(
                                  'Identificação',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<TipoDocumentoLogin>(
                                  segments: const [
                                    ButtonSegment(
                                      value: TipoDocumentoLogin.cpf,
                                      label: Text('CPF'),
                                      icon: Icon(Icons.badge_outlined),
                                    ),
                                    ButtonSegment(
                                      value: TipoDocumentoLogin.cns,
                                      label: Text('Cartão SUS'),
                                      icon: Icon(Icons.credit_card_outlined),
                                    ),
                                  ],
                                  selected: {_tipoDocumento},
                                  onSelectionChanged: (Set<TipoDocumentoLogin> sel) {
                                    _onTipoDocumentoChanged(sel.first);
                                  },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.comfortable,
                                    shape: WidgetStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Campo de CPF ou Cartão SUS
                                TextFormField(
                                  controller: _docController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    _tipoDocumento == TipoDocumentoLogin.cpf
                                        ? _cpfFormatter
                                        : _cnsFormatter
                                  ],
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: _tipoDocumento == TipoDocumentoLogin.cpf
                                        ? 'Número do CPF'
                                        : 'Número do Cartão SUS (15 dígitos)',
                                    hintText: _tipoDocumento == TipoDocumentoLogin.cpf
                                        ? '000.000.000-00'
                                        : '000000000000000',
                                    prefixIcon: const Icon(Icons.badge_outlined),
                                  ),
                                  validator: (valor) {
                                    if (valor == null || valor.trim().isEmpty) {
                                      return _tipoDocumento == TipoDocumentoLogin.cpf
                                          ? 'Informe o seu CPF.'
                                          : 'Informe o número do Cartão SUS.';
                                    }
                                    if (_tipoDocumento == TipoDocumentoLogin.cpf) {
                                      if (!DocumentValidators.validarCPF(valor)) {
                                        return 'CPF inválido. Verifique os números.';
                                      }
                                    } else {
                                      if (!DocumentValidators.validarCNS(valor)) {
                                        return 'Cartão SUS deve conter 15 dígitos numéricos.';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo Data de Nascimento (exigência RF01)
                                TextFormField(
                                  controller: _nascimentoController,
                                  keyboardType: TextInputType.datetime,
                                  inputFormatters: [_dataNascimentoFormatter],
                                  style: const TextStyle(fontSize: 16),
                                  decoration: const InputDecoration(
                                    labelText: 'Data de Nascimento',
                                    hintText: 'DD/MM/AAAA',
                                    prefixIcon: Icon(Icons.calendar_month_outlined),
                                  ),
                                  validator: (valor) {
                                    if (valor == null || valor.trim().isEmpty) {
                                      return 'Informe sua data de nascimento.';
                                    }
                                    if (!DocumentValidators.validarDataNascimento(valor)) {
                                      return 'Data inválida. Digite no formato DD/MM/AAAA.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo de Senha (Opcional para o cidadão no RF01)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Senha de Acesso (opcional)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'O acesso pode ser feito apenas com CPF e data de nascimento. Caso tenha cadastrado senha e a tenha esquecido, procure a recepção da UBS.'),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Esqueceu a senha?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF007A48),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextFormField(
                                  controller: _senhaController,
                                  obscureText: _obscureSenha,
                                  decoration: InputDecoration(
                                    hintText: 'Digite sua senha se possuir',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureSenha
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureSenha = !_obscureSenha;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Botão Principal de Login
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _fazerLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF005A32),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Entrar',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, size: 20),
                                          ],
                                        ),
                                ),

                                const SizedBox(height: 20),

                                // Divisor OU ACESSE COM
                                const Row(
                                  children: [
                                    Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'OU ACESSE COM',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Botão gov.br apenas visual / desabilitado conforme protótipo
                                OutlinedButton(
                                  onPressed: null, // Desabilitado
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0B3B60),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'g',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Entrar com gov.br',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'em breve',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF475569),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 24),

                        // Rodapé Institucional
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Primeiro acesso ou precisa de ajuda? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Atendimento na UBS'),
                                      content: const Text(
                                        'Dirija-se à recepção da sua Unidade Básica de Saúde ou converse com o Agente Comunitário de Saúde (ACS) do seu bairro para cadastro assistido e validação de seus dados.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Fale com a UBS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF007A48),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ambiente seguro com proteção de dados conforme a LGPD e Ministério da Saúde.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
