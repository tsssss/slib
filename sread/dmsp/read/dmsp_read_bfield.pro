;+
; Read DMSP B field.
;-

function dmsp_read_bfield, input_time_range, probe=probe, errmsg=errmsg, $
    get_name=get_name, suffix=suffix, read_b0=read_b0, _extra=ex

    sources = ['madrigal','cdaweb','noaa']
    foreach source, sources do begin
        func_name = 'dmsp_read_bfield_'+source
        retval = call_function(func_name, input_time_range, probe=probe, $
            errmsg=errmsg, get_name=get_name, suffix='', read_b0=read_b0, _extra=ex)
        if errmsg eq '' then return, retval
    endforeach

end