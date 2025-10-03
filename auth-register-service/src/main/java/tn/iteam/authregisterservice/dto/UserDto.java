package tn.iteam.authregisterservice.dto;

import jakarta.validation.constraints.NotEmpty;
import lombok.Getter;
import lombok.Setter;
import org.antlr.v4.runtime.misc.NotNull;
@Getter
@Setter
public class UserDto {
    @NotNull @NotEmpty
    private String firstName;
    @NotNull
    @NotEmpty
    private String lastName;
    @NotNull @NotEmpty
    private String password;
    private String matchingPassword;
    @NotNull @NotEmpty
    private String email;
}
