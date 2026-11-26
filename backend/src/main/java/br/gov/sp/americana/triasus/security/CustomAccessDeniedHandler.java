package br.gov.sp.americana.triasus.security;

import br.gov.sp.americana.triasus.dto.ErroRespostaDTO;
import br.gov.sp.americana.triasus.service.AuditoriaService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.LocalDateTime;

@Component
public class CustomAccessDeniedHandler implements AccessDeniedHandler {

    private static final Logger log = LoggerFactory.getLogger(CustomAccessDeniedHandler.class);
    private final AuditoriaService auditoriaService;
    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    public CustomAccessDeniedHandler(AuditoriaService auditoriaService) {
        this.auditoriaService = auditoriaService;
    }

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, AccessDeniedException accessDeniedException)
            throws IOException {
        String uri = request.getRequestURI();
        String ip = obterIpCliente(request);
        Integer usuarioId = null;

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof UsuarioAutenticado usuarioAutenticado) {
            usuarioId = usuarioAutenticado.getUsuarioId();
        }

        try {
            auditoriaService.registrarAcessoNegado(usuarioId, ip, uri);
        } catch (Exception e) {
            log.error("Falha ao registrar auditoria de acesso negado: {}", e.getMessage());
        }

        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");

        ErroRespostaDTO erro = new ErroRespostaDTO(
                LocalDateTime.now(),
                HttpStatus.FORBIDDEN.value(),
                "Acesso negado para o recurso solicitado.",
                uri
        );

        response.getWriter().write(objectMapper.writeValueAsString(erro));
    }

    private String obterIpCliente(HttpServletRequest request) {
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader == null || xfHeader.isBlank()) {
            return request.getRemoteAddr();
        }
        return xfHeader.split(",")[0].trim();
    }
}
