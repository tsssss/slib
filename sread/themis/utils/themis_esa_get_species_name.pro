;+
; Return the name/labeling for a given species.
;-
function themis_esa_get_species_name, species
    info = dictionary($
        'i', 'H+', $
        'p', 'H+', $
        'e', 'e-' )
    return, info[species]
end