;+
; Read high energy electron and ion fluxes.
;-

function mms_read_kev_flux, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, spec=spec, energy_range=energy_range, pitch_angle_range=pitch_angle_range

    e_var = mms_read_kev_electron(input_time_range, probe=probe, get_name=1)
    p_var = mms_read_kev_ion(input_time_range, probe=probe, get_name=1)
    vars = [e_var,p_var]
    if keyword_set(get_name) then return, vars

    errmsg = ''
    retval = ''
    e_var = mms_read_kev_electron(input_time_range, probe=probe, errmsg=errmsg, energy_range=energy_range, pitch_angle_range=pitch_angle_range)
    if errmsg ne '' then return, retval
    p_var = mms_read_kev_ion(input_time_range, probe=probe, errmsg=errmsg, energy_range=energy_range, pitch_angle_range=pitch_angle_range)
    if errmsg ne '' then return, retval

    return, vars

end

time_range = ['2015-09-01/06:00','2015-09-01/09:00']
probes = ['1','2','3','4']
plot_vars = list()
foreach probe, probes do begin
    vars = mms_read_kev_flux(time_range, probe=probe, spec=0)
    plot_vars.add, vars, extract=1
endforeach
plot_vars = plot_vars.toarray()
end