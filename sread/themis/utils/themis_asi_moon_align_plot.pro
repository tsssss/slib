;+
; Remove moon for a given asf_var.
;-

function elev_azim_to_r, elevs, azims

    deg = constant('deg')
    rad = constant('rad')
    
    dims = size(elevs, dimensions=1)
    if n_elements(elevs) eq 1 then dims = [1]
    ndim = 3
    
    theta = elevs*rad
    phi = azims*rad
    
    rrs = fltarr([product(dims),ndim])
    rrs[*,0] = cos(theta)*cos(phi)
    rrs[*,1] = cos(theta)*sin(phi)
    rrs[*,2] = sin(theta)
    
    rrs = reform(rrs, [dims,ndim])
    return, rrs
    
end


function r_to_elev_azim, rrs

    deg = constant('deg')
    rad = constant('rad')

    dims = size(rrs, dimensions=1)
    ndim = n_elements(dims)
    if ndim eq 1 then begin
        dims = [1]
        ndim = 3
    endif else begin
        dims = dims[0:ndim-2]
        ndim = 3
    endelse

    the_rrs = reform(rrs, [product(dims),ndim])
    
    tts = fltarr([product(dims),2])
    tts[*,0] = asin(the_rrs[*,2])*deg
    tts[*,1] = atan(the_rrs[*,1],the_rrs[*,0])*deg
    tts = reform(tts, [dims,2])
    
    return, tts

end


function find_pixel_index, the_elev, the_azim, pixel_elevs, pixel_azims

    the_rr = elev_azim_to_r(the_elev, the_azim)
    pixel_rrs = elev_azim_to_r(pixel_elevs, pixel_azims)


    angles = acos($
        pixel_rrs[*,*,0]*the_rr[0]+$
        pixel_rrs[*,*,1]*the_rr[1]+$
        pixel_rrs[*,*,2]*the_rr[2])*constant('deg')
    min_angle = min(angles, index)
    index2d = array_indices(pixel_elevs, index)
    return, index2d
end



