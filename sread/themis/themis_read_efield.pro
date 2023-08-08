;+
; Read Themis DC E field. Default is to read 'survey' data at 3 samples/sec.
;-
;
pro themis_read_efield, time, probe=probe, resolution=resolution, coord=coord, errmsg=errmsg

    errmsg = ''
    pre0 = 'th'+probe+'_'
    rgb = sgcolor(['red','green','blue'])

    resolution = (keyword_set(resolution))? strlowcase(resolution): '3sec'
    case resolution of
        '3sec': begin
            dt = 3
            type = 'efs'
            end
        'hires': begin
            dt = 1d/8
            type = 'eff'
            end
    endcase
    if n_elements(coord) eq 0 then coord = 'gsm'

    ; read 'thx_e_gsm'
    themis_read_efi, time, id='l2%'+type, probe=probe, coord='gsm', errmsg=errmsg
    if errmsg ne '' then return
    
    var = pre0+'e_gsm'
    var = rename_var(pre0+type+'_dot0_gsm', output=var)
    
    get_data, var, times, edata
    ntime = n_elements(times)
    ndata = n_elements(edata)/3
    if ntime ne ndata then begin
        errmsg = handle_error('Inconsistant data and time ...')
        return
    endif
    
    if coord ne 'gsm' then begin
        get_data, var, times, vec
        vec = cotran(vec, times, 'gsm2'+coord)
        var = pre0+'e_'+coord
        store_data, var, times, vec
    endif
    
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: rgb}
    uniform_time, var, dt

    ; smooth over 10 min.
    width = 600/dt
    if ntime lt width*2 then begin
        del_data, var
        errmsg = handle_error('No enough data ...')
        return
    endif
    get_data, var, times, edata
    for ii=0,2 do edata[*,ii] -= smooth(edata[*,ii],width,/edge_truncate,/nan)
    store_data, var, times, edata

;    ; remove vxB.
;    themis_calc_emodel, time, r_var=pre0+'r_gsm', b_var=pre0+'b_gsm', probe=probe
;    if errmsg ne '' then return
;    emod_var = pre0+'evxb_gsm'
;    interp_time, emod_var, to=var
;    sys_subtract, var, emod_var, to=var
;    get_data, var, times, edata
;    for ii=0,2 do edata[*,ii] -= mean(edata[*,ii],/nan)
;    store_data, var, times, edata
    

end


time = time_double(['2008-10-30','2008-10-31'])
time = time_double(['2008-01-01','2008-01-02'])
themis_read_efield, time, probe='a'
end
