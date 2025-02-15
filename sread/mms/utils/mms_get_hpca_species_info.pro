function mms_get_hpca_species_info, get_orig_species=get_orig_species

    species_names = dictionary($
        'p', 'hplus', $
        'o', 'oplus', $
        'he', 'heplus', $
        'alpha', 'heplusplus' )
    if keyword_set(get_orig_species) then return, (species_names.values()).toarray() else return, species_names

end

print, mms_get_hpca_species_info()
print, mms_get_hpca_species_info(get_orig_species=1)
end