;+
; Read spacecraft potential.
;-

function themis_read_sc_potential, input_time_range, probe=probe, $
    get_name=get_name, _extra=ex


    prefix = 'th'+probe+'_'
    errmsg = ''
    retval = ''

    var = prefix+'vsc'
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var
    
    files = themis_load_efi(time_range, probe=probe, errmsg=errmsg, id='l1%vaf')
    if errmsg ne '' then return, retval

    var_list = list()
    in_var = prefix+'vaf'
    var_list.add, dictionary($
        'in_vars', in_var, $
        'out_vars', in_var, $
        'time_var_name', in_var+'_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval


    vsvy = get_var_data(in_var, times=times)
    thm_init
    thm_get_efi_cal_pars, times, 'vaf', probe, cal_pars=cp
    ntime = n_elements(times)
    ndim = 4
    vsvy = float(vsvy[*,0:ndim-1])  ; convert to physical unit and convert to float.
    for ii=0,ndim-1 do vsvy[*,ii] *= cp.gain[ii]
    vsc = fltarr(ntime)
    ; boom length not the same, so should I still use median of all 4 spin plane booms?
    for ii=0,ntime-1 do vsc[ii] = median(vsvy[ii,*])

    store_data, var, times, vsc
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'unit', 'V', $
        'short_name', 'Vsc', $
        'requested_time_range', time_range )
    return, var
    
end



time_range = time_double(['2017-03-09','2017-03-10'])
probe = 'd'
var = themis_read_sc_potential(time_range, probe=probe)
end