;+
; Return the name/labeling for a given species.
;-
function rbsp_hope_species_name, species
    info = dictionary($
        'o', 'O+', $
        'p', 'H+', $
        'he', 'He+', $
        'e', 'e-' )
    return, info[species]
end