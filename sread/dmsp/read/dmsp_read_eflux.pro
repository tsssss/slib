;+
; Read DMSP eflux. 
; This is wrapper to try various data sources.
; madrigal and cdaweb are the same.
;-

function dmsp_read_eflux, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name, suffix=suffix, _extra=ex

    sources = ['madrigal','cdaweb']
    foreach source, sources do begin
        func_name = 'dmsp_read_eflux_'+source
        retval = call_function(func_name, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name, suffix='', _extra=ex)
        if errmsg eq '' then return, retval
    endforeach


end