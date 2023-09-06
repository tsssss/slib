;+
; Plot the HOPE L2 data to show the 2D distribution in UVW within a spin.
;-

;---Load data and settings.
    test = 0

    time_range = time_string(['2015-02-18/02:05','2015-02-18/02:15'])
    time_range = time_double(['2015-02-18','2015-02-19'])
    probe = 'a'
    prefix = 'rbsp'+probe+'_'
    file = '/Volumes/Research/data/rbsp/rbspa/hope/level2/sectors_rel04/2015/rbspa_rel04_ect-hope-sci-l2_20150218_v6.1.0.cdf'


    npixel = 5
    pixels = findgen(npixel)
    polar_angles = [72d,36,0,-36,-72] ; deg.
    rad = constant('rad')
    nsector = 16
    dsector = 2*!dpi/nsector
    ; Angle at the center of each sector.
    sector_angles = findgen(nsector)*dsector+0.5*dsector


;---Load r and B.
    rbsp_read_orbit, time_range, probe=probe
    rbsp_read_sc_vel, time_range, probe=probe
    rbsp_efw_phasef_read_b_mgse, time_range, probe=probe
    get_data, prefix+'r_gse', times, r_gse
    b_mgse = get_var_data(prefix+'b_mgse', at=times)
    b_gse = cotran(b_mgse, times, 'mgse2gse', probe=probe)
    store_data, prefix+'b_gse', times, b_gse
    add_setting, prefix+'b_gse', /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', 'nT', $
        'coord', 'GSE', $
        'coord_labels', constant('xyz') )
    define_fac, prefix+'b_gse', prefix+'r_gse'
    v_gse = get_var_data(prefix+'v_gse', at=times)
    v_uvw = cotran(v_gse, times, 'gse2uvw', probe=probe)
    store_data, prefix+'v_uvw', times, v_uvw
    add_setting, prefix+'v_uvw', /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'V', $
        'unit', 'km/s', $
        'coord', 'UVW', $
        'coord_labels', constant('uvw') )

;---Load Cristian's data.
    fn = '/Users/shengtian/Downloads/rbspa_201502_vel_eflux/'+$
        'rbspa_201502_vel_eflux_30eV<E_h_1.tplot'
    tplot_restore, filename=fn
    get_data, 'V_gsm_corr_h', times, v_gsm
    v_gse = cotran(v_gsm, times, 'gsm2gse')
    store_data, 'v_gse_h', times, v_gse
    add_setting, 'v_gse_h', /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'V', $
        'unit', 'km/s', $
        'coord', 'GSE', $
        'coord_labels', constant('xyz') )
    to_fac, 'v_gse_h', to='v_fac_h', q_var=prefix+'q_gse2fac'
    options, 'v_fac_h', 'constant', 0

;---Load HOPE L2.
    ; [ntime,nen_bin,nsector,npixel].
    fpdu = cdf_read_var('FPDU', filename=file)
    times = convert_time(cdf_read_var('Epoch_Ion', filename=file), from='epoch', to='unix')
    en_bins = cdf_read_var('HOPE_ENERGY_Ion', filename=file)

    ntime = n_elements(times)
    nen_bin = n_elements(en_bins[0,*])

    ; Time of "HOPE" spin.
    time_step = 11.362  ; sec.
    times = times-time_step*0.5
    
    
    ; Spec of energy-sum flux as a function of time and sector.
    foreach pixel_id, findgen(npixel) do begin
        spec = reform(total(fpdu[*,*,*,pixel_id],2))
        pixel_str = string(pixel_id,format='(I0)')
        store_data, 'fpdu_pixel'+pixel_str, $
            times, spec, findgen(nsector), $
            limits={spec:1, no_interp:1, ylog:0, zlog:1, zrange:[1e6,1e10], $
            ytitle:'Sector #', ztitle:'H+ flux', yticklen:-0.01, xticklen:-0.05}
    endforeach


    ; Plot the spectrogram of flux vs sector and time, for each pixel.
    vars = 'fpdu_pixel'+string(findgen(npixel),format='(I0)')
    nvar = n_elements(vars)
    sgopen, 0, xsize=6, ysize=6
    margins = [12,4,10,2]
    test_time_range = time_double(['2015-02-18/02:00','2015-02-18/02:20'])
    poss = sgcalcpos(nvar,margins=margins, xchsz=xchsz, ychsz=ychsz)
    tplot, vars, position=poss, trange=test_time_range
    fig_labels = letters(nvar)
    for ii=0,nvar-1 do begin
        tpos = poss[*,ii]
        msg = fig_labels[ii]+'. Pixel '+string(ii+1,format='(I0)')
        tx = xchsz*2
        ty = tpos[3]-ychsz*0.7
        xyouts, tx,ty,/normal, msg
    endfor
    
    

    ; Spec of energy-sum flux.
    spec = total(fpdu,2)
    store_data, prefix+'fpdu', times, spec, $
        limits={sector_angle:sector_angles, polar_angle:polar_angles}

    test_time_range = time_double(['2015-02-18/02:10','2015-02-18/02:20'])
    test_time_range = time_double(['2015-02-18/02:00','2015-02-18/02:50'])
