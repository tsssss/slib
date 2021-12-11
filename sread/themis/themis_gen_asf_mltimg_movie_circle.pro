;+
; Generate a movie for asf on mlt/mlat. The circle version.
;-

pro themis_gen_asf_mltimg_movie_circle, time_range, filename=movie_file, $
    mlt_range=mlt_range, mlat_range=mlat_range, test=test, errmsg=errmsg, _extra=ex


    errmsg = ''
    if n_elements(movie_file) eq 0 then return
    if n_elements(time_range) ne 2 then return

    mltimg_var = 'thg_mltimg'
    if check_if_update(mltimg_var,time_range) then $
        themis_read_mltimg, time_range, _extra=ex
    get_data, mltimg_var, times, mltimg
    mlt_bins = get_setting(mltimg_var, 'mlt_bins')
    mlat_bins = get_setting(mltimg_var, 'mlat_bins')
    if n_elements(mlt_range) ne 2 then begin
        mlt_range = get_setting(mltimg_var, 'mlt_range')
    endif else begin
        index = lazy_where(mlt_bins, '[]', mlt_range, count=count)
        if count eq 0 then begin
            errmsg = 'No data in mlt_range ...'
            return
        endif
        mltimg = mltimg[*,index,*]
        mlt_bins = mlt_bins[index]
    endelse
    if n_elements(mlat_range) ne 2 then begin
        mlat_range = get_setting(mltimg_var, 'mlat_range')
    endif else begin
        index = lazy_where(mlat_bins, '[]', mlat_range, count=count)
        if count eq 0 then begin
            errmsg = 'No data in mlat_range ...'
            return
        endif
        mltimg = mltimg[*,*,index]
        mlat_bins = mlat_bins[index]
    endelse


;---Convert to the circular version.
    ntime = n_elements(times)
    nmlat_bin = n_elements(mlat_bins)
    npixel = nmlat_bin*2+1
    mltimg_circ = fltarr(ntime,npixel,npixel)

    nmlt_bin = n_elements(mlt_bins)
    nmlat_bin = n_elements(mlat_bins)
    old_image_size = [nmlt_bin,nmlat_bin]
    mlt_2d = mlt_bins # (fltarr(nmlat_bin)+1)
    mlat_2d = (fltarr(nmlt_bin)+1) # mlat_bins
    min_mlat = 50.
    sphere = 1
    foreach time, times, time_id do begin
        old_image = reform(mltimg[time_id,*,*])
        get_mlt_image, old_image, mlat_2d, mlt_2d, min_mlat, sphere, mcell=npixel, new_image
        mltimg_circ[time_id,*,*] = new_image
    endforeach
;    mlat_min = min(mlat_bins)
;    angle_bins = mlt_bins*15*constant('rad')
;    radius_bins = 90-mlat_bins
;    x_bins = mlat_min+radius_bins*sin(angle_bins)
;    y_bins = mlat_min-radius_bins*cos(angle_bins)


;---Prepare image size.
    pan_ysize = 4.
    pan_xsize = 4.
    margins = [2.,2,10,2]
    sgopen, 0, xsize=1, ysize=1, xchsz=abs_xchsz, ychsz=abs_ychsz
    xsize = total(margins[[0,2]])*abs_xchsz+pan_xsize
    ysize = total(margins[[1,3]])*abs_ychsz+pan_ysize
    aspect_ratio = xsize/ysize
    aspect_ratio <= 2
    xsize = aspect_ratio*ysize
    sgclose, /wdelete
    xchsz = abs_xchsz/xsize
    ychsz = abs_ychsz/ysize
    tpos = margins*([0,1,0,1]*ychsz+[1,0,1,0]*xchsz)
    tpos[[2,3]] = 1-tpos[[2,3]]
    cbpos = tpos & cbpos[[0,2]] = tpos[2]+xchsz*[1,2]
    reverse_ct = 0
    ct = 57 ; blue.
    zrange = [0,700]
    ztitle = 'Photon Count (#)'

    xtickv0 = [0.,6,12,18]
    xtickv = xtickv0/24*2*!dpi
    xtickn = string(xtickv0,format='(I02)')

    yrange = [min_mlat,90]
    ystep = 10.
    ytickv0 = make_bins(yrange, ystep, /inner)
    ytickv = (ytickv0-min_mlat)/(90-min_mlat)
    ytickn = string(ytickv0,format='(I0)')

    nangle = 50
    dangle = 2*!dpi/nangle
    angles = make_bins([0,2*!dpi], dangle)
    linestyle = 1


;---Gen image.
    root_dir = fgetpath(movie_file)
    if file_test(root_dir,/directory) then file_mkdir, root_dir
    fig_dir = join_path([root_dir,'tmp'])
    if file_test(fig_dir,/directory) then begin
        fig_files = file_search(fig_dir, '*')
        foreach fig_file, fig_files do if file_test(fig_file) eq 1 then file_delete, fig_file
        file_delete, fig_dir
    endif
    file_mkdir, fig_dir
    ntime = n_elements(times)
    fig_files = strarr(ntime)
    foreach time, times, time_id do begin
        fig_file = join_path([fig_dir,'fig_thg_asf_mltimg_circ_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+'.png'])
        if keyword_set(test) then fig_file = 0
        sgopen, fig_file, xsize=xsize, ysize=ysize

        timg = bytscl(reform(mltimg_circ[time_id,*,*]), min=zrange[0], max=zrange[1], top=254)
        sgtv, timg, resize=0, position=tpos, ct=ct, reverse_ct=reverse_ct
        sgcolorbar, zrange=zrange, ztitle=ztitle, ct=ct, position=cbpos, reverse_ct=reverse_ct

        plot, [-1,1], [-1,1], /nodata, /noerase, $
            xstyle=5, ystyle=5, $
            position=tpos

        foreach val, ytickv, val_id do begin
            txs = val*cos(angles)
            tys = val*sin(angles)
            plots, txs,tys, /data, linestyle=linestyle
            if float(ytickn[val_id]) eq min_mlat then continue
            tx = 0
            ty = 1-val
            xyouts, tx,ty,/data, alignment=0.5, ytickn[val_id]
        endforeach

        plots, [0,0], [-1,1], /data, linestyle=linestyle
        plots, [-1,1], [0,0], /data, linestyle=linestyle
        foreach val, xtickv, val_id do begin
            tmp = val-!dpi*0.5
            tx = cos(tmp)
            ty = sin(tmp)
            xyouts, tx,ty,/data, alignment=0.5, xtickn[val_id]
        endforeach


        tx = tpos[0]+xchsz*0.5
        ty = tpos[1]+ychsz*0.3
        xyouts, tx,ty, /normal, time_string(time)

        if keyword_set(test) then stop
        sgclose
        fig_files[time_id] = fig_file
    endforeach

;---Gen movie.
    spic2movie, fig_files, movie_file
    foreach fig_file, fig_files do file_delete, fig_file
    file_delete, fig_dir

end

test_file = join_path([homedir(),'test_asf.mp4'])
time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])
sites = ['mcgr','gako','whit']
min_elevs = [5,5,5]
mlat_range = [55,70]
mlon_range = !null
merge_method = 'merge_elev'

site_infos = themis_read_mlonimg_default_site_info(sites)
foreach min_elev, min_elevs, ii do site_infos[ii].min_elev = min_elev

themis_gen_asf_mltimg_movie_circle, time_range, sites=sites, site_infos=site_infos, $
    mlon_range=mlon_range, mlat_range=mlat_range, merge_method=merge_method, test=0, $
    filename=test_file
end
