function themis_esa_species_is_valid, species

    all_species = themis_esa_get_species()
    index = where(all_species eq species, count)
    if count eq 0 then return, 0 else return, 1

end