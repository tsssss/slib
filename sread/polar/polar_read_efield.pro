
pro polar_read_efield, time, probe=probe, errmsg=errmsg

    pre0 = 'po_'
    coord = 'gsm'

    ; read 'po_e_gsm'
    polar_read_ebv, time, id='e_spc', errmsg=errmsg
    if errmsg ne '' then return
    polar_read_quaternion, time, errmsg=errmsg
    if errmsg ne '' then return

    var = pre0+'e_spc'
    get_data, var, times, edata
    ntime = n_elements(times)
    if ntime lt 1 then begin
        errmsg = handle_error('No data ...')
        return
    endif
    index = where(finite(edata), count)
    if count eq 0 then begin
        errmsg = handle_error('No valid data ...')
        return
    endif
    edata[*,2] = 0
    for ii=0,1 do edata[*,ii] -= mean(edata[*,ii],/nan)
    store_data, var, times, edata
    
    var = pre0+'e_gsm'
    polar_spc2gsm, pre0+'e_spc', var, quaternion=pre0+'q_spc2gsm'

    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z']}

    dt = 6.
    uniform_time, var, dt

end

time = time_double(['1996-09-10','1996-09-11'])
polar_read_efield, time
end
