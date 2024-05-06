;+
; Read SC Potential.
;-

function mms_read_vsc, input_time_range, id=datatype, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, update=update, _extra=ex

    errmsg = ''
    retval = ''

    if ~mms_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'mms'+probe+'_'

    ; Prepare var name.
    var_info = prefix+'vsc'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    ; Load files.
    files = mms_ld_edp(time_range, probe=probe, id='l2%slow%scpot', errmsg=errmsg)
    if errmsg ne '' then return, retval
    stop

;---Read data.
    var_list = list()
    in_vars = [prefix+'edp_scpot_slow_l2']
    out_vars = [var_info]
    time_var = prefix+'edp_epoch_slow_l2'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', time_var, $
        'time_var_type', 'tt2000' )

    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    add_setting, var_info, id='bfield', dictionary($
        'mission', 'mms', $
        'probe', probe, $
        'requested_time_range', time_range, $
        'coord', default_coord )
    
    return, var_info

end