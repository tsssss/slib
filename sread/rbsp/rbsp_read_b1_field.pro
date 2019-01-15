;+
; Read RBSP B1 E/B field, UVW.
;-
pro rbsp_read_b1_field, utr0, probe
    
    pre0 = 'rbsp'+probe+'_'

    ; read 'rbspx_[eb1,mscb1]_uvw'
    timespan, utr0[0], utr0[1]-utr0[0], /second
    rbsp_load_efw_waveform, probe=tprobe, level='l1', trange=utr0, /calibrate, datatype='eb1'
    rbsp_load_efw_waveform, probe=tprobe, level='l1', trange=utr0, /calibrate, datatype='mscb1'
    
    ; merge to system.
    evar = pre0+'eb1_uvw'
    rename_var, pre0+'efw_eb1', to=evar
    add_setting, evar, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'B1 E', $
        coord: 'UVW', $
        coord_labels: ['u','v','w'], $
        colors: [6,4,2]}
    
    bvar = pre0+'bb1_uvw'
    rename_var, pre0+'efw_mscb1', to=bvar
    add_setting, bvar, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B1 B', $
        coord: 'UVW', $
        coord_labels: ['u','v','w'], $
        colors: [6,4,2]}
    
    ; find data rate.
    get_data, evar, times
    dt = sdatarate(times)
    dt = 2d^round(alog(dt)/alog(2)) ; must be integer power of 2: 512,1024,4096,16384,etc.
    uniform_time, pre0+'eb1_uvw', dt
    interp_time, pre0+'bb1_uvw', to=pre0+'eb1_uvw'
    
    ; treat spin-axis.
    vars = pre0+['eb1_uvw','bb1_uvw']
    get_data, vars[0], uts, dat
    dat[*,2] = 0
    store_data, vars[0], uts, dat
    
    store_data, pre0+'efw_eb1_*', /delete
    store_data, pre0+'efw_mscb1_*', /delete

end

utr0 = time_double(['2013-06-10/05:57:20','2013-06-10/05:59:40']) ; a shorter time range for test purpose.
rbsp_read_b1_field, utr0, 'b'
end