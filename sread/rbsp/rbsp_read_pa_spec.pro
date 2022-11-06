;+
; Read the pitch angle spectrogram, for a given energy range.
;-

pro rbsp_read_pa_spec, time, probe=probe, errmsg=errmsg, $
    energy_range=energy_range

    errmsg = ''

    rbsp_read_hope, time, id='l3%pa', probe=probe, errmsg=errmsg
    if errmsg ne '' then return


    species_infos = dictionary()
    species_infos['e'] = dictionary('short_name', 'e!U-!N')
    species_infos['p'] = dictionary('short_name', 'H!U+!N')
    species_infos['o'] = dictionary('short_name', 'O!U+!N')
    species_infos['he'] = dictionary('short_name', 'He!U+!N')
    species = species_infos.keys()

    pa_bins = get_var_data('pitch_angle')
    pa_bins = sort_uniq(pa_bins)

    fillval = !values.f_nan
    foreach the_species, species do begin
        the_type = (the_species eq 'e')? 'ele': 'ion'

        flux_var = 'f'+the_species+'du'
        get_data, flux_var, times, fdat
        index = where(fdat le -1e30, count)
        if count ne 0 then fdat[index] = fillval

        en_var = 'hope_energy_'+the_type
        en_bins = reform((get_var_data(en_var))[0,*])
        if n_elements(energy_range) ne 2 then energy_range = minmax(en_bins)
        energy_index = lazy_where(en_bins, '[]', energy_range, count=nen_bin)

        pa_spec_var = 'rbsp'+probe+'_'+the_species+'_pa_spec'
        data = total(fdat[*,energy_index,*],2, /nan)/nen_bin
        store_data, pa_spec_var, times, data, pa_bins

        zrange = (the_species eq 'e')? [1e5,1e10]: [1e5,1e8]
        species_name = species_infos[the_species].short_name
        add_setting, pa_spec_var, /smart, {$
            display_type: 'spec', $
            unit: '1/cm!U2!N-s-sr-keV', $
            zrange: zrange, $
            species_name: species_name, $
            ytitle: species_name+' Pitch (deg)', $
            short_name: ''}
        ylim, pa_spec_var, 0, 180, 0
    endforeach

end

time = time_double(['2013-03-14/00:00','2013-03-14/00:10'])
probe = 'a'
rbsp_read_pa_spec, time, probe=probe
end
