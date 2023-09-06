;+
; Generate survey plot to show SSJ and SUSSI data.
;-

function dmsp_gen_polar_region_survey_plot_v01, input_time_range, probe=probe, $
    plot_dir=plot_dir, position=full_pos, errmsg=errmsg, test=test
    
    errmsg = ''
    retval = !null
    

    time_range = time_double(input_time_range)

    ; Load data.
    mlt_image_var = dmsp_read_mlt_image(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    mlt_images = get_var_data(mlt_image_var, times=times, limits=lim)
    
    
    time_ranges = lim.time_range
    index = where_pro(times, '[]', time_range, count=ntime_range)
    if ntime_range eq 0 then return, retval
    mlt_images = mlt_images[index,*,*]
    times = times[index]
    time_ranges = time_ranges[index,*]
    hem_flags = lim.hemisphere[index]
    
    
    full_time_range = minmax(time_ranges)
    mlat_vars = dmsp_read_mlat_vars(full_time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    ele_spec_var = dmsp_read_en_spec(full_time_range, probe=probe, species='e', errmsg=errmsg)
    if errmsg ne '' then return, retval
    ion_spec_var = dmsp_read_en_spec(full_time_range, probe=probe, species='p', errmsg=errmsg)
    if errmsg ne '' then return, retval
    ele_eflux_var = dmsp_read_eflux(full_time_range, probe=probe, species='e', errmsg=errmsg)
    if errmsg ne '' then return, retval

    options, ele_eflux_var, 'labels', 'eflux'
    db_var = dmsp_read_bfield(full_time_range, probe=probe)
    r_var = dmsp_read_orbit(full_time_range, probe=probe)
    
    rad = constant('rad')
    deg = constant('deg')
    mlat_var = mlat_vars[0]
    mlt_var = mlat_vars[1]
    
    ; Generate plot.
    if n_elements(plot_dir) eq 0 then plot_dir = join_path([default_local_root(),'dmsp','survey_plot_alfven_arc','%Y','%m%d'])
    plot_files = list()
    foreach time, times, time_id do begin
        the_time_range = reform(time_ranges[time_id,*])
        duration = total(the_time_range*[-1,1])
        if duration le 300 then continue
        hem = hem_flags[time_id]
        
        all_poss = panel_pos(pansize=[1,1]*4, panid=[1,0], xpans=[2,1], xpad=10, margins=[10,4,8,1], fig_size=fig_size)
        path = apply_time_to_pattern(plot_dir,time)
        base = 'dmsp_polar_region_survey_'+strlowcase(hem)+'_'+strjoin(time_string(the_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_'+probe+'_v01.pdf'
        plot_file = join_path([path,base])
        if keyword_set(test) then begin
            plot_file = 0
        endif else begin
            plot_files.add, plot_file
            if file_test(plot_file) eq 1 then begin
                print, plot_file+' exists, skip ...'
                continue
            endif
        endelse
        


        sgopen, plot_file, size=fig_size, xchsz=xchsz, ychsz=ychsz
        
        ; Left panels.
        tpos = all_poss[*,0]
        vars = [ele_eflux_var,ele_spec_var,ion_spec_var]
        nvar = n_elements(vars)
        fig_labels = letters(nvar)+') '+['e-','e-','H+']
        poss = sgcalcpos(nvar, position=tpos)
        tplot, vars, position=poss, trange=the_time_range
        for ii=0,nvar-1 do begin
            tpos = poss[*,ii]
            tx = tpos[0]-xchsz*8
            ty = tpos[3]-ychsz*0.8
            msg = fig_labels[ii]
            xyouts, tx,ty,msg, normal=1
        endfor

        ; Right panel.
        tpos = all_poss[*,1]
        cbpos = tpos
        cbpos[0] = cbpos[2]+xchsz*1
        cbpos[2] = cbpos[0]+xchsz*1
        ct = lim.color_table
        label_color = sgcolor('black')
        ;ct = 40
        ;label_color = sgcolor('white')
        line_color = sgcolor('silver')

        mlt_image = reform(mlt_images[time_id,*,*])
        zrange = lim.zrange
        if lim.zlog eq 0 then begin
            zzs = bytscl(mlt_image, min=zrange[0], max=zrange[1], top=254)
            ztitle = strupcase(lim.wavelength)+' ('+lim.unit+')'
            sgcolorbar, zrange=zrange, position=cbpos, ztitle=ztitle, ct=ct
        endif else begin
            zzs = bytscl(alog10(mlt_image), min=alog10(zrange[0]), max=alog10(zrange[1]), top=254)
            ztitle = strupcase(lim.wavelength)+' Log!D10!N ('+lim.unit+')'
            sgcolorbar, zrange=alog10(zrange), position=cbpos, ztitle=ztitle, ct=ct
        endelse
        sgtv, zzs, position=tpos, ct=ct
        plot, [-1,1],[-1,1], $
            xstyle=5, ystyle=5, position=tpos, nodata=1, noerase=1
            

        ; Add circles and lines for minor ticks.
        minor_linestyle = 1
        mlat_range = lim.mlat_range
        mlat_step = 5
        mlat_minors = make_bins(mlat_range, mlat_step, inner=1)
        rrs = abs((90-mlat_minors)/total(mlat_range*[-1,1]))
        tmp = smkarthm(0,2*!dpi,50,'n')
        circ_xs = cos(tmp)
        circ_ys = sin(tmp)
        foreach rr, rrs do plots, rr*circ_xs, rr*circ_ys, linestyle=minor_linestyle, color=line_color
        
        mlt_range = lim.mlt_range
        mlt_minors = make_bins(mlt_range, 1, inner=1)
        tts = (mlt_minors*15-90)*constant('rad')
        foreach tt, tts do plots, [0,1]*cos(tt), [0,1]*sin(tt), linestyle=minor_linestyle, color=line_color

        ; Add labels.
        tx = tpos[0]+xchsz*0.5
        ty = tpos[1]+ychsz*0.2
        msg = strupcase(probe)+' '+hem+' '+time_string(mean(the_time_range),tformat='YYYY-MM-DD/hh:mm')
        xyouts, tx,ty,msg, normal=1, alignment=0, color=label_color
        
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1
        msg = 'd)'
        xyouts, tx,ty,msg, normal=1, color=label_color
        
        ; Add tick names.
        major_linestyle = 0
        mlat_step = 10
        mlat_majors = make_bins(mlat_range, mlat_step, inner=1)
        rrs = abs((90-mlat_majors)/total(mlat_range*[-1,1]))
        foreach rr, rrs do plots, rr*circ_xs, rr*circ_ys, linestyle=major_linestyle, color=line_color
        ; ticknames.
        major_tickns = string(mlat_majors,format='(I02)')
        tt = 135*rad
        foreach msg, major_tickns, ii do begin
            tmp = convert_coord(rrs[ii]*cos(tt),rrs[ii]*sin(tt), data=1, to_normal=1)
            tx = tmp[0]
            ty = tmp[1]-ychsz*0.3
            xyouts, tx,ty,normal=1, msg, alignment=0.5, color=label_color
        endforeach
        
        mlt_step = 6
        mlt_majors = make_bins(mlt_range, mlt_step, inner=1)
        index = where(mlt_majors lt 0, count)
        if count ne 0 then mlt_majors[index] += 24
        tts = (mlt_majors*15-90)*rad
        foreach tt, tts do plots, [0,1]*cos(tt), [0,1]*sin(tt), linestyle=major_linestyle, color=line_color
        ; ticknames.
        major_tickns = string(mlt_majors,format='(I02)')
        rr = abs((90-min(mlat_range)-2)/total(mlat_range*[-1,1]))
        foreach msg, major_tickns, ii do begin
            tmp = convert_coord(rr*cos(tts[ii]),rr*sin(tts[ii]), data=1, to_normal=1)
            tx = tmp[0]
            ty = tmp[1]-ychsz*0.3
            xyouts, tx,ty,normal=1, msg, alignment=0.5, color=label_color
        endforeach
        
        ; Add SC track.
        mlts = get_var_data(mlt_var, in=the_time_range, times=the_times)
        mlats = get_var_data(mlat_var, in=the_time_range)
        tts = (mlts*15-90)*rad
        rrs = abs((90-abs(mlats))/total(mlat_range*[-1,1]))
        oplot, rrs*cos(tts), rrs*sin(tts), color=line_color

        minor_times = make_bins(the_time_range, 60, inner=1)
        minor_tts = interpol(tts, the_times, minor_times)
        minor_rrs = interpol(rrs, the_times, minor_times)
        usersym, circ_xs[0:*:2], circ_ys[0:*:2], fill=1
        plots, minor_rrs*cos(minor_tts), minor_rrs*sin(minor_tts), psym=8, symsize=0.5, color=line_color

        major_times = make_bins(the_time_range, 300, inner=1)
        major_tts = interpol(tts, the_times, major_times)
        major_rrs = interpol(rrs, the_times, major_times)
        major_tickns = time_string(major_times,tformat='hh:mm')
        major_xxs = major_rrs*cos(major_tts)
        major_yys = major_rrs*sin(major_tts)
        foreach msg, major_tickns, ii do begin
            tmp = convert_coord(major_xxs[ii],major_yys[ii], data=1, to_normal=1)
            tx = tmp[0]
            ty = tmp[1]+ychsz*0.4
            plots, tmp[0], tmp[1], normal=1, psym=8, symsize=0.5, color=label_color
            xyouts, tx,ty,normal=1, msg, alignment=0.5, color=label_color
        endforeach
        
        if keyword_set(test) then stop
        sgclose
    endforeach
    
    return, plot_files.toarray()
end

test = 1

; Qinghe's event.
probe = 'f17'
the_time_range = time_double(['2017-09-07/16:04','2017-09-07/16:17'])
files = dmsp_gen_polar_region_survey_plot_v01(the_time_range, probe=probe, plot_dir=plot_dir, test=test)

stop



input_time_range = ['2015-01-01','2015-04-01']
probes = 'f'+['16','17','18','19']
local_root = join_path([default_local_root(),'dmsp','survey_plot'])

time_range = time_double(input_time_range)
secofday = constant('secofday')
days = make_bins(time_range, secofday)
foreach day, days do begin
    print, 'Processing '+time_string(day)+' ...'
    the_time_range = day+[0,secofday]
    year = time_string(day,tformat='YYYY')
    monthday = time_string(day,tformat='MMDD')
    plot_dir = join_path([local_root,year,monthday])

    foreach probe, probes do begin
        print, 'Processing '+strupcase(probe)+' ...'
        files = dmsp_gen_polar_region_survey_plot_v01(the_time_range, probe=probe, plot_dir=plot_dir)
    endforeach
endforeach

stop

input_time_range = ['2013-05-01','2013-05-02']
input_time_range = ['201-01-18','2013-01-19']
probes = 'f'+['16','17','18']
files = list()
foreach probe, probes do begin
    files.add, dmsp_gen_polar_region_survey_plot_v01(input_time_range, probe=probe, test=test), extract=1
endforeach
files = files.toarray()
end