;+
; Test to fit the perigee efield.
;-


;---Settings.
    time_range = time_double(['2012-10-01','2013-10-01'])
    time_range = time_double(['2013-03-15','2013-03-20'])
;    time_range = time_double(['2012-10-01','2013-02-01'])
;    time_range = time_double(['2013-02-01','2013-04-01'])
    time_range = time_double(['2014-06-01','2015-01-01'])
    probe = 'b'


    prefix = 'rbsp'+probe+'_'
    ndim = 3

;---Read data.
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
    rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
    ;rbsp_efw_read_e_mgse, time_range, probe=probe


;---Prepare to fit.
    r_mgse = get_var_data(prefix+'r_mgse', times=times)
    time_step = sdatarate(times)
    dis = snorm(r_mgse)
    perigee_lshell = 2
    perigee_index = where(dis le perigee_lshell, ntime)
    perigee_times = times[perigee_index]

    v_mgse = get_var_data(prefix+'v_mgse')*1e-3
    vcoro_mgse = get_var_data(prefix+'vcoro_mgse')*1e-3
    u_mgse = v_mgse-vcoro_mgse
    du_mgse = u_mgse
    for ii=0,ndim-1 do du_mgse[*,ii] = deriv(times,u_mgse[*,ii])
    u_mgse = u_mgse[perigee_index,*]
    du_mgse = du_mgse[perigee_index,*]

    b_mgse = get_var_data(prefix+'b_mgse', at=perigee_times)
    e_mgse = get_var_data(prefix+'e_mgse', at=perigee_times)
    e_mgse[*,0] = 0

    ; The coefficient.
    de_mgse = e_mgse-vec_cross(u_mgse,b_mgse)
    de_mgse[*,0] = 0

    duxb = vec_cross(du_mgse,b_mgse)

    e_coef = fltarr(ntime,ndim)
    e_coef[*,1] =  e_mgse[*,2]
    e_coef[*,2] = -e_mgse[*,1]

    wx_coef = fltarr(ntime,ndim)
    wx_coef[*,0] = -u_mgse[*,1]*b_mgse[*,1]-u_mgse[*,2]*b_mgse[*,2]
    wx_coef[*,1] =  u_mgse[*,1]*b_mgse[*,0]
    wx_coef[*,2] =  u_mgse[*,2]*b_mgse[*,0]
    wy_coef = fltarr(ntime,ndim)
    wy_coef[*,0] =  u_mgse[*,0]*b_mgse[*,1]
    wy_coef[*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
    wy_coef[*,2] =  u_mgse[*,2]*b_mgse[*,1]
    wz_coef = fltarr(ntime,ndim)
    wz_coef[*,0] =  u_mgse[*,0]*b_mgse[*,2]
    wz_coef[*,1] =  u_mgse[*,1]*b_mgse[*,2]
    wz_coef[*,2] = -u_mgse[*,1]*b_mgse[*,1]-u_mgse[*,0]*b_mgse[*,0]

    bx_coef = fltarr(ntime,ndim)
    bx_coef[*,0] =  u_mgse[*,1]*b_mgse[*,1]+u_mgse[*,2]*b_mgse[*,2]
    bx_coef[*,1] = -u_mgse[*,0]*b_mgse[*,1]
    bx_coef[*,2] = -u_mgse[*,0]*b_mgse[*,2]

    by_coef = fltarr(ntime,ndim)
    by_coef[*,0] = -u_mgse[*,1]*b_mgse[*,0]
    by_coef[*,1] =  u_mgse[*,2]*b_mgse[*,2]+u_mgse[*,0]*b_mgse[*,0]
    by_coef[*,2] = -u_mgse[*,1]*b_mgse[*,2]

    bz_coef = fltarr(ntime,ndim)
    bz_coef[*,0] = -u_mgse[*,2]*b_mgse[*,0]
    bz_coef[*,1] = -u_mgse[*,2]*b_mgse[*,1]
    bz_coef[*,2] =  u_mgse[*,0]*b_mgse[*,0]+u_mgse[*,1]*b_mgse[*,1]
    


;---Do fit.
;    foreach comp, [1,2] do begin

    ;---u rotation.
        nfit = 4
        comp = 1
        yy_y = de_mgse[*,comp]
        xx_y = fltarr(nfit,ntime)
        xx_y[0,*] = (e_coef[*,comp])
        xx_y[1,*] = (wx_coef[*,comp])
        xx_y[2,*] = (wy_coef[*,comp])
        xx_y[3,*] = (wz_coef[*,comp])
        ;xx_y[4,*] = (e_mgse[*,comp])
        ;xx_y[4,*] = duxb[*,comp]

        comp = 2
        yy_z = de_mgse[*,comp]
        xx_z = fltarr(nfit,ntime)
        xx_z[0,*] = (e_coef[*,comp])
        xx_z[1,*] = (wx_coef[*,comp])
        xx_z[2,*] = (wy_coef[*,comp])
        xx_z[3,*] = (wz_coef[*,comp])
        ;xx_y[4,*] = (e_mgse[*,comp])
        ;xx_z[4,*] = duxb[*,comp]

    ;---B rotation.
        nfit = 3
        comp = 1
        yy_y = de_mgse[*,comp]
        xx_y = fltarr(nfit,ntime)
        xx_y[0,*] = bx_coef[*,comp]
        xx_y[1,*] = by_coef[*,comp]
        xx_y[2,*] = bz_coef[*,comp]

        comp = 2
        yy_z = de_mgse[*,comp]
        xx_z = fltarr(nfit,ntime)
        xx_z[0,*] = bx_coef[*,comp]
        xx_z[1,*] = by_coef[*,comp]
        xx_z[2,*] = bz_coef[*,comp]

    ;---B rotation 2.
        comp = 1
        yy_y = de_mgse[*,comp]
        xx_y = fltarr(1,ntime)
        xx_y[0,*] = bx_coef[*,comp]
        
        comp = 2
        yy_z = de_mgse[*,comp]
        xx_z = fltarr(1,ntime)
        xx_z[0,*] = bx_coef[*,comp]
        
        
    ;---uxB combo.
        comp = 1
        yy_y = de_mgse[*,comp]
        xx_y = fltarr(9,ntime)
        for ii=0,ndim-1 do begin
            for jj=0,ndim-1 do begin
                xx_y[ii*ndim+jj,*] = u_mgse[*,ii]*b_mgse[*,jj]
            endfor
        endfor
    
        comp = 2
        yy_z = de_mgse[*,comp]
        xx_z = fltarr(9,ntime)
        for ii=0,ndim-1 do begin
            for jj=0,ndim-1 do begin
                xx_z[ii*ndim+jj,*] = u_mgse[*,ii]*b_mgse[*,jj]
            endfor
        endfor
        

        xx = xx_y+xx_z
        yy = yy_y+yy_z
;        xx = xx_y
;        yy = yy_y
        res = regress(xx,yy, sigma=sigma, const=const)

        sgopen, 0, xsize=5, ysize=6
        poss = sgcalcpos(4)
        yr = [-1,1]*5

        plot, yy_y, position=poss[*,0], noerase=1, yrange=yr, ystyle=1
        ey_fit = reform(xx_y ## res)+const
        oplot, ey_fit, color=sgcolor('red')

        plot, yy_z, position=poss[*,1], noerase=1, yrange=yr, ystyle=1
        ez_fit = reform(xx_z ## res)+const
        oplot, ez_fit, color=sgcolor('red')

        plot, yy_y-ey_fit, position=poss[*,2], noerase=1, yrange=yr, ystyle=1
        plot, yy_z-ez_fit, position=poss[*,3], noerase=1, yrange=yr, ystyle=1


        e1_mgse = fltarr(ntime,ndim)
        e1_mgse[*,1] = yy_y-ey_fit
        e1_mgse[*,2] = yy_z-ez_fit
        rgb = constant('rgb')
        store_data, prefix+'e1_mgse', perigee_times, e1_mgse, limits={colors:rgb}
;        e1_gse = cotran(e1_mgse, perigee_times, 'mgse2gse', probe=probe)
;        store_data, prefix+'e1_gse', perigee_times, e1_gse, limits={colors:rgb}


        print, res, const
        print, stddev(de_mgse[*,1])
        print, stddev(de_mgse[*,2])
        print, stddev(e1_mgse[*,1])
        print, stddev(e1_mgse[*,2])



end
