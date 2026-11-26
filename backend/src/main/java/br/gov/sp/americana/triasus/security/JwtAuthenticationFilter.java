package br.gov.sp.americana.triasus.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.List;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final TokenService tokenService;

    public JwtAuthenticationFilter(TokenService tokenService) {
        this.tokenService = tokenService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7).trim();
            try {
                Claims claims = tokenService.validarToken(token);
                Integer usuarioId = Integer.valueOf(claims.getSubject());
                String cpf = claims.get("cpf", String.class);
                Integer pacienteId = claims.get("pacienteId", Integer.class);
                Integer profissionalId = claims.get("profissionalId", Integer.class);

                @SuppressWarnings("unchecked")
                List<String> papeis = claims.get("papeis", List.class);
                if (papeis == null) {
                    papeis = Collections.emptyList();
                }

                List<SimpleGrantedAuthority> authorities = papeis.stream()
                        .map(p -> new SimpleGrantedAuthority("ROLE_" + p))
                        .toList();

                UsuarioAutenticado authentication = new UsuarioAutenticado(
                        usuarioId,
                        cpf,
                        papeis,
                        pacienteId,
                        profissionalId,
                        authorities
                );

                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (Exception e) {
                SecurityContextHolder.clearContext();
            }
        }

        filterChain.doFilter(request, response);
    }
}
