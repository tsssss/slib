;+
; Read DMSP orbit. 
; This is wrapper to try various data sources.
; all data sources are essentially the same. noaa dis has step.
;-

function dmsp_read_mlat_vars, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name, suffix=suffix, _extra=ex

    sources = ['madrigal','cdaweb','noaa']
    foreach source, sources do begin
        func_name = 'dmsp_read_mlat_vars_'+source
        retval = call_function(func_name, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name, suffix='', _extra=ex)
        if errmsg eq '' then return, retval
    endforeach


end