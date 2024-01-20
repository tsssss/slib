;+
; Generate survey plot to show RBSP data.
;
; added Vsc, Eu, Ev, and Poynting flux.
;-

function rbsp_gen_polar_region_survey_plot_v05, input_time_range, probe=probe, $
    plot_dir=plot_dir, position=full_pos, errmsg=errmsg, test=test, xpansize=xpansize, local_root=local_root

    errmsg = ''
    retval = !null
    version = 'v05'

    time_range = time_double(input_time_range)
    ; This is just to use the new disk for thg b/c /data is almost full.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'themis','thg','survey_plot','rbsp'])

    if n_elements(plot_dir) eq 0 then plot_dir = join_path([local_root,'%Y'])
    path = apply_time_to_pattern(plot_dir,time_range[0])
    base = 'rbsp_polar_region_survey_'+strjoin(time_string(time_range,tformat='YYYY_MMDD'),'_')+'_rbsp'+probe+'_'+version+'.pdf'
    plot_file = join_path([path,base])
    if keyword_set(test) then begin
        plot_file = 0
    endif else begin
        if file_test(plot_file) eq 1 then begin
            print, plot_file+' exists, skip ...'
            return, plot_file
        endif
    endelse


;---Load data.
    prefix = 'rbsp'+probe+'_'
    b_gsm_var = rbsp_read_bfield(time_range, probe=probe, coord='gsm', errmsg=errmsg)
    if errmsg ne '' then return, retval
    e_var = rbsp_read_efield(time_range, probe=probe, resolution='spinfit_phasef', errmsg=errmsg)
    if errmsg ne '' then return, retval
    rbsp_efw_phasef_read_e_uvw, time_range, probe=probe
    e_uvw_var = prefix+'e_uvw'
    vsc_var = rbsp_read_vsc(time_range, probe=probe, id='median')
    r_gsm_var = rbsp_read_orbit(time_range, probe=probe, coord='gsm')
    mlat_var = rbsp_read_mlat(time_range, probe=probe)
    mlt_var = rbsp_read_mlt(time_range, probe=probe)
    e_en_var = rbsp_read_en_spec(time_range, probe=probe, species='e', errmsg=errmsg)
    if errmsg ne '' then return, retval
    p_en_var = rbsp_read_en_spec(time_range, probe=probe, species='p', errmsg=errmsg)
    if errmsg ne '' then return, retval
    var_info = rbsp_read_en_spec_combo(time_range, probe=probe, species='o', errmsg=errmsg)
    if errmsg ne '' then return, retval
    o_en_vars = [var_info.para, var_info.anti]
;    n_var = rbsp_read_density(time_range, probe=probe)

    time_step = 1d
    common_times = make_bins(time_range, time_step)
    foreach var, [e_var,b_gsm_var,vsc_var] do interp_time, var, common_times