;    test_time_range = time_double(['2015-02-18/06:20','2015-02-18/06:50'])
    index = where_pro(times, '[]', test_time_range, count=ntest_time)
    test_times = times[index]
    foreach test_time, test_times, test_id do begin
        tmp = min(times-test_time, index, /absolute)
        the_time = times[index]
        print, time_string(the_time)
        the_spec = reform(spec[index,*,*])

        ct = 62
        sgopen, 0, xsize=4, ysize=9
        poss = sgcalcpos(5, xchsz=xchsz, ychsz=ychsz, rmargin=10)
        poss[[1,3],0] += ychsz*4
        poss[[1,3],1] += ychsz*4
        zrange = [6d,11]
;        zrange = [9d,11]
        zrange = [floor(zrange[0]),ceil(zrange[1])]
        zz = bytscl(alog10(the_spec), min=zrange[0], max=zrange[1], /nan)
        ;zz = bytscl(alog10(the_spec), /nan, top=254)
        xx = make_bins([0d,360-1],360d/nsector, /inner)
        yy = polar_angles

        tpos = poss[*,0]
        sgtv, reverse(zz,2), position=tpos, resize=1, ct=ct

        xrange = [0d,360]
        xstep = 90
        xtickv = make_bins(xrange, xstep)
        xticks = n_elements(xtickv)-1
        xtitle = 'Azim angle (deg)'
        xminor = 9

        yrange = [-90,90]
        ystep = 30d
        ytickv = make_bins(yrange, ystep)
        yticks = n_elements(ytickv)-1
        ytitle = 'Polar angle (deg)'
        yminor = 3

        ;    plot, xrange, yrange, $
        ;        xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xtitle=xtitle, xminor=xminor, $
        ;        ystyle=1, yrange=yrange, ytickv=ytickv, yticks=yticks, ytitle=ytitle, yminor=yminor, $
        ;        position=tpos, nodata=1, noerase=1


        device, decomposed=0
        loadct2, ct
        ncolor = 15
        colors = smkarthm(0,255,ncolor,'n')
        tpos = poss[*,1]
        levels = smkarthm(zrange[0],zrange[1],ncolor,'n')
        contour, alog10(the_spec), xx,yy, levels=levels, nlevel=ncolor, /fill, c_colors=colors, $
            xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xtitle=xtitle, xminor=xminor, $
            ystyle=1, yrange=yrange, ytickv=ytickv, yticks=yticks, ytitle=ytitle, yminor=yminor, $
            position=tpos, nodata=0, noerase=1, c_labels=replicate(1,ncolor), follow=1
        
        contour, alog10(the_spec), xx,yy, levels=levels, $
            xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xtitle=xtitle, xminor=xminor, $
            ystyle=1, yrange=yrange, ytickv=ytickv, yticks=yticks, ytitle=ytitle, yminor=yminor, $
            position=tpos, nodata=0, noerase=1, c_labels=replicate(1,ncolor), follow=1

        
        q_var = prefix+'q_gse2fac'
        get_data, q_var, qtimes, q_xxx2fac
        q_gse2fac = qslerp(q_xxx2fac, qtimes, test_time+[0,1])
        m_xxx2fac = qtom(q_gse2fac)
        for ii=0,1 do m_xxx2fac[ii,*,*] = transpose(m_xxx2fac[ii,*,*])
        m_fac2gse = m_xxx2fac
        rgb = sgcolor(['red','green','blue'])
        deg = constant('deg')
        device, decomposed=1
        fac_vec = fltarr(3,3)
        foreach comp, ['b','w','o'], comp_id do begin
            case comp of
                'b': vec = [1d,0,0]
                'w': vec = [0d,1,0]
                'o': vec = [0d,0,1]
            endcase
            vec_fac = [transpose(vec),transpose(vec)]
            vec_gse = rotate_vector(vec_fac, m_fac2gse)
            vec_uvw = cotran(vec_gse, test_time+[0,1], $
                'gse2uvw', probe=probe)
            vec_uvw = vec_uvw[0,*]
            fac_vec[comp_id,*] = vec_uvw
            
            polar_angle = 90-acos(vec_uvw[2])*deg
            azim_angle = atan(vec_uvw[1],vec_uvw[0])*deg
            if azim_angle lt 0 then azim_angle += 360
            plots, azim_angle, polar_angle, /data, psym=1, color=rgb[comp_id]
            xyouts, azim_angle, polar_angle, /data, color=rgb[comp_id], ' '+comp
            
            vec_uvw = -vec_uvw
            polar_angle = 90-acos(vec_uvw[2])*deg
            azim_angle = atan(vec_uvw[1],vec_uvw[0])*deg
            if azim_angle lt 0 then azim_angle += 360
            plots, azim_angle, polar_angle, /data, psym=1, color=rgb[comp_id]
        endforeach
        b_fac = reform(fac_vec[0,*])
        w_fac = reform(fac_vec[1,*])
        o_fac = reform(fac_vec[2,*])
;        stop
        
        v_uvw = get_var_data(prefix+'v_uvw', at=test_time)
        v_hat = sunitvec(v_uvw)
        polar_angle = 90-acos(v_hat[2])*deg
        azim_angle = atan(v_hat[1],v_hat[0])*deg
        if azim_angle lt 0 then azim_angle += 360
        plots, azim_angle, polar_angle, /data, psym=6, color=sgcolor('red')
        
        tpos = poss[*,2:4]
        tplot, ['fpdu_pixel'+['1','3'],'v_fac_h'], trange=test_time_range, position=tpos, noerase=1
        timebar, test_time, color=sgcolor('red')
        stop
    endforeach


end
