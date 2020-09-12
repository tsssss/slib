;+
; Calculate E_vxb and E_corr.
; r_var=.
; b_var=.
; probe=.
; spin_axis='e0'. No other mode yet.
;-

pro rbsp_calc_emodel, time, r_var=r_var, b_var=b_var, probe=probe, spin_axis=sa_mode, errmsg=errmsg

    xyz = ['x','y','z']
    rgb = sgcolor(['red','green','blue'])
    errmsg = ''

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No probe ...')
        return
    endif
    pre0 = 'rbsp'+probe+'_'

;---Get R GSM and calculate V GSM.
    if n_elements(r_var) eq 0 then r_var = pre0+'r_gsm'
    if tnames(r_var) eq '' then rbsp_read_orbit, time, probe=probe
    get_data, r_var, times, r_gsm
    ntime = n_elements(times)
    ndim = 3
    v_gsm = fltarr(ntime,ndim)
    dt = sdatarate(times)
    re = 6378d
    for ii=0, ndim-1 do v_gsm[*,ii] = deriv(r_gsm[*,ii])*(re/dt)
    v_var = pre0+'v_gsm'
    store_data, v_var, times, v_gsm
    add_setting, v_var, /smart, {$
        display_type: 'vector', $
        unit: 'km/s', $
        short_name: 'V', $
        coord: 'GSM', $
        coord_labels: xyz, $
        colors: rgb}

;---Get B GSM.
    if n_elements(b_var) eq 0 then b_var = pre0+'b_gsm'
    if tnames(b_var) eq '' then rbsp_read_bfield, time, probe=probe, resolution='4sec', errmsg=errmsg
    b_gsm = get_var_data(b_var, at=times)
    if n_elements(b_gsm) ne ntime*3 then begin
        errmsg = handle_error('Invalid B field data ...')
        return
    endif

;---Calculat E = vxB. This v is v_sc, already -v in the plasma frame.
    evxb_gsm = scross(v_gsm,b_gsm)*1e-3   ; convert to mV/m.
    evxb_var = pre0+'evxb_gsm'
    store_data, evxb_var, times, evxb_gsm
    add_setting, evxb_var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'VxB E', $
        coord: 'GSM', $
        coord_labels: xyz, $
        colors: rgb}

;---Calculate the corrotation electric field.
    omega = (2*!dpi)/86400d  ;Earth's rotation angular frequency
    r_gei = cotran(r_gsm, times, 'gsm2gei')
    vcoro_gei = fltarr(ntime,ndim)
    vcoro_gei[*,0] = -r_gei[*,1]*omega
    vcoro_gei[*,1] =  r_gei[*,0]*omega
    vcoro_gei[*,2] = 0.0
    vcoro_gei *= re     ; convert Re/s to km/s.
    vcoro_gsm = cotran(vcoro_gei, times, 'gei2gsm')
    ecoro_gsm = scross(vcoro_gsm, b_gsm)*1e-3   ; convert to mV/m.
    ecoro_var = pre0+'ecoro_gsm'
    store_data, ecoro_var, times, ecoro_gsm
    add_setting, ecoro_var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'Coro E', $
        coord: 'GSM', $
        coord_labels: xyz, $
        colors: rgb}

    if n_elements(sa_mode) eq 0 then sa_mode = 'e0'
    foreach var, pre0+['evxb','ecoro'] do begin
        rbsp_gsm2uvw, var+'_gsm', var+'_uvw'
        get_data, var+'_uvw', times, vec_uvw
        vec_uvw[*,2] = 0
        store_data, var+'_uvw', times, vec_uvw
        rbsp_uvw2gsm, var+'_uvw', var+'_gsm'
    endforeach
    
    get_data, evxb_var, times, evxb_gsm
    get_data, ecoro_var, times, ecoro_gsm
    emod_gsm = evxb_gsm+ecoro_gsm
    emod_var = pre0+'emod_gsm'
    store_data, emod_var, times, emod_gsm
    add_setting, emod_var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'Model E', $
        coord: 'GSM', $
        coord_labels: xyz, $
        colors: rgb}

end