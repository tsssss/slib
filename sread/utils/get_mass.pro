
function get_mass, species_str

    mass_0 = 1.67e-27    ; kg.
    mass_e = 0.91e-30   ; kg.
    if species_str eq 'p' then return, mass_0
    if species_str eq 'o' then return, mass_0*16
    if species_str eq 'he' then return, mass_0*4
    if species_str eq 'e' then return, mass_e

end