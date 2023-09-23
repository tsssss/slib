;+
; Calculate moments use esa and sst.
;
; Internal function, does not check input closely.
; This is a wrapper of Jiang Liu's thm_load_esansst2
;
; Vectors returned are in gsm.
;-

function themis_read_moment_combo_esa_sst, input_time_range, probe=probe, $
    errmsg=errmsg, species=species0, update=update, get_name=get_name

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
    coord = 'themis_dsl'
    
    
;---Init return value and determine if load data.
    the_vinfo = dictionary()
    load_data = 0
    foreach the_species, ['e','i'] do begin
        type = 'pt'+the_species+'x'
        prefix1 = prefix+type+'_'
        the_species1 = the_species
        if the_species1 eq 'i' then the_species1 = 'p'
        prefix2 = prefix+the_species1+'_'   ; we save data in e and p in tplot.

        vinfo = dictionary($
            'n', prefix2+'n', $             ; density.
            'tavg', prefix2+'tavg', $       ; average temperature.
            'pavg', prefix2+'pavg', $       ; average pressure.
            'vth', prefix2+'vth', $         ; thermal velocity.
            'vbulk', prefix2+'vbulk_'+coord, $  ; bulk velocity.
            'nflux', prefix2+'nflux_'+coord, $  ; number flux.
            'eflux', prefix2+'eflux_'+coord, $  ; energy flux.
            'keflux', prefix2+'keflux_'+coord, $; kinetic energy flux.
            'enthalpy', prefix2+'enthalpy_'+coord, $    ; enthalpy flux.
            'hflux', prefix2+'hflux_'+coord, $  ; heat flux.
            ;'t3', prefix2+'t3', $           ; temperature in DSL.
            ;'magt3, prefix2+'magt3', $      ; temperature in FAC.
            'ptens', prefix2+'ptens' )      ; pressure tensor, nPa, for completeness.
            
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

    ; prepare for loading data.
    ; thx_fgs_dsl not needed here b/c we do not need magt3 etc.
    ;thm_load_state, probe=probe, /get_supp, trange=time_range
    ;thm_load_fit, probe=probe,coord='dsl',suff='_dsl', trange=time_range
    ;thm_cotrans, prefix+'fgs_dsl', prefix+'fgs_gsm', in_coord='dsl', out_coord='gsm'
    
    ; load esa.
    thm_load_esa_pot, sc=probe, trange=time_range
    thm_load_esa_pkt, probe=probe, trange=time_range
    
    ; contamination removal.
    thm_part_moments, probe=probe, instrum = ['peir','peer'], scpot_suffix='_esa_pot', $
        trange=time_range, mag_suffix='_fgs_dsl', tplotnames=tn, $
        verbose=2, bgnd_remove=1

    ; load sst.
    thm_load_sst2, probe=probe, trange=time_range
    
    ; contamination removal
    nbin = 64
    ibins2mask = intarr(nbin)+1
    invalid_bin_idxs = [0,8,16,24,32,40,47,48,55,56]
    ibins2mask[invalid_bin_idxs] = 0
    thm_part_moments, probe=probe, instrum='psif', $
        trange=time_range, mag_suffix='_fgs_dsl', tplotnames=tn, $
        sun_bins=ibins2mask, enoise_remove_method='fill', $
        verbose=2, sst_cal=1; new names are output into tn
        
    ebins2mask = intarr(nbin)+1
    invalid_bin_idxs = [0,8,24,32,40,47,48,55,56]
    ebins2mask[invalid_bin_idxs] = 0
    thm_part_moments, probe=probe, instrum='psef', $
        trange=time_range, mag_suffix='_fgs_dsl', tplotnames=tn, $
        sun_bins=ebins2mask, enoise_remove_method='fill', $
        verbose=2, sst_cal=1; new names are output into tn
        
        
