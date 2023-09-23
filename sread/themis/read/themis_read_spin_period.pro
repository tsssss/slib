;+
; Read Themis spin period.
;-

function themis_read_spin_period, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name

    errmsg = ''
    retval = ''

    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif

;---Var name.
    prefix = 'th'+probe+'_'
    var = prefix+'spin_period'
    if keyword_set(get_name) then return, var

;---Prepare files.
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var
    files = themis_load_ssc(time_range, probe=probe, id='l1%state')

    
;---Read data.
    var_list = list()
    in_vars = prefix+'spinper'
    out_vars = prefix+'spin_period'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix+'state_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

;---Post-processing.
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'Spin period', $
        'unit', 'sec' )
    return, var

end


time_range = ['2017-03-09','2017-03-10']
probe = 'd'
vars = list()
vars.add, themis_read_spin_period(time_range, probe=probe)
vars.add, themis_read_spin_phase(time_range, probe=probe)
vars = vars.toarray()
sgopen, 0, size=[6,6]
tplot, vars, trange=time_range
end