function themis_asi_moon_align_plot, asf_var, test=test, plot_dir=plot_dir

    ; Read asf images.
    get_data, asf_var, times, asf_images
    site = get_setting(asf_var, 'site')
    time_range = minmax(times)
    moon_vars = themis_asi_read_moon_pos(time_range, site=site)
    moon_elev_var = moon_vars['moon_elev']
    moon_azim_var = moon_vars['moon_azim']
    
    pixel_elevs = get_setting(asf_var, 'pixel_elev')
    pixel_azims = get_setting(asf_var, 'pixel_azim')
    pixel_rrs = elev_azim_to_r(pixel_elevs, pixel_azims)
    
    deg = constant('deg')
    rad = constant('rad')
    
    image_size = get_setting(asf_var, 'image_size')
    nxpan = 3
    
    ct = 49
    zrange = [4000d,40000]
    color_top = 254
    
    
    time_step = 3
    time1_id = 0
    time1 = times[time1_id]
        
    elev1 = get_var_data(moon_elev_var, at=time1)
    azim1 = get_var_data(moon_azim_var, at=time1)
    moon1_index2d = find_pixel_index(elev1,azim1, pixel_elevs, pixel_azims)

    dtimes = [30,60,90,120]*60
    ndtime = n_elements(dtimes)
    labels = letters(ndtime)
    nypan = ndtime

    if n_elements(plot_dir) eq 0 then plot_dir = srootdir()
    plot_file = join_path([plot_dir,'themis_asi_moon_align_plot_'+time_string(time1,tformat='YYYY_MMDD_hh_mm')+'_v01.pdf'])
    sgopen, plot_file, size=2*[nxpan,nypan], xchsz=xchsz, ychsz=ychsz, test=test
    poss = sgcalcpos(nypan,nxpan, xpad=0,ypad=0, margins=[0,0,0,0])

    foreach dtime, dtimes, dtime_id do begin
        time2 = time1+dtime
        time2_id = dtime/time_step
        elev2 = get_var_data(moon_elev_var, at=time2)
        azim2 = get_var_data(moon_azim_var, at=time2)
        moon2_index2d = find_pixel_index(elev2,azim2, pixel_elevs, pixel_azims)
        
        r1 = elev_azim_to_r(elev1, azim1)
        r2 = elev_azim_to_r(elev2, azim2)
        r_center = sunitvec(vec_cross(r1,r2))
        t_center = r_to_elev_azim(r_center)
        elev_center = t_center[0]
        azim_center = t_center[1]
        center_index2d = find_pixel_index(elev_center,azim_center, pixel_elevs, pixel_azims)
        apparent_r1 = moon1_index2d-center_index2d
        apparent_r2 = moon2_index2d-center_index2d
        delta_angle = sang(apparent_r1, apparent_r2, deg=1)


        xrange = [0,image_size[0]-1]
        yrange = [0,image_size[1]-1]
        
        tpos = poss[*,0,dtime_id]
        the_image1 = bytscl(reform(asf_images[time1_id,*,*]), min=zrange[0], max=zrange[1], top=color_top)
        sgtv, the_image1, position=tpos, ct=ct
        msg = labels[dtime_id]+'-1) T0'
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1
        xyouts, tx,ty,normal=1, msg

        msg = strupcase(site)+', '+time_string(time1)
        tx = tpos[0]+xchsz*0.5
        ty = tpos[1]+ychsz*0.2
        xyouts, tx,ty,normal=1, msg
        
        plot, xrange, yrange, $
            xstyle=5, xrange=xrange, $
            ystyle=5, yrange=yrange, $
            nodata=1, noerase=1, position=tpos
        plots, moon1_index2d[0], moon1_index2d[1], psym=1, color=sgcolor('yellow')
        plots, moon2_index2d[0], moon2_index2d[1], psym=1, color=sgcolor('green')
        plots, center_index2d[0], center_index2d[1], psym=1, color=sgcolor('blue')

    
        tpos = poss[*,1,dtime_id]
        the_image2 = bytscl(reform(asf_images[time2_id,*,*]), min=zrange[0], max=zrange[1], top=color_top)
        sgtv, the_image2, position=tpos, ct=ct
        msg = labels[dtime_id]+'-2) T0 + '+string(dtime/60,format='(I0)')+' min'
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1
        xyouts, tx,ty,normal=1, msg
        

        plot, xrange, yrange, $
            xstyle=5, xrange=xrange, $
            ystyle=5, yrange=yrange, $
            nodata=1, noerase=1, position=tpos
        plots, moon1_index2d[0], moon1_index2d[1], psym=1, color=sgcolor('yellow')
        plots, moon2_index2d[0], moon2_index2d[1], psym=1, color=sgcolor('green')
        plots, center_index2d[0], center_index2d[1], psym=1, color=sgcolor('blue')

        tpos = poss[*,2,dtime_id]
        the_image2_rot = rot(the_image2,-delta_angle, 1, center_index2d[0], center_index2d[1], pivot=1, missing=1)
        sgtv, the_image2_rot, position=tpos, ct=ct
        
        msg = labels[dtime_id]+'-3) T0 + '+string(dtime/60,format='(I0)')+' min Rotated'
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1
        xyouts, tx,ty,normal=1, msg

        plot, xrange, yrange, $
            xstyle=5, xrange=xrange, $
            ystyle=5, yrange=yrange, $
            nodata=1, noerase=1, position=tpos
        plots, moon1_index2d[0], moon1_index2d[1], psym=1, color=sgcolor('yellow')
        plots, moon2_index2d[0], moon2_index2d[1], psym=1, color=sgcolor('green')
        plots, center_index2d[0], center_index2d[1], psym=1, color=sgcolor('blue')
    endforeach

    sgclose
    return, plot_file

end


test = 0
event_list = list()

event_list.add, dictionary($
    'time_range', ['2015-01-01/00:00','2015-01-01/05:00'], $
    'site', 'rank' )
event_list.add, dictionary($
    'time_range', ['2008-01-19/06:00','2008-01-19/10:00'], $
    'site', 'inuv' )

foreach event, event_list do begin
    time_range = time_double(event['time_range'])
    site = event['site']
    asf_var = themis_read_asf(time_range, site=site, get_name=1)
    if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)
    plot_file = themis_asi_moon_align_plot(asf_var, test=test)
endforeach
end