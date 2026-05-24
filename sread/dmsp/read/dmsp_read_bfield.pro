;+
; Read DMSP B field.
;-

function dmsp_read_bfield, input_time_range, probe=probe, errmsg=errmsg, $
    get_name=get_name, suffix=suffix, get_b0=get_b0, keep_baseline=keep_baseline, _extra=ex
    compile_opt idl2

    sources = ['madrigal','cdaweb','noaa']
    foreach source, sources do begin
        func_name = 'dmsp_read_bfield_'+source
        retval = call_function(func_name, input_time_range, probe=probe, $
            errmsg=errmsg, get_name=get_name, suffix=suffix, get_b0=get_b0, _extra=ex)
        if errmsg eq '' then begin
            if keyword_set(keep_baseline) then return, retval
            b_base_var = dmsp_read_bfield_baseline(input_time_range, probe=probe, errmsg=errmsg)
            if errmsg eq '' then begin
                b_orig = var_get_data(retval, times=times)
                b_base = var_get_data(b_base_var, at=times)
                retval = var_store(retval, b_orig-b_base, times)
            endif
            return, retval
        endif
    endforeach
    errmsg = 'No data ...'
    return, !null

end

compile_opt idl2
time_range = ['2013-05-01','2013-05-02']
probe = 'f18'
b_base_var = dmsp_read_bfield_baseline(time_range, probe=probe)
b0_var = dmsp_read_bfield_cdaweb(time_range, probe=probe)
b_var = dmsp_read_bfield(time_range, probe=probe)
plot_vars = [b_base_var, b0_var, b_var]
tplot, plot_vars, trange=time_range
end