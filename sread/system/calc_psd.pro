;+
; Calculate the power spectral density (PSD) using wavelet or FFT.
; Save var_[psd_cwt,psd_dft, cwt,dft, coi,wps].
; 
; x_n. An array of N numbers.
; t_n. An array of N times. Must be uniform in sample rate.
; 
; scales. Set scales, otherwise automatically calculate the scale.
; wavelet. A string sets the mother wavelet. 'morlet', 'paul', 'dog'.
; param. A number sets the parameter for the mother wavelet. 2 or 6 for dog. No effect for morlet or paul. 
;-
pro calc_psd, var, scales = scales, wavelet=wavelet, param=param

    ; get data.
    if tnames(var) eq '' then message, 'Cannot find var: '+var+' ...'
    get_data, var, t_n, x_n
    if size(x_n, /n_dimensions) ne 1 then message, 'Data needs to be a scalar ...'
    index = where(finite(x_n,/nan), count)
    if count ne 0 then x_n[index] = 0
    unit = get_setting(var, 'unit', exist)
    if not exist then unit = ''
    short_name = get_setting(var, 'short_name', exist)
    if not exist then short_name = ''
    f_unit = 'Hz'
    
    ; spec of the signal.
    N = n_elements(x_n)
    dt = t_n[1]-t_n[0]
    T = t_n[N-1]-t_n[0]
    x_n -= mean(x_n)
    sigma = stddev(x_n)
    sigma2 = sigma^2
    
    ; settings for PSD.
    conf = 0.95
    wvinfo = wavelet_info(wavelet, param)
    c_coi = wvinfo[0]
    dof0 = wvinfo[1]
    dj0 = wvinfo[2]
    gamma0 = wvinfo[3]
    cdelta = wvinfo[4]
    psi0 = wvinfo[5]
    s2t = wvinfo[6]
    t2s = wvinfo[7]
    freq_range = 1/[T,dt]
    
    s_j = (keyword_set(scales))? scales: wavelet_make_scale(s0=dt*2*t2s, sJ=T*0.5*t2s, dj=0.125d)
    J = n_elements(s_j)
    s0 = s_j[0]
    dj = alog(s_j[1]/s_j[0])/alog(2)
    
    ; Calc COI. cone of influence.
    coi = (T*0.5-abs(t_n-t_n[0]-T*0.5))*c_coi*s2t
    tvar = var+'_coi'
    store_data, tvar, t_n, coi
    add_setting, tvar, /smart, {$
        display_type: 'scalar', $
        unit: f_unit, $
        short_name: 'COI', $
        ylog: 1, $
        yrange: freq_range}
    
    
    ; Calc CWT. Continuous wavelet transform. w_nj.
    w_nj = wv_cwt(x_n, wavelet, param, dscale=dj, start_scale=s0/dt, nscale=J, scale=s_j, /pad)
    s_j *= dt
    tau_j = s_j*s2t
    f_j = 1d/tau_j
    store_data, var+'_cwt', 0, {$
        w_nj: w_nj, $
        s_j: s_j, $
        c_coi: c_coi, $
        dof0: dof0, $
        dj0: dj0, $
        gamma0: gamma0, $
        cdelta: cdelta, $
        psi0: psi0, $
        s2t: s2t, $
        t2s: t2s, $
        N: N, $
        dt: dt, $
        J: J, $
        dj: dj, $
        s0: s0, $
        sJ: s_j[-1], $
        sigma: sigma, $
        sigma2: sigma2, $
        conf: conf}

    
    ; Calc WPS, Wavelet power spectrum.
    wps_nj = abs(w_nj)^2
    zrange = ceil(alog10(minmax(wps_nj)))+[0,-1]
    zrange = (zrange[1]-zrange[0] lt 1)? minmax(wps_nj): 10d^zrange
    tvar = var+'_wps'
    store_data, tvar, t_n, wps_nj, f_j
    add_setting, tvar, /smart, {$
        display_type: 'spec', $
        unit: unit+'!U2!N', $
        short_name: short_name+' Power', $
        zlog: 1, $
        zrange: zrange, $
        ytitle: 'Freq ('+f_unit+')', $
        ylog: 1, $
        yrange: freq_range}
        
    
    ; Calc GWS. Global wavelet spectrum.
    gws_j = total(wps_nj,1)/N    
    ; Calc PSD. Power spectral density.
    psd_j = gws_j*2*s2t*dt/cdelta
    tvar = var+'_psd_cwt'
    store_data, tvar, f_j, psd_j
    add_setting, tvar, /smart, {$
        display_type: 'plot', $
        short_name: short_name+' PSD', $
        ytitle: short_name+' PSD ('+unit+'!U2!N/Hz)', $
        ylog:1, $
        xtitle: 'Freq ('+f_unit+')', $
        xlog:1, $
        xrange: freq_range}

    
    ; Calc DFT. Discrete Fourier transform.
    x_k = fft(x_n)
    f_k = findgen(N)/T
    tvar = var+'_dft'
    store_data, tvar, {$
        x_k: x_k, $
        f_k: f_k, $
        N: N, $
        dt: dt, $
        sigma: sigma, $
        sigma2: sigma2, $
        conf: conf}
    
    ; Calc FPS. Fourier power spectrum.
    fps_k = 2*abs(x_k[1:N*0.5])^2
    f_k = f_k[1:N*0.5]
    
    ; Calc PSD. Power spectral density.
    psd_k = fps_k*T
    tvar = var+'_psd_dft'
    store_data, tvar, f_k, psd_k
    add_setting, tvar, /smart, {$
        display_type: 'plot', $
        short_name: short_name+' PSD', $
        ytitle: short_name+' PSD ('+unit+'!U2!N/Hz)', $
        ylog:1, $
        xtitle: 'Freq ('+f_unit+')', $
        xlog:1, $
        xrange: freq_range}
    
    ; Set PSD of DFT and CWT the same yrange.
    yrange = ceil(alog10(minmax([psd_j,psd_k])))+[0,-1]
    yrange = (yrange[1]-yrange[0] lt 1)? minmax([psd_j,psd_k]): 10d^yrange
    options, var+['_psd_dft','_psd_cwt'], 'yrange', yrange
    
end


utr0 = time_double(['2013-06-07/04:45','2013-06-07/05:15'])
probe = 'a'
pre0 = 'rbsp'+probe+'_'

rbsp_read_bfield, utr0, probe
rbsp_read_orbit, utr0, probe
read_geopack_info, pre0+'r_gsm', prefix=pre0
calc_db, pre0+'b_gsm', pre0+'bmod_gsm'
sys_magnitude, pre0+'db_gsm', to=pre0+'dbmag'
calc_psd, pre0+'dbmag'

end