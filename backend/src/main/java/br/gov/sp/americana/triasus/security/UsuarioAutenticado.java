package br.gov.sp.americana.triasus.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

import java.util.Collection;
import java.util.List;

public class UsuarioAutenticado implements Authentication {

    private final Integer usuarioId;
    private final String cpf;
    private final List<String> papeis;
    private final Integer pacienteId;
    private final Integer profissionalId;
    private final Collection<? extends GrantedAuthority> authorities;
    private boolean authenticated = true;

    public UsuarioAutenticado(Integer usuarioId, String cpf, List<String> papeis, Integer pacienteId, Integer profissionalId, Collection<? extends GrantedAuthority> authorities) {
        this.usuarioId = usuarioId;
        this.cpf = cpf;
        this.papeis = papeis;
        this.pacienteId = pacienteId;
        this.profissionalId = profissionalId;
        this.authorities = authorities;
    }

    public Integer getUsuarioId() {
        return usuarioId;
    }

    public String getCpf() {
        return cpf;
    }

    public List<String> getPapeis() {
        return papeis;
    }

    public Integer getPacienteId() {
        return pacienteId;
    }

    public Integer getProfissionalId() {
        return profissionalId;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public Object getCredentials() {
        return null;
    }

    @Override
    public Object getDetails() {
        return null;
    }

    @Override
    public Object getPrincipal() {
        return usuarioId;
    }

    @Override
    public boolean isAuthenticated() {
        return authenticated;
    }

    @Override
    public void setAuthenticated(boolean isAuthenticated) throws IllegalArgumentException {
        this.authenticated = isAuthenticated;
    }

    @Override
    public String getName() {
        return String.valueOf(usuarioId);
    }
}