;---Derived data.
    fac_labels = ['b','w','o']

    ; Model field.
    external_model = 't89'
    internal_model = 'dipole'
    igrf = (internal_model eq 'igrf')? 1: 0
    t89_par = 2
    bmod_gsm_var = geopack_read_bfield(time_range, r_var=r_gsm_var, models=external_model, igrf=igrf, suffix='_'+internal_model, t89_par=t89_par)
    vinfo_north = geopack_trace_to_ionosphere(r_gsm_var, models='t89', igrf=0, north=1, refine=1, suffix='_'+internal_model+'_north')
    vinfo_south = geopack_trace_to_ionosphere(r_gsm_var, models='t89', igrf=0, south=1, refine=1, suffix='_'+internal_model+'_south')

    foreach var, [b_gsm_var,bmod_gsm_var] do begin
        get_data, var, times, b_vec, limits=lim
        coord = strlowcase(lim.coord)
        if coord ne 'sm' then begin
            b_vec = cotran(b_vec, times, coord+'2sm')
        endif
        theta_var = var+'_theta'
        theta = atan(b_vec[*,2]/snorm(b_vec))*constant('deg')
        store_data, theta_var , times, theta
        add_setting, theta_var, smart=1, dictionary($
            'display_type', 'scalar', $
            'short_name', 'Tilt', $
            'unit', 'deg' )
    endforeach
    dtheta_var = prefix+'b_dtheta'
    b_theta = get_var_data(b_gsm_var+'_theta', times=times)
    bmod_theta = get_var_data(bmod_gsm_var+'_theta', at=times)
    dtheta = b_theta-bmod_theta
    store_data, dtheta_var, times, dtheta
    add_setting, dtheta_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'dTilt', $
        'unit', 'deg' )
    

    ; Separate B0 and B1.
    window = 20.*60
    b_gsm = get_var_data(b_gsm_var, times=times)
    bmod_gsm = get_var_data(bmod_gsm_var, at=times)
    b1_gsm = b_gsm-bmod_gsm
    ndim = 3
    time_step = total(times[0:1]*[-1,1])
    width = window/time_step
    for ii=0,ndim-1 do begin
        b1_gsm[*,ii] -= smooth(b1_gsm[*,ii], width, edge_mirror=1, nan=1)
    endfor
    b0_gsm = b_gsm-b1_gsm
    b0_gsm_var = prefix+'b0_gsm'
    var = b0_gsm_var
    store_data, var, times, b0_gsm
    add_setting, var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', strupcase(external_model)+' B', $
        'unit', 'nT', $
        'coord', 'GSM', $
        'coord_labels', constant('xyz'), $
        'model', external_model, $
        'internal_model', internal_model )
    b1_gsm_var = prefix+'b1_gsm'
    var = b1_gsm_var
    store_data, var, times, b1_gsm
    add_setting, var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', strupcase(external_model)+' B', $
        'unit', 'nT', $
        'coord', 'GSM', $
        'coord_labels', constant('xyz'), $
        'model', external_model, $
        'internal_model', internal_model )

    ; Convert E/B into FAC.
    define_fac, b0_gsm_var, r_gsm_var, time_var=b0_gsm_var
    b1_fac_var = prefix+'b1_fac'
    to_fac, b1_gsm_var, to=b1_fac_var

    get_data, e_var, times, e_mgse
    b0_gsm = get_var_data(b0_gsm_var, at=times)
    b0_mgse = cotran(b0_gsm, times, 'gsm2mgse', probe=probe)
    e_mgse[*,0] = -(e_mgse[*,1]*b0_mgse[*,1]+e_mgse[*,2]*b0_mgse[*,2])/b0_mgse[*,0]
    type = 'dot0'
    edot0_mgse_var = prefix+'e'+type+'_mgse'
    var = edot0_mgse_var
    store_data, var, times, e_mgse
    add_setting, var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'Edot0', $
        'unit', 'mV/m', $
        'coord', 'mGSE', $
        'coord_labels', constant('xyz') )
    edot0_gsm_var = prefix+'e'+type+'_gsm'
    edot0_gsm = cotran(e_mgse, times, 'mgse2gsm', probe=probe)
    var = edot0_gsm_var
    store_data, var, times, edot0_gsm
    add_setting, var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'Edot0', $
        'unit', 'mV/m', $
        'coord', 'GSM', $
        'coord_labels', constant('xyz') )
    e1_fac_var = prefix+'e'+type+'_fac'    
    to_fac, edot0_gsm_var, to=e1_fac_var
    
    

    ; Calculate pflux.
    filter = [1,1800]    ; sec.
    scale_info = {s0:min(filter), s1:max(filter), dj:1d/8, ns:0d}

    pf_fac_var = prefix+'pf'+type+'_fac'
    stplot_calc_pflux_mor, e1_fac_var, b1_fac_var, pf_fac_var, scaleinfo=scale_info
    add_setting, pf_fac_var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'S', $
        'unit', 'mW/m!E2!N', $
        'coord', 'FAC', $
        'coord_labels', fac_labels )

    ; Normalize to 100 km.
    b0_gsm = get_var_data(b0_gsm_var, times=times)
    bf_var = prefix+'bf_gsm_'+external_model+'_'+internal_model+'_north'
    bf_gsm = get_var_data(bf_var, at=times)
    cmap = snorm(bf_gsm)/snorm(b0_gsm)

    pf_fac_map_var = pf_fac_var+'_map'
    pf_fac = get_var_data(pf_fac_var, times=times)
    pf_fac_map = pf_fac
    for ii=0,ndim-1 do pf_fac_map[*,ii] = cmap*pf_fac[*,ii]
    store_data, pf_fac_map_var, times, pf_fac_map
    add_setting, pf_fac_map_var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'S', $
        'unit', 'mW/m!E2!N', $
        'model', external_model, $
        'internal_model', internal_model, $
        'coord', 'FAC', $
        'coord_labels', fac_labels )
    

