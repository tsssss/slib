;+
; Generate survey plot to show RBSP data.
;-

function rbsp_gen_polar_region_survey_plot_v02, input_time_range, probe=probe, $
    plot_dir=plot_dir, position=full_pos, errmsg=errmsg, test=test, xpansize=xpansize

    errmsg = ''
    retval = !null
    version = 'v02'
    

    time_range = time_double(input_time_range)
    if n_elements(plot_dir) eq 0 then plot_dir = join_path([homedir(),'rbsp_polar_region_survey'])
    base = 'rbsp_polar_region_survey_'+strjoin(time_string(time_range,tformat='YYYY_MMDD'),'_')+'_rbsp'+probe+'_'+version+'.pdf'
    plot_file = join_path([plot_dir,base])
    if keyword_set(test) then begin
        plot_file = 0
    endif else begin
        if file_test(plot_file) eq 1 then begin
            print, plot_file+' exists, skip ...'
            return, plot_file
        endif
    endelse


    ; Load data.
    prefix = 'rbsp'+probe+'_'
    b_var = rbsp_read_bfield(time_range, probe=probe, coord='sm')
    e_var = rbsp_read_efield(time_range, probe=probe, resolution='survey')
    r_var = rbsp_read_orbit(time_range, probe=probe)
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

    ; FMLat.
    vinfo_north = geopack_trace_to_ionosphere(r_var, models='t89', igrf=0, north=1, refine=1, suffix='_north')
    vinfo_south = geopack_trace_to_ionosphere(r_var, models='t89', igrf=0, south=1, refine=1, suffix='_south')
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


    
    ; Model field.
    bmod_var = geopack_read_bfield(time_range, $
        r_var=r_var, models='t89', igrf=0, t89_par=2)
    foreach var, [b_var,bmod_var] do begin
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
    b_theta = get_var_data(b_var+'_theta', times=times)
    bmod_theta = get_var_data(bmod_var+'_theta', at=times)
    dtheta = b_theta-bmod_theta
    store_data, dtheta_var, times, dtheta
    add_setting, dtheta_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'dTilt', $
        'unit', 'deg' )
    
    ; dis.
    dis_var = prefix+'dis'
    get_data, r_var, times, data
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
    ytickv = make_bins([-1,1]*12,6)
    yticks = n_elements(ytickv)
    yminor = 3
    constants = [-1,0,1]*6
    options, mlt_var, 'yrange', yrange
    options, mlt_var, 'constant', constants
    options, mlt_var, 'ytickv', ytickv
    options, mlt_var, 'yticks', yticks
    options, mlt_var, 'yminor', yminor
    
    ; Tilt.
    var = bmod_var+'_theta'
    options, var, 'yrange', [0,90]
    options, var, 'ytickv', [0,40,80]
    options, var, 'constant', [40,80]
    options, var, 'yticks', 2
    options, var, 'yminor', 4
    var = dtheta_var
    get_data, var, times, data
    ystep = 5
    ytickv = make_bins(data,ystep, inner=1)
    yticks = n_elements(ytickv)-1
    yrange = minmax(make_bins(data,ystep, inner=0))
    options, var, 'ytickv', ytickv
    options, var, 'yticks', yticks
    options, var, 'yrange', yrange
    options, var, 'yminor', ystep
    options, var, 'constant', ytickv
    
    ; E
    var = e_var
    options, var, 'yrange', [-1,1]*100
    options, var, 'ytickv', [-2,-1,0,1,2]*40
    options, var, 'yticks', 4
    options, var, 'yminor', 4
    options, var, 'constant', [-2,-1,0,1,2]*40
    
    vars = [e_en_var,p_en_var,o_en_vars]
    options, vars, 'ytitle', 'Energy!C(eV)'
    
;---Plot settings.
    xticklen_chsz = -0.25   ; in ychsz.
    yticklen_chsz = -0.40   ; in xchsz.

    vars = [e_var,e_en_var,p_en_var,o_en_vars, $
        bmod_var+'_theta',dtheta_var,fmlat_var,mlat_var,mlt_var,dis_var]
    nvar = n_elements(vars)
    fig_labels = letters(nvar)+') '+$
        ['RB-'+strupcase(probe)+' E','e-','H+','O+!Cpara','O+!Canti', $
        'Tilt','dTilt','f/MLat','MLat','MLT','|R|']
    ypans = [1,1,1,1,1, [0.8d,1,0.8,1,1,0.8]*0.7]
    if n_elements(xpansize) eq 0 then xpansize = abs(total(time_range*[-1,1]))/constant('secofday')*6
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

    if keyword_set(test) then stop
    sgclose

    return, plot_file

end

test = 0


input_time_range = ['2013-01-01','2016-01-01']
probes = ['a','b']
local_root = join_path([default_local_root(),'rbsp','survey_plot'])

time_range = time_double(input_time_range)
secofday = constant('secofday')
days = make_bins(time_range, secofday)
foreach day, days do begin
    print, 'Processing '+time_string(day)+' ...'
    the_time_range = day+[0,secofday]
    year = time_string(day,tformat='YYYY')
    monthday = time_string(day,tformat='MMDD')
    plot_dir = join_path([local_root,year])

    foreach probe, probes do begin
        print, 'Processing '+strupcase(probe)+' ...'
        files = rbsp_gen_polar_region_survey_plot_v02(the_time_range, probe=probe, plot_dir=plot_dir, xpansize=6, test=test)
    endforeach
endforeach
stop


input_time_range = ['2013-05-01','2013-05-03']
; input_time_range = ['2013-01-18','2013-01-19']
probes = ['a','b']
files = list()
foreach probe, probes do begin
    files.add, rbsp_gen_polar_region_survey_plot_v02(input_time_range, probe=probe, test=test), extract=1
endforeach
files = files.toarray()
end