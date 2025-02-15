;+
; Read Polar q_spc2gsm. To replace polar_read_quaternion.
;-

function polar_read_q_spc2gsm, input_time_range, probe=probe, errmsg=errmsg, $
    get_name=get_name, update=update, suffix=suffix, _extra=ex

    prefix = 'po_'
    errmsg = ''
    retval = ''

;---Preparation.
    if n_elements(suffix) eq 0 then suffix = ''
    q_var = prefix+'q_spc2gsm'+suffix
    if keyword_set(get_name) then return, q_var
    if keyword_set(update) then del_data, q_var
    time_range = time_double(input_time_range)
    if ~check_if_update(q_var, time_range) then return, q_var

    ; Load files.
    files = polar_ld_ebv(time_range, errmsg=errmsg)
    if errmsg ne '' then return, retval

;---Read data.
    var_list = list()
    var_list.add, dictionary($
        'in_vars', 'q_spc2gsm', $
        'out_vars', q_var, $
        'time_var_name', 'ut_cotran', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval


    settings = { $
        display_type: 'stack', $
        unit: '#', $
        short_name: 'Q', $
        in_coord: 'polar_spc', $
        out_coord: 'gsm', $
        labels: ['a','b','c','d'], $
        colors: sgcolor(['red','green','blue','black'])}
    add_setting, q_var, settings, smart=1

    return, q_var

end

time_range = ['1998-09-25','1998-09-26']
var = polar_read_q_spc2gsm(time_range)
end