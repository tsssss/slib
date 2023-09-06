;+
; Read RBSP B1 B field, UVW.
;-
pro rbsp_read_burst_bfield, time, probe=probe, prefix=pre0, datarate=dt

    if n_elements(pre0) eq 0 then pre0 = 'rbsp'+probe+'_'
    pre1 = 'rbsp'+probe+'_'

    rbsp_read_efw, time, id='l1%mscb1', probe=probe, errmsg=errmsg
    b0var = pre1+'efw_mscb1'

    ; Adopted from rbsp_load_efw_waveform, rbsp_efw_cal_waveform.
;    timespan, time[0], time[1]-time[0], /second
;    rbsp_efw_cal_waveform, probe=probe, datatype='mscb1', trange=time
    cp0 = rbsp_efw_get_cal_params(time[0])
    cp = (probe eq 'a')? cp0.a: cp0.b

    ; Convert ADC counts into physical units
    gain = cp.ADC_gain_MSC
    offset = cp.ADC_offset_MSC
    get_data, b0var, times, data & data = float(data)
    for ii= 0,2 do data[*,ii] = (data[*,ii]-offset[ii])*gain[ii]
    tmp = rbsp_efw_deconvol_inst_resp({x:times, y:data}, probe, 'mscb1')
    data = tmp.y & tmp = 0
    ; Boost signal by 19dB, if necessary
    gain19dB = rbsp_efw_emfisis_scm_gain_list()
    time_ranges = (probe eq 'a')? $
        [[gain19dB.rbspa_on_start],[gain19dB.rbspa_on_stop]]: $
        [[gain19dB.rbspb_on_start],[gain19dB.rbspb_on_stop]]
    time_ranges = time_double(time_ranges)
    ntime_range = n_elements(time_ranges)/2
    for ii=0, ntime_range-1 do begin
        time_range = reform(time_ranges[ii,*])
        index = where_pro(times, time_range, count=count)
        if count eq 0 then continue
        data[index,*] = data[index,*]*10^(19./20.)
    endfor
    store_data, b0var, times, data

    bvar = pre0+'bb_uvw'
    rename_var, pre1+'efw_mscb1', to=bvar
    add_setting, bvar, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B1 B', $
        coord: 'UVW', $
        coord_labels: ['u','v','w'], $
        colors: sgcolor(['red','green','blue'])}

    ; find data rate.
    if n_elements(dt) eq 0 then begin
        get_data, bvar, times
        dt = sdatarate(times)
        dt = 2d^round(alog(dt)/alog(2)) ; must be integer power of 2: 512,1024,4096,16384,etc.
    endif

    if dt gt 0 then uniform_time, bvar, dt

end

time = time_double(['2013-06-10/05:57:20','2013-06-10/05:59:40']) ; a shorter time range for test purpose.
probe = 'b'

time = time_double(['2019-04-11/15:33','2019-04-11/16:33'])
probe = 'b'

rbsp_read_burst_bfield, time, probe=probe
end
