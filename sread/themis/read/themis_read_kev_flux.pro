;+
; Read high energy electron and ion fluxes.
;-
function themis_read_kev_flux, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, spec=spec, energy_range=energy_range

    e_var = themis_read_kev_electron(input_time_range, probe=probe, get_name=1)
    p_var = themis_read_kev_proton(input_time_range, probe=probe, get_name=1)
    vars = [e_var,p_var]
    if keyword_set(get_name) then return, vars


    errmsg = ''
    retval = ''
    e_var = themis_read_kev_electron(input_time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    p_var = themis_read_kev_proton(input_time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval


    return, vars

end

time_range = ['2008-01-19/06:00','2008-01-19/09:00']
probes = themis_probes()
probes = ['e','d','a']
plot_vars = list()
foreach probe, probes do begin
    vars = themis_read_kev_flux(time_range, probe=probe, spec=1)
;    ylim, vars, 30, 600, 1
;    options, vars, 'ytickv', [30,300]
;    options, vars, 'yticks', 1
;    options, vars, 'yminor', 10
    plot_vars.add, vars, extract=1
endforeach
plot_vars = plot_vars.toarray()
end