;---Settings.
    ; Euv.
    get_data, e_uvw_var, times, e_uvw
    eu_var = prefix+'eu'
    store_data, eu_var, times, e_uvw[*,0]
    add_setting, eu_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'Eu', $
        'colors', sgcolor('red'), $
        'unit', 'mV/m' )
    ev_var = prefix+'ev'
    store_data, ev_var, times, e_uvw[*,1]
    add_setting, ev_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'Ev', $
        'colors', sgcolor('green'), $
        'unit', 'mV/m' )
    ; FMLat.
    fmlat_north_var = vinfo_north.fmlat
    fmlat_south_var = vinfo_south.fmlat
    fmlat_var = prefix+'fmlat'
    fmlat_var = stplot_merge([fmlat_north_var,fmlat_south_var], output=fmlat_var)
    get_data, fmlat_var, times, data
    store_data, fmlat_var, times, abs(data)
    add_setting, fmlat_var, smart=1, dictionary($
        'display_type', 'stack', $
        'ytitle', '(deg)', $
        'yrange', [55,70], $
        'ytickv', [60,70], $
        'yticks', 1, $
        'yminor', 5, $
        'constant', [60,65], $
        'labels', ['North','South'], $
        'colors', sgcolor(['red','blue']) )


    
    ; dis.
    dis_var = prefix+'dis'
    get_data, r_gsm_var, times, data
    store_data, dis_var, times, snorm(data)
    add_setting, dis_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', '|R|', $
        'unit', 'Re' )
    var = dis_var
    options, var, 'yrange', [1,6]
    options, var, 'ytickv', [2,4,6]
    options, var, 'yticks', 2
    options, var, 'yminor', 2
    options, var, 'constant', [2,4]
    
    
    ; MLat.
    options, mlat_var, 'yrange', [-1,1]*20
    options, mlat_var, 'constant', [-1,0,1]*10
    options, mlat_var, 'ytickv', [-1,0,1]*10
    options, mlat_var, 'yticks', 2
    options, mlat_var, 'yminor', 2
    
    
    ; MLT.
    yrange = [-1,1]*12
    ytickv = [-1,0,1]*6
    yticks = n_elements(ytickv)-1
    yminor = 3
    constants = [-1,0,1]*6
    options, mlt_var, 'yrange', yrange
    options, mlt_var, 'constant', constants
    options, mlt_var, 'ytickv', ytickv
    options, mlt_var, 'yticks', yticks
    options, mlt_var, 'yminor', yminor
    
    ; Tilt.
    var = bmod_gsm_var+'_theta'
    options, var, 'yrange', [0,90]
    options, var, 'ytickv', [40,80]
    options, var, 'constant', [40,80]
    options, var, 'yticks', 1
    options, var, 'yminor', 4
    var = dtheta_var
    get_data, var, times, data
    ystep = 10
    ytickv = make_bins(data,ystep, inner=1)
    yticks = n_elements(ytickv)-1
    yrange = minmax(make_bins(data,ystep, inner=0))
    options, var, 'ytickv', ytickv
    options, var, 'yticks', yticks
    options, var, 'yrange', yrange
    options, var, 'yminor', 2
    options, var, 'constant', ytickv
    
    ; E
    var = e_var
    options, var, 'yrange', [-1,1]*60
    options, var, 'ytickv', [-2,-1,0,1,2]*20
    options, var, 'yticks', 4
    options, var, 'yminor', 2
    options, var, 'constant', [-2,-1,0,1,2]*20
    
    ; Euv
    var = [eu_var,ev_var]
    options, var, 'yrange', [-1,1]*200
    options, var, 'ytickv', [-1,0,1]*100
    options, var, 'yticks', 2
    options, var, 'yminor', 2
    options, var, 'constant', [-1,0,1]*100
    
    ; Vsc.
    var = vsc_var
    options, var, 'yrange', [-50,210]
    options, var, 'ytickv', [0,200]
    options, var, 'yticks', 1
    options, var, 'yminor', 4
    options, var, 'constant', [[-1,0,1]*20,100]
    
    
    vars = [e_en_var,p_en_var,o_en_vars]
    options, vars, 'ytitle', 'Energy!C(eV)'


    ; pflux.
    var = pf_fac_map_var
    yrange = [-1,1]*150
    options, var, 'yrange', yrange
    options, var, 'ytickv', [-1,1]*100
    options, var, 'yticks', 1
    options, var, 'yminor', 4
    options, var, 'constant', make_bins(yrange, 50, inner=1)



    
