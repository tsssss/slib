;+
; Read the energy-time spectrogram, for a given pitch angle.
;-

pro rbsp_read_en_spec, time, probe=probe, errmsg=errmsg, $
    pitch_angle=pitch_info

    errmsg = ''

    rbsp_read_hope, time, id='l3%pa', probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    ; if no pitch angle is given, then average all pitch angle.
    ; else if a pitch angle is given, then choose the closest channel.
    if n_elements(pitch_info) eq 1 then begin
        pitch_angles = get_var_data('pitch_angle')
        tmp = min(pitch_angles-pitch_info[0],/absolute, pitch_index)
        the_pitch = pitch_angles[pitch_index]
    endif else the_pitch = !null

    species_infos = dictionary()
    species_infos['e'] = dictionary('short_name', 'e!U-!N')
    species_infos['p'] = dictionary('short_name', 'H!U+!N')
    species_infos['o'] = dictionary('short_name', 'O!U+!N')
    species_infos['he'] = dictionary('short_name', 'He!U+!N')
    species = species_infos.keys()

    fillval = !values.f_nan
    foreach the_species, species do begin
        the_type = (the_species eq 'e')? 'ele': 'ion'

        flux_var = 'f'+the_species+'du'
        get_data, flux_var, times, fdat
        index = where(fdat le -1e30, count)
        if count ne 0 then fdat[index] = fillval

        en_var = 'hope_energy_'+the_type
        en0s = get_var_data(en_var)

        en_spec_var = 'rbsp'+probe+'_'+the_species+'_en_spec'
        if n_elements(pitch_info) eq 1 then begin
            en_spec_var += '_'+sgnum2str(the_pitch)+'deg'
        endif
        if n_elements(pitch_index) eq 0 then begin
            dims = size(fdat,/dimensions)
            data = total(fdat,3,/nan)/dims[2]
        endif else data = reform(fdat[*,*,pitch_index])

        store_data, en_spec_var, times, data, en0s

        zrange = (the_species eq 'e')? [1e4,1e10]: [1e4,1e8]
        species_name = species_infos[the_species].short_name
        add_setting, en_spec_var, /smart, {$
            display_type: 'spec', $
            unit: '1/cm!U2!N-s-sr-keV', $
            zrange: zrange, $
            species_name: species_name, $
            ytitle: species_name+' Energy (eV)', $
            ylog: 1, $
            zlog: 1, $
            short_name: ''}
        if n_elements(the_pitch) ne 0 then begin
            add_setting, en_spec_var, {$
                pitch_angle: the_pitch, $
                ytitle: species_name+' Energy (eV)!CPA='+sgnum2str(the_pitch)+' deg'}
        endif
    endforeach

end

time = time_double(['2013-03-14/00:00','2013-03-14/00:10'])
probe = 'a'
rbsp_read_en_spec, time, probe=probe
end
