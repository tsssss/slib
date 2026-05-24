;+
; :Purpose: Read B baseline.
; :Returns: str, variable name.
; :Arguments:
;   input_time_range: in, required. Time range.
; :Keywords:
;   probe: in, required. 'fxx'.
;   errmsg: out, optional. Error message.
;-
function dmsp_read_bfield_baseline, input_time_range, probe=probe, errmsg=errmsg
    compile_opt idl2
    errmsg = ''
    retval = !null

    time_range = time_double(input_time_range)
    files = dmsp_load_ssm_baseline(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    base_var = 'dmsp'+probe+'_db_base'

    var_list.add, dictionary($
        'in_vars', base_var, $
        'out_vars', base_var, $
        'time_var_name', 'time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    settings = dictionary('coord', 'dmsp_xyz')
    add_setting, base_var, settings, smart=1, id='bfield'

    return, base_var
end


compile_opt idl2
time_range = ['2013-05-01','2013-05-02']
probe = 'f18'
b_base_var = dmsp_read_bfield_baseline(time_range, probe=probe)
b_var = dmsp_read_bfield_cdaweb(time_range, probe=probe)
plot_vars = [b_base_var, b_var]
tplot, plot_vars, trange=time_range
end