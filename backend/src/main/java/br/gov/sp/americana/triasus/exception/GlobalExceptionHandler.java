package br.gov.sp.americana.triasus.exception;

import br.gov.sp.americana.triasus.dto.ErroRespostaDTO;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.LocalDateTime;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private final br.gov.sp.americana.triasus.service.AuditoriaService auditoriaService;

    public GlobalExceptionHandler(br.gov.sp.americana.triasus.service.AuditoriaService auditoriaService) {
        this.auditoriaService = auditoriaService;
    }

    @ExceptionHandler(CredenciaisInvalidasException.class)
    public ResponseEntity<ErroRespostaDTO> handleCredenciaisInvalidas(CredenciaisInvalidasException ex, HttpServletRequest request) {
        return buildResponse(HttpStatus.UNAUTHORIZED, ex.getMessage(), request.getRequestURI());
    }

    @ExceptionHandler({AuthenticationException.class, BadCredentialsException.class, SecurityException.class})
    public ResponseEntity<ErroRespostaDTO> handleAuthException(Exception ex, HttpServletRequest request) {
        return buildResponse(HttpStatus.UNAUTHORIZED, "Não autorizado ou credenciais inválidas.", request.getRequestURI());
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErroRespostaDTO> handleAccessDenied(AccessDeniedException ex, HttpServletRequest request) {
        try {
            Integer usuarioId = null;
            org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            if (auth instanceof br.gov.sp.americana.triasus.security.UsuarioAutenticado usuarioAutenticado) {
                usuarioId = usuarioAutenticado.getUsuarioId();
            }
            String ip = request.getHeader("X-Forwarded-For");
            if (ip == null || ip.isBlank()) {
                ip = request.getRemoteAddr();
            } else {
                ip = ip.split(",")[0].trim();
            }
            auditoriaService.registrarAcessoNegado(usuarioId, ip, request.getRequestURI());
        } catch (Exception e) {
            log.error("Erro ao auditar acesso negado: {}", e.getMessage());
        }
        return buildResponse(HttpStatus.FORBIDDEN, "Acesso negado para o recurso solicitado.", request.getRequestURI());
    }


    @ExceptionHandler({RecursoNaoEncontradoException.class, NoResourceFoundException.class})
    public ResponseEntity<ErroRespostaDTO> handleNotFound(Exception ex, HttpServletRequest request) {
        String msg = ex instanceof RecursoNaoEncontradoException ? ex.getMessage() : "Recurso não encontrado.";
        return buildResponse(HttpStatus.NOT_FOUND, msg, request.getRequestURI());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErroRespostaDTO> handleValidationException(MethodArgumentNotValidException ex, HttpServletRequest request) {
        String detalhes = ex.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining("; "));
        return buildResponse(HttpStatus.UNPROCESSABLE_ENTITY, detalhes, request.getRequestURI());
    }

    @ExceptionHandler({
            org.springframework.web.multipart.MaxUploadSizeExceededException.class,
            org.springframework.web.multipart.MultipartException.class
    })
    public ResponseEntity<ErroRespostaDTO> handleMaxUploadSize(Exception ex, HttpServletRequest request) {
        return buildResponse(HttpStatus.PAYLOAD_TOO_LARGE, "O arquivo excede o limite de 5 MB.", request.getRequestURI());
    }

    @ExceptionHandler(RegraNegocioException.class)
    public ResponseEntity<ErroRespostaDTO> handleRegraNegocio(RegraNegocioException ex, HttpServletRequest request) {
        return buildResponse(HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage(), request.getRequestURI());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErroRespostaDTO> handleBadRequest(IllegalArgumentException ex, HttpServletRequest request) {
        return buildResponse(HttpStatus.BAD_REQUEST, ex.getMessage(), request.getRequestURI());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErroRespostaDTO> handleGenericException(Exception ex, HttpServletRequest request) {
        log.error("Erro interno não tratado ao processar requisição {}: {}", request.getRequestURI(), ex.getMessage(), ex);
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, "Ocorreu um erro interno no servidor. Tente novamente mais tarde.", request.getRequestURI());
    }

    private ResponseEntity<ErroRespostaDTO> buildResponse(HttpStatus status, String mensagem, String caminho) {
        ErroRespostaDTO erro = new ErroRespostaDTO(
                LocalDateTime.now(),
                status.value(),
                mensagem,
                caminho
        );
        return ResponseEntity.status(status).body(erro);
    }
}
