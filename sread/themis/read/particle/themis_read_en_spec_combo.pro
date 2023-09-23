;+
; Read themis en_spec_[para,perp,anti].
;-

function themis_read_en_spec_combo, input_time_range, probe=probe, $
    id=id, species=species0, $
    errmsg=errmsg, get_name=get_name, update=update


    errmsg = ''
    retval = dictionary()


;---Check input.
    ; probe.
    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'
    
    
    ; species.
    if n_elements(species0) eq 0 then species0 = 'i'
    species = species0
    if species eq 'p' then species = 'i'
    if ~themis_esa_species_is_valid(species) then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif
    species1 = species
    if species1 eq 'i' then species1 = 'p'
    
    
    ; time_range and coord.
    time_range = time_double(input_time_range)
    
    
    ; id.
    if n_elements(id) eq 0 then id = 'esa%sst'
    
    
    
;---Init return value and determine if load data.
    the_vinfo = dictionary()
    pa_settings = dictionary($
        'para', [0,45], $
        'perp', [45,135], $
        'anti', [135,180] )
    load_data = 0
    foreach the_species, ['e','i'] do begin
        the_species1 = the_species
        if the_species1 eq 'i' then the_species1 = 'p'
        prefix1 = prefix+the_species1+'_'   ; we save data in e and p in tplot.

        vinfo = dictionary()
        foreach key, pa_settings.keys() do begin
            vinfo[key] = prefix1+'en_spec_'+key
        endforeach
        the_vinfo[the_species] = vinfo

        foreach key, vinfo.keys() do begin
            var = vinfo[key]
            if check_if_update(var, time_range) then begin
                load_data = 1
                break
            endif
        endforeach
    endforeach
    if keyword_set(get_name) then return, the_vinfo[species]
    if keyword_set(update) then load_data = 1
    if load_data eq 0 then return, the_vinfo[species]
    
    
;---Load needed data.
    ; this is adopted from thm_load_esansst2.
    b_var = prefix+'fgs_dsl'
    vsc_var = prefix+'esa_pot'
    unit = 'flux'
    
    ; prepare for loading data.
    thm_load_state, probe=probe, /get_supp, trange=time_range
    thm_load_fit, probe=probe,coord='dsl',suff='_dsl', trange=time_range
    

    foreach the_species, ['e','i'] do begin
        vinfo = the_vinfo[the_species]
        ct = get_ct(the_species)        
        
    ;---Load the combined particle distribution data.
        esa_type = 'pe'+the_species+'r'
        sst_type = 'ps'+the_species+'f'
        combo_dist = thm_part_combine(probe=probe, trange=time_range, $
            esa_datatype=esa_type, sst_datatype=sst_type, $
            orig_esa=esa_dist, orig_sst=sst_dist, $
            sst_sun_bins=sst_mask, energies=energy_bins, unit=unit)
        if id eq 'esa%sst' then begin
            the_dist = combo_dist
            orig_var = prefix+'pt'+the_species+'rf_flux_energy'
            zrange = (the_species eq 'e')? [1e1,1e9]: [1e-2,1e8]
        endif else if id eq 'esa' then begin
            the_dist = esa_dist
            orig_var = prefix+'pe'+the_species+'r_flux_energy'
            zrange = (the_species eq 'e')? [1e4,1e9]: [1e4,1e8]
        endif else if id eq 'sst' then begin
            the_dist = sst_dist
            orig_var = prefix+'ps'+the_species+'f_flux_energy'
            zrange = (the_species eq 'e')? [1e1,1e4]: [1e-2,1e4]
        endif
        
    ;---Calculate the components.
        foreach key, vinfo.keys() do begin
            pitch_angle_range = pa_settings[key]
            del_data, orig_var
            thm_part_products, dist_array=the_dist, outputs='fac_energy', $
                sc_pot_name=vsc_var, mag_name=b_var, pitch=pitch_angle_range, units=unit
            if tnames(orig_var) eq '' then errmsg = 'No valid data ...'
            if errmsg ne '' then return, retval
            spec_var = rename_var(orig_var, output=vinfo[key])
            get_data, spec_var, times, data, val, limits=lim
            data *= 1e3 ; convert from #/cm!U2-s-sr-eV to #/cm!U2-s-sr-keV.
            store_data, spec_var, times, data, val

            add_setting, spec_var, smart=1, dictionary($
                'display_type', 'spec', $
                'unit', '#/cm!E2!N-s-sr-keV', $
                'zrange', zrange, $
                'species_name', species_name, $
                'ytitle', 'Energy!C(eV)', $
                'ylog', 1, $
                'zlog', 1, $
                'color_table', ct, $
                'short_name', '')
        endforeach
        
        foreach key, vinfo.keys() do begin
            add_setting, var, dictionary('requested_time_range', time_range)
        endforeach
    endforeach
    
    return, the_vinfo[species]

end

time_range = time_double(['2017-03-09/07:00','2017-03-09/09:00'])
probes = ['d','e']
species = ['e','p']
probes = 'd'
species = 'p'
update = 0
id = 'esa%sst'
foreach the_species, species do begin
    foreach probe, probes do begin
        vinfo = themis_read_en_spec_combo(time_range, probe=probe, $
            species=the_species, id=id, update=update)
        stop
    endforeach
endforeach
end