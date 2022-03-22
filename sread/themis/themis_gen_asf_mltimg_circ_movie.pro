;+
; Generate a movie for asf on mlt/mlat. The circle version.
; zrange=. The zrange (color) for auroral images.
; reset_images=. Boolean, set to regenerate images. By default is 0.
; min_mlat=. In deg, by default is 50 deg.
;-

pro themis_gen_asf_mltimg_circ_movie, time_range, filename=movie_file, $
    sites=sites, zrange=zrange, min_mlat=min_mlat, reset_images=reset_images, $
    test=test, errmsg=errmsg, _extra=ex


    errmsg = ''
    if n_elements(movie_file) eq 0 then return
    if n_elements(time_range) ne 2 then return
    if n_elements(zrange) ne 2 then zrange = [0,300]
    if n_elements(min_mlat) eq 0 then min_mlat = 50d

    themis_read_mltimg_circ, time_range, sites=sites, save_file=1
    mltimg_circ_var = 'thg_mltimg_circ'
    get_data, mltimg_circ_var, times, mltimg_circ


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
    ztitle = 'Norm. Count (#)'

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
    fig_dir = join_path([root_dir,'asf_mltimg_circ'])
    if keyword_set(reset_images) then begin
        fig_files = file_search(fig_dir+'/*', count=count)
        for ii=0,count-1 do file_delete, fig_files[ii]
    endif
    if ~file_test(fig_dir,directory=1) then file_mkdir, fig_dir
    ntime = n_elements(times)
    fig_files = strarr(ntime)
    foreach time, times, time_id do begin
        fig_file = join_path([fig_dir,'fig_thg_asf_mltimg_circ_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+'.png'])
        if file_test(fig_file) then begin
            fig_files[time_id] = fig_file
            continue
        endif
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
    spic2movie, movie_file, plot_files=fig_files
    if keyword_set(remove_plots) then begin
        foreach fig_file, fig_files do file_delete, fig_file
        file_delete, fig_dir
    endif

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

themis_gen_asf_mltimg_circ_movie, time_range, sites=sites, site_infos=site_infos, $
    mlon_range=mlon_range, mlat_range=mlat_range, merge_method=merge_method, test=0, $
    filename=test_file
end
