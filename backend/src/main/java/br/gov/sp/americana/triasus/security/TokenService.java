package br.gov.sp.americana.triasus.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.List;

@Service
public class TokenService {

    @Value("${app.jwt.expiration-hours:2}")
    private long expirationHours;

    private SecretKey secretKey;

    @PostConstruct
    public void init() {
        String secret = System.getenv("JWT_SECRET");
        if (secret == null || secret.trim().length() < 32) {
            throw new IllegalStateException(
                "A variável de ambiente JWT_SECRET é obrigatória e deve possuir no mínimo 32 caracteres."
            );
        }
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String gerarToken(Integer usuarioId, List<String> papeis, Integer pacienteId, Integer profissionalId, Instant expiracao) {
        var builder = Jwts.builder()
                .subject(String.valueOf(usuarioId))
                .claim("papeis", papeis)
                .issuedAt(Date.from(Instant.now()))
                .expiration(Date.from(expiracao))
                .signWith(secretKey, Jwts.SIG.HS256);

        if (pacienteId != null) {
            builder.claim("pacienteId", pacienteId);
        }
        if (profissionalId != null) {
            builder.claim("profissionalId", profissionalId);
        }

        return builder.compact();
    }

    public Instant calcularExpiracao() {
        return Instant.now().plus(expirationHours, ChronoUnit.HOURS);
    }

    public Claims validarToken(String token) {
        try {
            return Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (JwtException | IllegalArgumentException e) {
            throw new SecurityException("Token JWT inválido ou expirado.", e);
        }
    }
}
