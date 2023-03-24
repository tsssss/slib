;+
; Plot the raw count of the image at the center time and selective pixels at all times.
;
; input_time_range. Input time range in string or unix time.
; site=. Required input, a string for site.
; test_time=. Optional. By default is the frame with max total count.
; filename=. Set to plot to that file.
;-
pro themis_plot_asi_raw_count_survey, input_time_range, site=site, test_time=test_time, filename=plot_file

    prefix = 'thg_'+site+'_'
    time_range = time_double(input_time_range)
    asf_var = themis_read_asf(time_range, site=site, errmsg=errmsg)
    if errmsg ne '' then return

    if n_elements(plot_file) eq 0 then plot_file = 0
    margins = [1,3,2,1]
    xpad = 16
    poss = panel_pos(plot_file, fig_size=fig_size, $
        nxpan=2, nypan=1, pansize=[2,2], xpans=[1,1.5], $
        margins=margins, xpad=xpad)
    sgopen, plot_file, xsize=fig_size[0], ysize=fig_size[1], $
        xchsz=xchsz, ychsz=ychsz


;---Collect info for test image and pixel counts.
    get_data, asf_var, times, imgs_raw, limits=lim
    ntime = n_elements(times)
    image_size = lim.image_size

    if n_elements(test_time) eq 0 then begin
        test_index = ntime*0.5
        tmp = max(total(total(imgs_raw,2),2), test_index)
        test_time = times[test_index]
    endif
    test_time = time_double(test_time)
    test_index = where(times eq test_time)



    nx = 8
    ny = 8
    dx = image_size[0]/nx
    dy = image_size[1]/ny
    test_xs = smkarthm(dx,image_size[0]-dx,dx,'dx')
    test_ys = smkarthm(dy,image_size[1]-dy,dy,'dx')
    test_pixels = list()
    foreach test_x, test_xs do begin
        foreach test_y, test_ys do begin
            test_pixels.add, [test_x,test_y]
        endforeach
    endforeach

;    test_xs = float([32,64,128,192,224])
    test_xs = smkarthm(dx,image_size[0]-dx,dx,'dx')
    test_ys = test_xs
    test_pixels = list()
    foreach test_x, test_xs do begin
        test_y = test_x
        test_pixels.add, [test_x,test_y]
;        test_y2 = image_size[1]-test_y
;        if test_y2 eq test_y then continue
;        test_pixels.add, [test_x,test_y2]
    endforeach

    ; Add moon.
    site_info = themis_asi_read_site_info(site)
    center_glon = site_info.asc_glon
    center_glat = site_info.asc_glat
    moon_elev = moon_elev(test_time, $
        center_glon, center_glat, azimuth=moon_azim, degree=1)
    min_moon_elev = 10d ; deg
    if moon_elev ge min_moon_elev then begin
        asf_info = themis_asi_read_pixel_info(time_range, site=site)
        elev = asf_info.asf_elev
        azim = asf_info.asf_azim
        moon_dis = sqrt((elev-moon_elev)^2+(azim-moon_azim)^2)
        tmp = min(moon_dis, moon_index)
        moon_index = array_indices(elev, moon_index)
        test_pixels.add, moon_index
    endif

    ntest_pixel = n_elements(test_pixels)
    test_pixels = test_pixels.toarray()
    center_dis = sqrt($
        (test_pixels[*,0]-image_size[0]*0.5)^2+$
        (test_pixels[*,1]-image_size[1]*0.5)^2)
    test_pixels = test_pixels[reverse(sort(center_dis)),*]
    color_bottom = 0
    color_top = 254
    pixel_ct = 33
    pixel_colors = (smkarthm(color_bottom,color_top,ntest_pixel,'n'))
    for ii=0,ntest_pixel-1 do begin
        pixel_colors[ii] = sgcolor(pixel_colors[ii],ct=pixel_ct)
    endfor


;---Plot test image.
    zrange = [0,65535]
    ztitle = 'Count (#)'
    image_ct = 49
    test_image = reform(imgs_raw[test_index,*,*])
    test_image = bytscl(test_image, min=zrange[0], max=zrange[1], top=color_top)
    tpos = poss[*,0]
    sgtv, test_image, ct=image_ct, position=tpos

    xrange = [0,image_size[0]-1]
    yrange = [0,image_size[1]-1]
    plot, xrange, yrange, $
        xstyle=5, xrange=xrange, $
        ystyle=5, yrange=yrange, $
        noerase=1, nodata=1, position=tpos
    for test_id=0,ntest_pixel-1 do begin
        test_x = test_pixels[test_id,0]
        test_y = test_pixels[test_id,1]
        plots, test_x,test_y, data=1, color=pixel_colors[test_id], psym=1
    endfor
    tx = tpos[0]
    ty = tpos[1]-ychsz
    msg = 'a) '+strupcase(site)+' '+time_string(test_time)
    xyouts, tx,ty,normal=1, msg

    cbpos = tpos
    cbpos[0] = tpos[2]+xchsz*0.5
    cbpos[2] = cbpos[0]+xchsz*1
    colors = smkarthm(color_bottom,color_top,1,'dx')
    zstep = 2e4
    ztickv = make_bins(zrange, zstep, inner=1)
    zticks = n_elements(ztickv)
    sgcolorbar, colors, $
        zrange=zrange, ztitle=ztitle, ztickv=ztickv, zticks=zticks, $
        ct=image_ct, position=cbpos, zcharsize=1


;---Plot pixel counts.
    tpos = poss[*,1]
    xrange = time_range
    xstep = 20*60
    xminor = 4
    xtickv = make_bins(xrange, xstep, inner=1)
    xticks = n_elements(xtickv)-1
    xtickn = time_string(xtickv,tformat='hh:mm')
    xtickn[0] = time_string(xtickv[0],tformat='YYYY-MM-DD')
    yrange = zrange
    yrange = [1e3,65535]
    ytitle = 'Count (#)'
    xticklen = -0.02
    yticklen = -0.02

    plot, xrange, yrange, $
        xstyle=5, xlog=0, xrange=xrange, $
        ystyle=5, ylog=1, yrange=yrange, $
        noerase=1, nodata=1, position=tpos
    for test_id=0,ntest_pixel-1 do begin
        test_x = test_pixels[test_id,0]
        test_y = test_pixels[test_id,1]
        count_raw = imgs_raw[*,test_x,test_y]>1
        plots, times[0:*:1], count_raw[0:*:1], color=pixel_colors[test_id]
    endfor

    plot, xrange, yrange, $
        xstyle=1, xlog=0, xrange=xrange, $
        xticks=xticks, xtickv=xtickv, xtickname=xtickn, xminor=xminor, $
        xticklen=xticklen, yticklen=yticklen, ytitle=ytitle, $
        ystyle=1, ylog=1, yrange=yrange, $
        noerase=1, nodata=1, position=tpos
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1
    msg = 'b)'
    xyouts, tx,ty,normal=1, msg
    plots, test_time+[0,0], yrange, linestyle=1


    sgclose

end

time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
site = 'gako'
test_time = '2016-10-13/12:10'

time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon, at 160,70 at t=0.
site = 'inuv'
test_time = !null

time_range = time_double(['2008-01-17/03:00','2008-01-17/04:00'])   ; moon, at 40,140
site = 'kuuj'
test_time = !null

time_range = time_double(['2016-01-28/08:00','2016-01-28/09:00'])
site = 'snkq'
test_time = !null

themis_plot_asi_raw_count_survey, time_range, site=site, test_time=test_time
end
