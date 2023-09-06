;+
; Read RBSP B1 E field, UVW.
;-
pro rbsp_read_burst_efield, time, probe=probe, prefix=pre0, datarate=dt, spin_axis=sa_mode

    if n_elements(pre0) eq 0 then pre0 = 'rbsp'+probe+'_'
    pre1 = 'rbsp'+probe+'_'

    ; 'e0': E spin-axis = 0.
    ; 'e'; E spin-axis as-is.
    ; 'edot0': Calculate E spin-axis using E dot B = 0.
    if n_elements(sa_mode) eq 0 then sa_mode = 'e0'

    rbsp_read_efw, time, id='l1%vb1', probe=probe, errmsg=errmsg
    vvar = pre1+'efw_vb1'

    ; Adopted from rbsp_load_efw_waveform, rbsp_efw_cal_waveform.
;    timespan, time[0], time[1]-time[0], /second
;    rbsp_efw_cal_waveform, probe=probe, datatype='vb1', trange=time
    cp0 = rbsp_efw_get_cal_params(time[0])
    cp = (probe eq 'a')? cp0.a: cp0.b

    ; Convert ADC counts into physical units
    gain = cp.ADC_gain_VDC
    offset = cp.ADC_offset_VDC
    get_data, vvar, times, data & data = float(data) & store_data, vvar, /delete
    for ii= 0,5 do data[*,ii] = (data[*,ii]-offset[ii])*gain[ii]

    ; Calculate the E field.
    boom_length = cp.boom_length*cp.boom_shorting_factor
    edata = data[*,0:2]
    edata[*,0] = (data[*,0]-data[*,1])/boom_length[0]
    edata[*,1] = (data[*,2]-data[*,3])/boom_length[1]
    edata[*,2] = (data[*,4]-data[*,5])/boom_length[2]
    if sa_mode ne 'e' then edata[*,2] = 0
    edata = edata*1000d     ; Convert V/m to mV/m.
    data = 0.

    max_e = 500.
    pad_i = 20
    for ii=0,1 do begin
        flags = abs(edata[*,ii]) gt max_e
        index = where(flags eq 1, count)
        if count eq 0 then continue
        for jj=0, pad_i-1 do flags = shift(flags, -1) or shift(flags, 1) or flags
        index = where(flags eq 1)
        edata[index,ii] = !values.f_nan
    endfor

    evar = pre0+'be_uvw'
    store_data, evar, times, edata
    add_setting, evar, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'B1 E', $
        coord: 'UVW', $
        coord_labels: ['u','v','w'], $
        colors: sgcolor(['red','green','blue'])}

    ; find data rate.
    if n_elements(dt) eq 0 then begin
        get_data, evar, times
        dt = sdatarate(times)
        dt = 2d^round(alog(dt)/alog(2)) ; must be integer power of 2: 512,1024,4096,16384,etc.
    endif

    if dt gt 0 then uniform_time, evar, dt

end

time = time_double(['2013-06-10/05:57:20','2013-06-10/05:59:40']) ; a shorter time range for test purpose.
probe = 'b'

time = time_double(['2019-04-11/15:33','2019-04-11/16:33'])
time = time_double(['2019-04-10/12:48','2019-04-10/13:48'])
bad_time = time_double(['2019-04-10/12:58','2019-04-10/13:03'])
;time = time_double(['2019-05-11/08:24','2019-05-11/09:24'])
probe = 'b'


;---Calculate E model.
    rbsp_calc_emodel, time, probe=probe
    emod_var = pre0+'emod_gsm'
    

;---Load hires data.
    rbsp_read_efield, time, probe=probe, resolution='hires'
    e0var = pre0+'e0_gsm'
    get_data, e0var, times, egsm
    index = where_pro(times, bad_time)
    egsm[index,*] = !values.d_nan
    store_data, e0var, times, egsm

;---Remove E_vxB.
    get_data, e0var, times, egsm, limits=lims
    get_data, emod_var, uts, e0gsm
    e0gsm = sinterpol(e0gsm, uts, times, /quadratic, /nan)
    e0mag = snorm(e0gsm)
    emag = snorm(egsm)
    index = where(finite(emag))
;    for ii=0, 2 do begin
;        fit_res = linfit(e0gsm[index,ii], egsm[index,ii])
;        egsm[*,ii] = egsm[*,ii]-fit_res[0]
;    endfor
    fit_res = linfit(e0mag[index], emag[index])
    fs_coef = fit_res[1]
    degsm = egsm/fs_coef-e0gsm
    store_data, pre0+'de0_gsm', times, degsm, limits=lims
    stop
    

;---Load burst data.
    rbsp_read_burst_efield, time, probe=probe
    pre0 = 'rbsp'+probe+'_'
    evar = pre0+'be_gsm'
    rbsp_uvw2gsm, pre0+'be_uvw', evar

;---Remove E_vxB.
    get_data, evar, times, egsm, limits=lims
    get_data, emod_var, uts, e0gsm
    e0gsm = sinterpol(e0gsm, uts, times, /quadratic)

    degsm = egsm-e0gsm
    store_data, pre0+'de_gsm', times, degsm, limits=lims
    

end
