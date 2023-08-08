;+
; Read eflux for given species.
;-

function dmsp_read_eflux_madrigal, input_time_range, probe=probe, errmsg=errmsg, $
    species=species, get_name=get_name, suffix=suffix

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = '_madrigal'
    if n_elements(species) eq 0 then species = 'e'
    all_species = dmsp_ssj_species()
    index = where(all_species eq species, count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif

    eflux_var = prefix+species+'_eflux'+suffix
    if keyword_set(get_name) then return, eflux_var

    time_range = time_double(input_time_range)
    if ~check_if_update(eflux_var, time_range) then return, eflux_var

    files = dmsp_load_ssj_madrigal(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    ;the_var = (species eq 'e')? 'el_i_flux': 'ion_i_flux'   ; number flux?
    the_var = (species eq 'e')? 'el_i_ener': 'ion_i_ener'   ; energy flux.
    in_var = '/Data/Array Layout/1D Parameters/'+the_var
    eflux = hdf_read_var(in_var, filename=files)

;---Calibrate the data.
    time_var = '/Data/Array Layout/timestamps'
    times = hdf_read_var(time_var, filename=files)
    time_index = lazy_where(times, '[]', time_range, count=count)
    if count eq 0 then begin
        errmsg = 'No data in given time_range ...'
        return, retval
    endif
    times = times[time_index]
    eflux = eflux[time_index]
    store_data, eflux_var, times, eflux
    add_setting, eflux_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'eV/cm!U2!N-sr-s', $
        'short_name', tex2str('Gamma'), $
        'ylog', 1 )
    return, eflux_var

end


time_range = time_double(['2013-05-01/07:00','2013-05-01/10:00'])
probes = 'f'+['16','17','18']
probes = 'f18'
species = 'p'
foreach probe, probes do begin
    var1 = dmsp_read_eflux_madrigal(time_range, probe=probe, species=species)
    var2 = dmsp_read_eflux_cdaweb(time_range, probe=probe, species=species)
    vars = [var1,var2]
    tplot, vars, trange=time_range

stop
endforeach
end