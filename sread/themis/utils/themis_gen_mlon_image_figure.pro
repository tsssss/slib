;+
; Plot mlon image for given mlon image.
;-

function themis_gen_mlon_image_figure, mlon_image_var, $
    fig_dir=fig_dir, time_step=time_step, crop_method=crop_method, $
    mlon_range=mlon_range0, mlat_range=mlat_range0, zrange=zrange, ct=ct, _extra=extra

    get_data, mlon_image_var, times, mlon_images, limits=lim
    ntime = n_elements(times)
    if ntime eq 1 and times[0] eq 0 then begin
        errmsg = 'No mlon image ...'
        return, ''
    endif

;---Get the images we want.
    time_step0 = total(times[0:1]*[-1,1])
    if n_elements(time_step) eq 0 then time_step = time_step0
    index = findgen(ntime)
    step = round(time_step/time_step0)
    if step gt 1 then begin
        index = index[0:*:step]
        times = times[index]
        mlon_images = mlon_images[index,*,*]
        ntime = n_elements(times)
    endif

;---Get the cropping solution.
    if n_elements(crop_method) eq 0 then crop_method = 'auto'
    if crop_method eq 'auto' then begin
;        mlon_range = [-100d,20]
;        mlat_range = [50d,90]
        index = where(lim.illuminated_pixels ne 0)
        mlon_range = minmax(lim.pixel_mlon[index])
        mlat_range = minmax(lim.pixel_mlat[index])
        mlon_range = [floor(mlon_range[0]),ceil(mlon_range[1])]
        mlon_step = 5d
        mlon_range = [floor(mlon_range[0]/mlon_step)*mlon_step,ceil(mlon_range[1]/mlon_step)*mlon_step]
    endif
    if n_elements(mlat_range0) eq 2 then mlat_range = mlat_range0
    if n_elements(mlon_range0) eq 2 then mlon_range = mlon_range0

;---Rotate mlon image to be symmetric around -y.
    mlon_adjust = -mean(mlon_range)

    pixel_mlon = lim.pixel_mlon
    pixel_mlat = lim.pixel_mlat
    pixel_mlon = rot(pixel_mlon, mlon_adjust)
    pixel_mlat = rot(pixel_mlat, mlon_adjust)
    for ii=0,ntime-1 do mlon_images[ii,*,*] = rot(reform(mlon_images[ii,*,*]), mlon_adjust)

    index = where(pixel_mlon ge mlon_range[0] and pixel_mlon le mlon_range[1] $
        and pixel_mlat ge mlat_range[0] and pixel_mlat le mlat_range[1], complement=index_outside)
    
    xrange = minmax(lim.pixel_xpos[index])
    yrange = minmax(lim.pixel_ypos[index])
    image_size = lim.image_size
    crop_xrange = (xrange+1)*0.5*(image_size[0]-1)
    crop_yrange = (yrange+1)*0.5*(image_size[1]-1)

    mlon_step = 20d
    mlon_tickv = make_bins(mlon_range, mlon_step, inner=1)
    tt_tickv = (mlon_tickv)*constant('rad')
    mlat_step = 10d
    mlat_tickv = make_bins(mlat_range, mlat_step, inner=1)
    rr_tickv = (lim.mlat_range[1]-mlat_tickv)/(lim.mlat_range[1]-lim.mlat_range[0])
    tt_range = (mlon_range-mlon_adjust)*constant('rad')
    rr_range = (lim.mlat_range[1]-mlat_range)/(lim.mlat_range[1]-lim.mlat_range[0])
    nang = round(total(tt_range*[-1,1])*constant('deg')/360*60)>20
    angs = smkarthm(tt_range[0],tt_range[1],nang,'n')

;test = 1
    color_top = 254
    if n_elements(zrange) eq 0 then zrange = [0,1e4]
    ztitle = 'Count (#)'
    if n_elements(ct) eq 0 then ct = 49
    tick_linestyle= 1
    tick_color = sgcolor('silver')
    image_size = [total(crop_xrange*[-1,1])+1,total(crop_yrange*[-1,1])+1]
    margins = [2,2,2,4]
    if n_elements(fig_xsize) eq 0 then fig_xsize=5
    image_pos = panel_pos(plot_file, pansize=image_size/image_size[0]*fig_xsize, $
        margins=margins, fig_size=fig_size, xchsz=xchsz, ychsz=ychsz)
    
    fig_files = strarr(ntime)
    foreach time, times, time_id do begin
        the_image = reform(mlon_images[time_id,*,*])
        the_image[index_outside] = !values.f_nan
        the_image = the_image[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        base_name = 'thg_mlon_image_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+'.png'
        fig_file = join_path([fig_dir,base_name])
        fig_files[time_id] = fig_file
        if keyword_set(test) then fig_file = 0
        sgopen, fig_file, size=fig_size, xchsz=xchsz, ychsz=ychsz
        
    ;---Draw colorbar.
        cbpos = image_pos
        cbpos[1] = cbpos[3]+ychsz*1
        cbpos[3] = cbpos[1]+ychsz*0.5
        colors = findgen(color_top)
        sgcolorbar, colors, zrange=zrange, horizontal=1, ztitle=ztitle, position=cbpos, ct=ct
        
    ;---Draw image.
        tpos = image_pos
        sgtv, bytscl(the_image, min=zrange[0], max=zrange[1], top=color_top), ct=ct, position=tpos
        
        plot, xrange, yrange, $
            xstyle=5, xrange=xrange, $
            ystyle=5, yrange=yrange, $
            nodata=1, noerase=1, position=tpos
        
        ; Draw box.
        foreach tt, tt_range do begin
            tx = rr_range*cos(tt)
            ty = rr_range*sin(tt)
            plots, tx,ty, color=tick_color
        endforeach
        foreach rr, rr_range do begin
            tx = rr*cos(angs)
            ty = rr*sin(angs)
            plots, tx,ty, color=tick_color
        endforeach
        
        ; Draw ticks and tickname.
        foreach tt, tt_tickv, ii do begin
            tt -= mlon_adjust*constant('rad')
            tx = rr_range*cos(tt)
            ty = rr_range*sin(tt)
            oplot, tx,ty, linestyle=tick_linestyle, color=tick_color
            
            if ii eq 0 then continue
            tmp = max(tx^2+ty^2, index)
            tx = tx[index]
            ty = ty[index]
            msg = mlon_tickv[ii]
            msg = string(msg,format='(I4)')
            xyouts, tx,ty-ychsz*0.3, msg, alignment=0.5, color=tick_color
        endforeach
        foreach rr, rr_tickv, ii do begin
            tx = rr*cos(angs)
            ty = rr*sin(angs)
            oplot, tx,ty, linestyle=tick_linestyle, color=tick_color
            
            tx = tx[0]
            ty = ty[0]
            msg = string(mlat_tickv[ii],format='(I0)')
            xyouts, tx,ty-ychsz*0.3,msg, alignment=0.5, color=tick_color
        endforeach
        
        ; Add time.
        tx = tpos[0]
        ty = tpos[1]
        msg = time_string(time, tformat='YYYY-MM-DD/hh:mm:ss')
        xyouts, tx,ty,msg, normal=1, color=tick_color
        
        ty = tpos[1]+ychsz
        msg = 'MLon-MLat'
        xyouts, tx,ty,msg, normal=1, color=tick_color
        
        if keyword_set(test) then stop
        
        sgclose
    endforeach

    return, fig_files

end