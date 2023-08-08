;+
; Read DMSP orbit. Default in gsm.
; This is wrapper to try various data sources.
; madrigal is most updated but has spikes; cdaweb is of best quality but only before 2026;
; noaa is not checked closely.
;-

function dmsp_read_orbit, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_name, suffix=suffix, _extra=ex

    sources = ['madrigal','noaa','cdaweb']
    foreach source, sources do begin
        func_name = 'dmsp_read_orbit_'+source
        retval = call_function(func_name, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_name, suffix='', _extra=ex)
        if errmsg eq '' then return, retval
    endforeach


end