;+
; Generate a movie for asf on mlon/mlat.
;-

pro themis_gen_asf_mlonimg_movie, time_range, filename=movie_file, $
    mlon_range=mlon_range, mlat_range=mlat_range, test=test, errmsg=errmsg, $
    _extra=ex


    errmsg = ''
    if n_elements(movie_file) eq 0 then return
    if n_elements(time_range) ne 2 then return

    mlonimg_var = 'thg_mlonimg'
    if check_if_update(mlonimg_var, time_range) then $
        themis_read_mlonimg, time_range, _extra=ex
    get_data, mlonimg_var, times, mlonimg
    mlon_bins = get_setting(mlonimg_var, 'mlon_bins')
    mlat_bins = get_setting(mlonimg_var, 'mlat_bins')
    if n_elements(mlon_range) ne 2 then begin
        mlon_range = get_setting(mlonimg_var, 'mlon_range')
    endif else begin
        index = lazy_where(mlon_bins, '[]', mlon_range, count=count)
        if count eq 0 then begin
            errmsg = 'No data in mlon_range ...'
            return
        endif
        mlonimg = mlonimg[*,index,*]
        mlon_bins = mlon_bins[index]
    endelse
    if n_elements(mlat_range) ne 2 then begin
        mlat_range = get_setting(mlonimg_var, 'mlat_range')
    endif else begin
        index = lazy_where(mlat_bins, '[]', mlat_range, count=count)
        if count eq 0 then begin
            errmsg = 'No data in mlat_range ...'
            return
        endif
        mlonimg = mlonimg[*,*,index]
        mlat_bins = mlat_bins[index]
    endelse


;---Prepare image size.
    nmlon_bin = n_elements(mlon_bins)
    nmlat_bin = n_elements(mlat_bins)
    pan_ysize = 4.
    pan_xsize = pan_ysize/nmlat_bin*nmlon_bin
    margins = [10.,5,10,2]
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
    cbpos = tpos & cbpos[[0,2]] = tpos[2]+xchsz*[0.5,1.5]
    ct = 57 ; blue.
    zrange = [0,700]
    ztitle = 'Photon Count (#)'

    xrange = mlon_range
    xtitle = 'MLon (deg)'
    xextent = total(xrange*[-1,1])
    if xextent ge 100 then begin
        xstep = 50.
    endif else if xextent ge 50 then begin
        xstep = 10.
    endif
    xtickv = make_bins(xrange, xstep, /inner)
    xticks = n_elements(xtickv)-1
    xminor = 5

    yrange = mlat_range
    ytitle = 'MLat (deg)'
    yextent = total(yrange*[-1,1])
    if yextent ge 10 then begin
        ystep = 5.
    endif else if yextent ge 5 then begin
        ystep = 1.
    endif
    ytickv = make_bins(yrange, ystep, /inner)
    yticks = n_elements(ytickv)-1
    yminor = ystep

    xticklen_chsz = -0.15
    yticklen_chsz = -0.40
    xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])

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
        fig_file = join_path([fig_dir,'fig_thg_asf_mlonimg_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+'.png'])
        if keyword_set(test) then fig_file = 0
        sgopen, fig_file, xsize=xsize, ysize=ysize

        timg = bytscl(reform(mlonimg[time_id,*,*]), min=zrange[0], max=zrange[1], top=254)
        sgtv, timg, resize=1, position=tpos, ct=ct
        sgcolorbar, zrange=zrange, ztitle=ztitle, ct=ct, position=cbpos

        plot, xrange, yrange, /nodata, /noerase, $
            xrange=xrange, xstyle=1, xtitle=xtitle, xtickv=xtickv, xticks=xticks, xminor=xminor, xticklen=xticklen, $
            yrange=yrange, ystyle=1, ytitle=ytitle, ytickv=ytickv, yticks=yticks, yminor=yminor, yticklen=yticklen, $
            position=tpos

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

themis_gen_asf_mlonimg_movie, time_range, sites=sites, site_infos=site_infos, $
    mlon_range=mlon_range, mlat_range=mlat_range, merge_method=merge_method, test=0, $
    filename=test_file

end