;---Convert to the wanted format.
    ; We have [density,flux,eflux,mftens,velocity,ptens] for [psif,peir] and [psef,peer].
    ; Combine psif and peir
    ; Combine psef and peer
    
    ; Constants.
    mp = 1.67d-27   ; kg.
    qe = 1.6d-19    ; Coulume.
    idx6 = [0,4,8,1,2,5]    ; map from matrix[3x3] to vec[6].
    idx3x3 = [[0,3,4],[3,1,5],[4,5,2]]  ; from vec[6] to matrix[3x3].
    deg = 180d/!dpi
    rad = !dpi/180d
    
    foreach the_species, ['e','i'] do begin
        vinfo = the_vinfo[the_species]
        type = 'pt'+the_species+'x'
        prefix1 = prefix+type+'_'
        prefix_esa = prefix+'pe'+the_species+'r_'
        prefix_sst = prefix+'ps'+the_species+'f_'

        ; These basic integrated quantities can be directly added.
        add_types = ['density','flux','eflux','ptens']
        foreach data_type, add_types do begin
            esa_data = get_var_data(prefix_esa+data_type, times=times)
            sst_data = get_var_data(prefix_sst+data_type, at=times)
            the_data = esa_data+sst_data
            the_var = prefix1+data_type
            store_data, the_var, times, the_data
        endforeach


    ;---Integrated quantities.
    
        ; density.
        var = vinfo['n']
        tmp = rename_var(prefix1+'density', output=var)
        add_setting, var, smart=1, dictionary($
            'display_type', 'scalar', $
            'short_name', 'N', $
            'unit', 'cm!U-3!N' )

        ; number flux.
        var = vinfo['nflux']
        tmp = rename_var(prefix1+'flux', output=var)
        add_setting, var, smart=1, dictionary($
            'display_type', 'vector', $
            'short_name', 'F', $
            'unit', '#/cm!U2!N-s', $
            'coord', coord )
        
        ; energy flux. Originally in eV/cm^2-s.
        c_eflux = 1.6e-12   ; this converts the unit to mW/m^2.
        var = vinfo['eflux']
        tmp = rename_var(prefix1+'eflux', output=var)
        get_data, var, times, eflux
        ndim = 3
        for ii=0,ndim-1 do eflux[*,ii] *= c_eflux
        store_data, var, times, eflux
        add_setting, var, smart=1, dictionary($
            'display_type', 'vector', $
            'short_name', 'Eflux', $
            'unit', 'mW/m!U2!N', $
            'coord', coord )
        
        ; pressure tensor. Originally in eV/cm^3
        c_pressure = 1.6e-4 ; this converts the unit to nPa.
        var = vinfo['ptens']
        tmp = rename_var(prefix1+'ptens', output=var)
        get_data, var, times, ptens
        for ii=0,n_elements(idx6)-1 do ptens[*,ii] *= c_pressure
        store_data, var, times, ptens
        add_setting, var, dictionary('unit','nPa')
        
        
        ; Make sure these quantities are on the same times.
        common_times = get_var_time(vinfo['n'])
        foreach key, ['nflux','eflux','ptens'] do interp_time, vinfo[key], common_times
        
        
    ;---Derived quantities.
        dens = get_var_data(vinfo['n'], times=times)
        nflux = get_var_data(vinfo['nflux'])
        eflux = get_var_data(vinfo['eflux'])
        ptens = get_var_data(vinfo['ptens'])
        ntime = n_elements(common_times)
        mass_kg = (species eq 'i')? 1.67e-27: 0.91e-30
        mass = mass_kg/qe*1e6   ; so that sqrt(mass/E(eV)) in km/s.
    
        ; bulk velocity.
        vbulk = fltarr(ntime,ndim)
        for ii=0,ndim-1 do vbulk[*,ii] = nflux[*,ii]/dens*1e-5
        var = vinfo['vbulk']
        store_data, var, times, vbulk
        add_setting, var, id='velocity', dictionary('coord', coord)

        
        ; kinetic energy flux.
        keflux = fltarr(ntime,ndim)
        tmp = 0.5*dens*mass*total(vbulk^2,2)    ; in eV.
        for ii=0,ndim-1 do keflux[*,ii] = tmp*vbulk[*,ii]*1e5*c_eflux
        var = vinfo['keflux']
        store_data, var, times, keflux
        add_setting, var, smart=1, dictionary($
            'display_type', 'vector', $
            'short_name', 'KEflux', $
            'unit', 'mW/m!U2!N', $
            'coord', coord )
                    

        ; average temperature.
        p3x3 = ptens[*,idx3x3]  ; [n,9]
        t3x3 = p3x3/c_pressure
        for ii=0,ndim^2-1 do t3x3[*,ii] /= dens
        tavg = total(t3x3[*,[0,4,8]],2)/ndim
        var = vinfo['tavg']
        store_data, var, times, tavg
        add_setting, var, smart=1, dictionary($
            'display_type', 'scalar', $
            'short_name', 'T', $
            'unit', 'eV' )
        
        ; average pressure.
        pavg = total(p3x3[*,[0,4,8]],2)/ndim
        var = vinfo['pavg']
        store_data, var, times, pavg
        add_setting, var, smart=1, dictionary($
            'display_type', 'scalar', $
            'short_name', 'P', $
            'unit', 'nPa' )
        
        ; thermal speed.
        vth = sqrt(2*tavg/mass)
        var = vinfo['vth']
        store_data, var, times, vth
        add_setting, var, smart=1, dictionary($
            'display_type', 'scalar', $
            'short_name', 'V!Dth!N', $
            'unit', 'km/s' )
        
        ; enthalpy.
        enthalpy = fltarr(ntime,ndim)
        tmp = 2.5*pavg/c_pressure*1.6e-7
        for ii=0,ndim-1 do enthalpy[*,ii] = tmp*vbulk[*,ii]
        var = vinfo['enthalpy']
        store_data, var, times, enthalpy
        add_setting, var, smart=1, dictionary($
            'display_type', 'vector', $
            'short_name', 'Enthalpy', $
            'unit', 'mW/m!U2!N', $
            'coord', coord )
            
        ; heat flux.
        hflux = eflux-keflux-enthalpy
        var = vinfo['hflux']
        store_data, var, times, hflux
        add_setting, var, smart=1, dictionary($
            'display_type', 'vector', $
            'short_name', 'Hflux', $
            'unit', 'mW/m!U2!N', $
            'coord', coord )

        ; t3.
        ; t3 = fltarr(ntime,ndim)
        ; Notes for moments_3d:
        ; symm is the unit vector of the magnetic field (in DSL?)
        ; t3evec[*,2] is the eigenvector of the magnetic field direction


        ; magt3.
        ; This requires B field and R in DSL.
        ; Following Line 229 to 238 in thm_load_mom.

        foreach key, vinfo.keys() do begin
            add_setting, var, dictionary('requested_time_range', time_range)
        endforeach            
    endforeach

    return, the_vinfo[species]

end


time_range = time_double(['2017-03-09/06:30','2017-03-09/09:00'])
probe = 'e'

vinfo = themis_read_moment_combo_esa_sst(time_range, probe=probe, species='i')
end