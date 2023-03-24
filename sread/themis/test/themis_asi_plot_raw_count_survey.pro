;+
; This is adopted from themis_plot_asi_raw_count_survey.
; 
; asf_images.
; times.
; test_time=.
; ntest_pixel=.
;-

function themis_asi_plot_raw_count_survey, asf_images, times, test_time=test_time, ntest_pixel=ntest_pixel


    image_size = size(reform(asf_images[0,*,*]),dimensions=1)
    ntime = n_elements(asf_images[*,0,0])
    if n_elements(times) eq 0 then times = findgen(ntime)
    time_range = minmax(times)
    if n_elements(test_time) eq 0 then test_time = mean(minmax(times))
    tmp = min(times-test_time, test_index, abs=1)


;---Add test pixels.
    nx = 8
    ny = 8
    dx = image_size[0]/nx
    dy = image_size[1]/ny

;;    test_xs = float([32,64,128,192,224])
;    test_xs = smkarthm(dx,image_size[0]-dx,dx,'dx')
;    test_ys = test_xs
;    test_pixels = list()
;    foreach test_x, test_xs do begin
;        test_y = test_x
;        test_pixels.add, [test_x,test_y]
;        test_pixels.add, [test_x,image_size[1]-test_y]
;    endforeach
;
;    ; Add moon.
;    max_count = 65535
;    for ii=0,image_size[0]-1 do begin
;        for jj=0,image_size[1]-1 do begin
;            if max(asf_images[*,ii,jj]) ge max_count then begin
;                test_pixels.add, [ii,jj]
;                break
;            endif
;        endfor
;        break
;    endfor
;    ntest_pixel = n_elements(test_pixels)
;    test_pixels = test_pixels.toarray()

;    ;---Prepare settings for test pixels.
;    center_dis = sqrt($
;        (test_pixels[*,0]-image_size[0]*0.5)^2+$
;        (test_pixels[*,1]-image_size[1]*0.5)^2)
;    test_pixels = test_pixels[reverse(sort(center_dis)),*]
;    color_bottom = 0
;    color_top = 254
;    pixel_ct = 33
;    pixel_colors = (smkarthm(color_bottom,color_top,ntest_pixel,'n'))
;    for ii=0,ntest_pixel-1 do begin
;        pixel_colors[ii] = sgcolor(pixel_colors[ii],ct=pixel_ct)
;    endfor


    if n_elements(ntest_pixel) eq 0 then ntest_pixel = 10
    test_pixels = fltarr(ntest_pixel,2)
    avg_counts = fltarr(image_size)
    for ii=0,image_size[0]-1 do begin
        for jj=0,image_size[1]-1 do begin
            tmp = asf_images[*,ii,jj]<65535
            index = where(tmp ne 0, count)
            if count eq 0 then continue
            avg_counts[ii,jj] = mean(tmp[index])
        endfor
    endfor
    sort_index = sort(avg_counts)
    values = smkgmtrc(5e3,max(avg_counts), ntest_pixel, 'n')
    
    for ii=0,ntest_pixel-1 do begin
        tmp = min(avg_counts-values[ii], index, abs=1)
        test_pixels[ii,*] = array_indices(image_size, index, dimension=1)
    endfor

    color_bottom = 100
    color_top = 254
    pixel_ct = 65
    pixel_colors = reverse(smkarthm(color_bottom,color_top,ntest_pixel,'n'))
    for ii=0,ntest_pixel-1 do begin
        pixel_colors[ii] = sgcolor(pixel_colors[ii],ct=pixel_ct)
    endfor



;---Plot test image.
    if n_elements(plot_file) eq 0 then plot_file = 0
    margins = [1,3,2,1]
    xpad = 16
    poss = panel_pos(plot_file, fig_size=fig_size, $
        nxpan=2, nypan=1, pansize=[2,2], xpans=[1,1.5], $
        margins=margins, xpad=xpad)
    sgopen, plot_file, xsize=fig_size[0], ysize=fig_size[1], $
        xchsz=xchsz, ychsz=ychsz

    zrange = [0,65535]
    ztitle = 'Count (#)'
    image_ct = 49
    test_image = reform(asf_images[test_index,*,*])
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
;    msg = 'a) '+strupcase(site);+' '+time_string(test_time)
    msg = 'a) '+time_string(test_time)
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
    yrange = [3e3,1e5]
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
        count_raw = 1>asf_images[*,test_x,test_y]<65535
        oplot, times[0:*:1], count_raw[0:*:1], color=pixel_colors[test_id]
        ;plots, times, count_raw, color=pixel_colors[test_id]
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
    
    return, avg_counts

end