;+
; Calculate E_vxb and E_corr.
; r_var=.
; b_var=.
;-

pro themis_calc_emodel, time, r_var=r_var, b_var=b_var, probe=probe, spin_axis=sa_mode

    xyz = ['x','y','z']
    rgb = sgcolor(['red','green','blue'])
    errmsg = ''

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No probe ...')
        return
    endif
    pre0 = 'th'+probe+'_'

;---Get R GSM and calculate V GSM.
    if n_elements(r_var) eq 0 then r_var = pre0+'r_gsm'
    if check_if_update(r_var, time) then themis_read_orbit, time, probe=probe
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
    if check_if_update(b_var, time) then b_var = pre0+'b_gsm'
    if tnames(b_var) eq '' then themis_read_bfield, time, probe=probe
    b_gsm = get_var_data(b_var, at=times)

;---Calculat E = vxB. This v is v_sc, already -v in the plasma frame.
    evxb_gsm = vec_cross(v_gsm,b_gsm)*1e-3   ; convert to mV/m.
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
    vcoro_gsm = cotran(vcoro_gei, times, 'gei2gsm')
    ecoro_gsm = scross(vcoro_gsm, b_gsm)
    ecoro_var = pre0+'ecoro_gsm'
    store_data, ecoro_var, times, ecoro_gsm
    add_setting, ecoro_var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'Coro E', $
        coord: 'GSM', $
        coord_labels: xyz, $
        colors: rgb}

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