;+
; :Purpose: Generate survey plot to show DMSP SSJ, SSUSI, B and V data. v04 adds ion velosity and B field and plot then on the auroral image.
; :Returns: str, figure name.
; :Arguments:
;   input_time_range: in, [2], input time range.
; :Keywords:
;   probe: in, required, str 'fxx'.
;   plot_dir: in, optional, str of plot dir.
;   errmsg: out, optional, error message.
;   test: in, optional, set for testing.
;   local_root: in, optional, str of the root directory of saving plots.
;-

function dmsp_gen_polar_region_survey_plot_v04, input_time_range, probe=probe, $
    plot_dir=plot_dir, errmsg=errmsg, test=test, local_root=local_root

    compile_opt idl2
    errmsg = ''
    retval = !null
    file = get_filename()
    version = get_file_version(file)
    

    time_range = time_double(input_time_range)
    ; This is just to use the new disk for thg b/c /data is almost full.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'survey_plot','dmsp_'+version])

    ; Load data.
    prefix = 'dmsp'+probe+'_'
    mlt_image_var = dmsp_read_mlt_image(time_range, probe=probe, errmsg=errmsg, id='energy')
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

    mlat_var = mlat_vars[0]
    mlt_var = mlat_vars[1]


    ; Generate plot.
    if n_elements(plot_dir) eq 0 then plot_dir = join_path([local_root,'%Y','%m%d'])
    plot_files = list()
    foreach time, times, time_id do begin
        the_time_range = reform(time_ranges[time_id,*])
        duration = total(the_time_range*[-1,1])
        if duration le 300 then continue
        hem = hem_flags[time_id]
        
        margins = [10,6,1,1]
        all_poss = panel_pos(pansize=[1,1]*3, panid=[1,0], xpans=[2,1], ypans=[2,1], xpad=14, margins=margins, fig_size=fig_size)
        path = apply_time_to_pattern(plot_dir,time)
        base = 'dmsp_polar_region_survey_'+strlowcase(hem)+'_'+strjoin(time_string(the_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_'+probe+'_'+version+'.pdf'
        plot_file = join_path([path,base])
        plot_files.add, plot_file
        if keyword_set(test) then begin
            plot_file = 0
        endif else begin
            if file_test(plot_file) eq 1 then begin
                print, plot_file+' exists, skip ...'
                continue
            endif
        endelse

        ; Load dB and Ion vel.
        ndim = 3
        db_var = dmsp_read_bfield(the_time_range, probe=probe, errmsg=errmsg)
        if errmsg ne '' then begin
            db_var = var_store(prefix+'db_dmsp_xyz', the_time_range, fltarr(2,ndim), id='bfield')
        endif
        vel_var = dmsp_read_flow3d(the_time_range, probe=probe, errmsg=errmsg)
        foreach var, [db_var,vel_var] do begin
            uniform_time, var
        endforeach
        
        if errmsg ne '' then begin
            vel_var = dmsp_read_ion_vel(the_time_range, probe=probe, errmsg=errmsg)
            if errmsg ne '' then begin
                vel_var = var_store(prefix+'v_dmsp_xyz', the_time_range, fltarr(2,ndim), id='velocity')
            endif
        endif
        options, db_var, yrange=[-1,1]*500, yminor=5, yticks=2, constant=0
        options, vel_var, yrange=[-1,1]*2, yminor=4, yticks=2, constant=0

        sgopen, plot_file, size=fig_size, xchsz=xchsz, ychsz=ychsz
        plot_vars = [ele_spec_var,ion_spec_var,db_var,vel_var]
        nplot_var = n_elements(plot_vars)
        plot_labels = letters(nplot_var)+'. '+['e-','H+','dB','V']

        label_vars = [mlat_var,mlt_var]
        options, mlat_var, ytitle='MLat (deg)'
        options, mlt_var, ytitle='MLT (h)'
        vlab_margins = 8

        spec_vars = [ele_spec_var,ion_spec_var]
        options, spec_vars, ytitle='Energy!C(eV)', zticklen=-0.5

        plot_pos = combine_pos(all_poss[*,0,*])
        left_poss = sgcalcpos(nplot_var,position=plot_pos)
        tplot_options, 'tickinterval', 180
        tplot, plot_vars, var_label=label_vars, $
            trange=the_time_range, noerase=1, position=left_poss, $
            vlab_margin=vlab_margins
        
        for ii=0,nplot_var-1 do begin
            my_pos = left_poss[*,ii]
            tx = my_pos[0]-xchsz*8
            ty = my_pos[3]-ychsz*0.8
            msg = plot_labels[ii]
            xyouts, tx,ty,msg, normal=1
        endfor

    
    ;---Draw MLT images, dB, and vel.
        big_pos = reform(all_poss[*,1,0])
        small_poss = sgcalcpos(1,2, position=all_poss[*,1,1],xpad=0)
        plot_poss = [[big_pos],[small_poss]]
        down_sample_cadence = 6
        plot_scale = 10d
        db_color = sgcolor('peru')
        db_unit = 'nT'
        db_scale = 400d     ; nT.
        vel_color = sgcolor('sea_green')
        vel_unit = 'km/s'
        vel_scale = 1d      ; km/s.
        label_color = sgcolor('black')
        color_top = 254

        ; MLT images.
        tr = the_time_range
        mlt_images = var_get_data(mlt_image_var, in=tr, times=uts, settings=mlt_image_settings)
        mlt_image_zrange = mlt_image_settings['zrange']
        mlt_image_ct = mlt_image_settings['color_table']
        mlt_image_ztitle = strupcase(mlt_image_settings['wavelength'])+' Log!D10!N ('+mlt_image_settings['unit']+')'
        if n_elements(uts) eq 1 then begin
            mlt_image = mlt_images
            mlt_image_time = uts[0]
        endif else begin
            index = where_pro(uts, '[]', tr, count=count)
            if count eq 1 then begin
                mlt_image = reform(mlt_images[index,*,*])
                mlt_image_time = uts[index]
            endif
        endelse

        if n_elements(mlt_image) ne 0 then begin
            zzs = bytscl(mlt_image, $
                min=mlt_image_zrange[0],max=mlt_image_zrange[1], top=color_top)
        endif else begin
            zzs = !null
        endelse

        mlats = var_get_data(mlat_var, in=tr)
        is_south = median(mlats) lt 0
        hem_str = is_south? 'South': 'North'

        ; Colorbar.
        rel_pos = 'below'
        cbpos = calc_cbpos(plot_poss, rel_pos)
        sgcolorbar, zrange=mlt_image_zrange, rel_pos=rel_pos, $
            ztitle=mlt_image_ztitle, position=cbpos, ct=mlt_image_ct, $
            zticklen=-0.5

        ; MLT image.
        if n_elements(zzs) ne 0 then begin
            for ii=0,2 do begin
                my_pos = plot_poss[*,ii]
                sgtv, position=my_pos, zzs, ct=mlt_image_ct
                ; Only do labels in big plot.
                if ii eq 0 then begin
                    msgs = [$
                        time_string(tr[0],tformat='YYYY-MM-DD/hh:mm')+'-'+time_string(tr[1],tformat='hh:mm')+' UT', $
                        strupcase(probe)+' '+hem_str]
                    nmsg = n_elements(msgs)
                    foreach msg, msgs, mid do begin
                        tx = my_pos[0]+xchsz*0.5
                        ty = my_pos[1]+ychsz*(nmsg-1-mid+0.3)
                        xyouts, tx,ty,msg, normal=1, alignment=0, color=label_color
                    endforeach
                endif
            endfor
        endif
        my_pos = polar_xy_set_axis(big_pos)
        polar_xy_draw_axis, south=is_south


    ;---Add dB.
        the_color = db_color
        the_unit = db_unit
        the_scale = db_scale
        my_pos = polar_xy_set_axis(small_poss[*,0])
        polar_xy_draw_vector, db_var, $
            mlat_var=mlat_var, mlt_var=mlt_var, $
            data_scale=the_scale, $
            plot_scale=plot_scale, $
            color=the_color, down_sample_cadence=down_sample_cadence
        polar_xy_draw_axis, south=is_south, mlt_label_mlat=55, $
            mlat_tickformat='(A1)'

        ; Add label and scale.
        len = polar_xy_mlat_to_dis(90-plot_scale)
        label_pos = [my_pos[0]+xchsz*1,my_pos[1]+ychsz*0.3]
        tmp = convert_coord(label_pos, normal=1, to_data=1)
        txs = tmp[0]+[0,len]
        tys = tmp[1]+[0,0]
        plots, txs, tys, data=1, color=the_color
        foreach tx, txs do begin
            tmp = convert_coord(tx,tys[0], data=1, to_normal=1)
            ttxs = tmp[0]+[0,0]
            ttys = tmp[1]+[-1,1]*ychsz*0.15
            plots, ttxs, ttys, normal=1, color=the_color
        endforeach
        mid_pos = [mean(txs),tys[0]]
        tmp = convert_coord(mid_pos, data=1, to_normal=1)
        tx = tmp[0]
        ty = tmp[1]+ychsz*0.3
        msg = string(the_scale,format='(I0)')+' '+the_unit
        xyouts, tx,ty,msg,normal=1, alignment=0.5, color=the_color


    ;---Add velocity.
        the_color = vel_color
        the_unit = vel_unit
        the_scale = vel_scale
        my_pos = polar_xy_set_axis(small_poss[*,1])
        polar_xy_draw_vector, vel_var, $
            mlat_var=mlat_var, mlt_var=mlt_var, $
            data_scale=the_scale, $
            plot_scale=plot_scale, $
            color=the_color, down_sample_cadence=down_sample_cadence
        polar_xy_draw_axis, south=is_south, mlt_label_mlat=55, $
            mlat_tickformat='(A1)'

        ; Add label and scale.
        len = polar_xy_mlat_to_dis(90-plot_scale)
        label_pos = [my_pos[0]+xchsz*1,my_pos[1]+ychsz*0.3]
        tmp = convert_coord(label_pos, normal=1, to_data=1)
        txs = tmp[0]+[0,len]
        tys = tmp[1]+[0,0]
        plots, txs, tys, data=1, color=the_color
        foreach tx, txs do begin
            tmp = convert_coord(tx,tys[0], data=1, to_normal=1)
            ttxs = tmp[0]+[0,0]
            ttys = tmp[1]+[-1,1]*ychsz*0.15
            plots, ttxs, ttys, normal=1, color=the_color
        endforeach
        mid_pos = [mean(txs),tys[0]]
        tmp = convert_coord(mid_pos, data=1, to_normal=1)
        tx = tmp[0]
        ty = tmp[1]+ychsz*0.3
        msg = string(the_scale,format='(I0)')+' '+the_unit
        xyouts, tx,ty,msg,normal=1, alignment=0.5, color=the_color
    
    
    ;---Draw orbit.
        line_color = sgcolor('silver')
        mlts = get_var_data(mlt_var, in=the_time_range, times=the_times)
        mlats = get_var_data(mlat_var, in=the_time_range)
        sc_xys = polar_xy_from_mlat_mlt(mlats, mlts)
        sc_xs = sc_xys[*,0]
        sc_ys = sc_xys[*,1]
        minor_times = make_bins(the_time_range, 60, inner=1)
        minor_xys = sinterpol(sc_xys, the_times, minor_times)
        major_times = make_bins(the_time_range, 300, inner=1)
        major_xys = sinterpol(sc_xys, the_times, major_times)
        major_tickns = time_string(major_times,tformat='hh:mm')
        major_xxs = major_xys[*,0]
        major_yys = major_xys[*,1]

        my_pos = big_pos
        my_pos = polar_xy_set_axis(my_pos)

        oplot, sc_xs, sc_ys, color=line_color

        set_circ, fill=1
        plots, minor_xys[*,0], minor_xys[*,1], psym=8, symsize=0.5, color=line_color

        foreach msg, major_tickns, ii do begin
            tmp = convert_coord(major_xxs[ii],major_yys[ii], data=1, to_normal=1)
            tx = tmp[0]
            ty = tmp[1]+ychsz*0.4
            plots, tmp[0], tmp[1], normal=1, psym=8, symsize=0.5, color=label_color
            xyouts, tx,ty,normal=1, msg, alignment=0.5, color=label_color
        endforeach

        ; Add letters.
        plot_labels = letters([0,3]+nplot_var)+'. '
        for pid=0,2 do begin
            my_pos = plot_poss[*,pid]
            tx = my_pos[0]+xchsz*0.5
            ty = my_pos[3]-ychsz*1.0
            msg = plot_labels[pid]
            xyouts, tx,ty,msg, normal=1
        endfor


        if keyword_set(test) then stop
        sgclose
    endforeach
    
    return, plot_files.toarray()
end

compile_opt idl2
test = 1

event_list = list()
; Qinghe's event.
event_list.add, dictionary($
    'time_range', ['2017-09-07/16:04','2017-09-07/16:17'], $
    'probe', 'f17')
; When there are v3d.
event_list.add, dictionary($
    'time_range', ['2013-05-01/00:53','2013-05-01/01:16'], $
    'probe', 'f18')
foreach event, event_list do begin
    tr = event['time_range']
    probe = event['probe']
    files = dmsp_gen_polar_region_survey_plot_v04(tr, probe=probe, test=test)
    print, files
endforeach
end
