;+
; Read high energy electron and ion fluxes.
;-
function goes_read_kev_flux, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, no_spec=no_spec


    time_range = time_double(input_time_range)
    prefix = probe+'_'
    if strmid(probe,0,1) ne 'g' then prefix = 'g'+probe+'_'
    vars = prefix+['e','p']+'_flux'
    if keyword_set(get_name) then return, vars

    retval = ''
    goes_read_kev_electron, time_range, probe=probe, errmsg=errmsg
    if errmsg ne '' then return, retval
    goes_read_kev_proton, time_range, probe=probe, errmsg=errmsg
    if errmsg ne '' then return, retval

    ct = 33
    foreach var, vars do begin
        short_name = (var eq prefix+'e_flux')? 'e-': 'H+'
        if keyword_set(no_spec) then begin
            add_setting, var, smart=1, dictionary($
                'display_type', 'list', $
                'unit', '#/cm!U-2!N-s-sr-keV', $
                'short_name', short_name, $
                'ylog', 1, $
                'color_table', ct, $
                'value_unit', 'keV' )
        endif else begin
            add_setting, var, smart=1, dictionary($
                'display_type', 'spec', $
                'unit', '#/cm!U-2!N-s-sr-keV', $
                'ylog', 1, $
                'ytitle', '(keV)', $
                'zlog', 1, $
                'color_table', ct, $
                'short_name', short_name )
        endelse
    endforeach

    return, vars

end

probes = ['11','12','13']
time_range = time_double(['2008-01-19/06:00','2008-01-19/09:00'])
foreach probe, probes do var = goes_read_kev_flux(time_range, probe=probe)
end