;---Plot settings.
    xticklen_chsz = -0.25   ; in ychsz.
    yticklen_chsz = -0.40   ; in xchsz.

    vars = [e_var,eu_var,ev_var,vsc_var,pf_fac_map_var,e_en_var,p_en_var,o_en_vars, $
        bmod_gsm_var+'_theta',dtheta_var,fmlat_var,mlat_var,mlt_var,dis_var]
    nvar = n_elements(vars)
    fig_labels = letters(nvar)+') '+$
        ['RB-'+strupcase(probe)+' E','Eu','Ev','Vsc','S 100km','e-','H+','O+ para','O+ anti', $
        'Tilt','dTilt','f/MLat','MLat','MLT','|R|']
    ypans = [1,[1,1,0.8]*0.7,1,1,1,1,1, [0.8d,1,0.8,0.8,1,0.8]*0.7]
    if n_elements(xpansize) eq 0 then xpansize = 8
    pansize = [xpansize,1]
    nvar = n_elements(vars)
    margins = [10,4,8,1]
    
    
    poss = panel_pos(plot_file, ypans=ypans, fig_size=fig_size, nypan=nvar, pansize=pansize, panid=[0,1], margins=margins)
    sgopen, plot_file, size=fig_size, xchsz=xchsz, ychsz=ychsz, inch=1

    for ii=0,nvar-1 do begin
        tpos = poss[*,ii]
        xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
        yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
        options, vars[ii], 'xticklen', xticklen
        options, vars[ii], 'yticklen', yticklen
    endfor

    tplot, vars, trange=time_range, position=poss
    for ii=0,nvar-1 do begin
        tpos = poss[*,ii]
        tx = tpos[0]-xchsz*9
        ty = tpos[3]-ychsz*0.8
        msg = fig_labels[ii]
        xyouts, tx,ty,msg, normal=1
    endfor
    
    timebar, make_bins(time_range, 3600), linestyle=1
    

    if keyword_set(test) then stop
    sgclose

    return, plot_file

end

the_time_range = time_double(['2013-05-01','2013-05-02'])
the_time_range = time_double(['2015-04-16','2015-04-17'])
probe = 'a'
test = 1
files = rbsp_gen_polar_region_survey_plot(the_time_range, probe=probe, xpansize=6, test=test)
end