;+
; Calculate moments by integrating a combined distribution of esa and sst.
; This is adopted from Jiang Liu's thm_load_esansst2
;
; Vectors returned are in themis_dsl.
;-

function themis_read_moment_combo_esa_sst_integrate, input_time_range, probe=probe, $
    id=id, species=species0, $
    errmsg=errmsg, get_name=get_name, update=update

    errmsg = ''
    retval = ''

;---Check input.
    ; probe.
    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'

    ; species.
    if n_elements(species0) eq 0 then species0 = 'i'
    ; species is used for original spedas routines. in 'e' and 'i'.
    species = species0
    if species eq 'p' then species = 'i'
    if ~themis_esa_species_is_valid(species) then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif
    ; species1 is used for uniformed species info. in 'e' and 'p'.
    species1 = species
    if species1 eq 'i' then species1 = 'p'
    
    
    ; time_range and coord.
    time_range = time_double(input_time_range)
    coord = 'themis_dsl'
    
    ; id.
    if n_elements(id) eq 0 then id = 'esa_sst'


;---Init return value and determine if load data.
    load_data = 0
    prefix1 = prefix+species1+'_'   ; we save data in e and p in tplot.

    vinfo = dictionary($
        'n', prefix1+'n', $             ; density.
        'tavg', prefix1+'tavg', $       ; average temperature.
        'pavg', prefix1+'pavg', $       ; average pressure.
        'vth', prefix1+'vth', $         ; thermal velocity.
        'vbulk', prefix1+'vbulk_'+coord, $  ; bulk velocity.
        'nflux', prefix1+'nflux_'+coord, $  ; number flux.
        'eflux', prefix1+'eflux_'+coord, $  ; energy flux.
        'keflux', prefix1+'keflux_'+coord, $; kinetic energy flux.
        'enthalpy', prefix1+'enthalpy_'+coord, $    ; enthalpy flux.
        'hflux', prefix1+'hflux_'+coord, $  ; heat flux.
        ;'t3', prefix1+'t3', $           ; temperature in DSL.
        ;'magt3, prefix1+'magt3', $      ; temperature in FAC.
        'ptens', prefix1+'ptens' )      ; pressure tensor, nPa, for completeness.
        
    foreach key, vinfo.keys() do begin
        var = vinfo[key]
        if check_if_update(var, time_range) then begin
            load_data = 1
            break
        endif
    endforeach
    if keyword_set(get_name) then return, vinfo
    if keyword_set(update) then load_data = 1
    if load_data eq 0 then return, vinfo


;---Load needed data.
    mom_dist_var = themis_read_mom_dist(time_range, probe=probe, species=species, errmsg=errmsg, update=update)
    the_dist = get_setting(mom_dist_var, id)

    ; this is adopted from thm_load_esansst2.
    b_var = prefix+'fgs_dsl'
    vsc_var = prefix+'esa_pot'
    
    ; prepare for loading data.
    thm_load_state, probe=probe, get_supp=1, trange=time_range
    thm_load_fit, probe=probe,coord='dsl',suff='_dsl', trange=time_range

;---Calculate the components.
    thm_part_products, dist_array=the_dist, outputs='moments', $
        sc_pot_name=vsc_var, mag_name=b_var


;---Integrated quantities.
    prefix2 = prefix+'pt'+species+'rf_'
    ; Constants.
    mp = 1.67d-27   ; kg.
    qe = 1.6d-19    ; Coulume.
    idx6 = [0,4,8,1,2,5]    ; map from matrix[3x3] to vec[6].
    idx3x3 = [[0,3,4],[3,1,5],[4,5,2]]  ; from vec[6] to matrix[3x3].
    

    ; density.
    var = vinfo['n']
    tmp = rename_var(prefix2+'density', output=var)
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'N', $
        'unit', 'cm!U-3!N' )

    ; number flux.
    var = vinfo['nflux']
    tmp = rename_var(prefix2+'flux', output=var)
    add_setting, var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'F', $
        'unit', '#/cm!U2!N-s', $
        'coord', coord )
    
    ; energy flux. Originally in eV/cm^2-s.
    c_eflux = 1.6e-12   ; this converts the unit to mW/m^2.
    var = vinfo['eflux']
    tmp = rename_var(prefix2+'eflux', output=var)
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
    tmp = rename_var(prefix2+'ptens', output=var)
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

    return, vinfo

end



time_range = time_double(['2017-03-09/06:30','2017-03-09/09:00'])
probe = 'e'

species = 'i'
vinfo = themis_read_moment_combo_esa_sst_integrate(time_range, probe=probe, species=species)
foreach key, vinfo.keys() do begin
    vinfo[key] = rename_var(vinfo[key],output=vinfo[key]+'_int')
endforeach
vinfo_add = themis_read_moment_combo_esa_sst(time_range, probe=probe, species=species, update=1) 
end