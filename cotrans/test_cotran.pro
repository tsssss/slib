
;---Test against a previous version.
    r_gsm = [-5.1,0.3,2.8]
    time = time_double('2001-01-01/02:03:04')

    r_gse = gsm2gse(r_gsm, time)
    r_sm = gsm2sm(r_gsm, time)
    r_gei = gse2gei(r_gse, time)
    r_geo = gei2geo(r_gei, time)
    r_mag = geo2mag(r_geo, time)
    
    print, r_gsm
    print, r_geo
    print, r_gse
    print, r_sm
    print, r_mag
    print, r_gei


    epoch = stoepoch(time, 'unix')

    r_gse = sgsm2gse(r_gsm, epoch)
    r_sm = sgsm2sm(r_gsm, epoch)
    r_gei = sgse2gei(r_gse, epoch)
    r_geo = sgei2geo(r_gei, epoch)
    r_mag = sgeo2mag(r_geo, epoch)

    print, r_gsm
    print, r_geo
    print, r_gse
    print, r_sm
    print, r_mag
    print, r_gei


;---Test forward and backward transforms.
    print, 'Test forward and backward transforms ...'
    print, gse2gsm(gsm2gse(r_gsm,time),time), r_gsm
    print, gsm2sm(sm2gsm(r_sm,time),time), r_sm
    print, gse2gei(gei2gse(r_gei,time),time), r_gei
    print, gei2geo(geo2gei(r_geo,time),time), r_geo
    print, geo2mag(mag2geo(r_mag,time),time), r_mag
    
    
;---Test mgse<->gse.
; R MGSE should be:
;      -3.9254099      0.97749642       4.1923331
; For R GSE:
;      -5.0999999      0.90601232       2.6662973
; at 2013-01-01/02:03:04.

    time = time_double('2013-01-01/02:03:04')

    probe = 'a'
    r_mgse = gse2mgse(r_gse, time, wsc=wsc, probe=probe)
    print, mgse2gse(r_mgse, time, wsc=wsc, probe=probe)
    
    rbsp_efw_init
    time_range = time+[-1,1]*60
    timespan, time_range[0], time_range[1]-time_range[0], /second
    rbsp_load_spice_kernels
    pre0 = 'rbsp'+probe+'_'
    rgse_var = pre0+'r_gse'
    rmgse_var = pre0+'r_mgse'
    store_data, rgse_var, time+[0,60], transpose([[r_gse],[r_gse]])
    rbsp_mgse2gse, rgse_var, wgse, newname=rmgse_var, /inverse, /no_spice_load, probe=probe
    print, get_var_data(rmgse_var, at=time)
    print, r_mgse

end