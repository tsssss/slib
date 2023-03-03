;+
; Read high energy electron and ion fluxes.
;-
function goes_read_kev_flux, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, no_spec=no_spec


    time_range = time_double(input_time_range)
    prefix = probe+'_'
    if strmid(probe,0,1) ne 'g' then prefix = 'g'+probe+'_'
    vars = prefix+'kev_'+['e','p']+'_flux'
    if keyword_set(get_name) then return, vars

    retval = ''
    e_var = goes_read_kev_electron(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    p_var = goes_read_kev_proton(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    return, vars

end

probes = ['11','12','13']
time_range = time_double(['2008-01-19/06:00','2008-01-19/09:00'])
foreach probe, probes do var = goes_read_kev_flux(time_range, probe=probe)
end