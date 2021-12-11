;+
; Generate a movie for vertical currents on mlt/mlat.
;-

pro themis_gen_j_ver_mltimg_movie, time_range, filename=movie_file, $
    mlt_range=mlt_range, mlat_range=mlat_range, test=test, errmsg=errmsg


    errmsg = ''
    if n_elements(movie_file) eq 0 then return
    if n_elements(time_range) ne 2 then return

    mltimg_var = 'thg_j_ver_mltimg'
    themis_read_current_mltimg, time_range
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


;---Prepare image size.
    nmlt_bin = n_elements(mlt_bins)
    nmlat_bin = n_elements(mlat_bins)
    pan_ysize = 4.
    pan_xsize = pan_ysize/nmlat_bin*nmlt_bin
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
    ct = 70 ; red-blue.
    reverse_ct = 1
    zrange = [-1,1]*2.5e5
    ztitle = 'Vertical current (A) Upward (+)'

    xrange = mlt_range
    xtitle = 'MLT (hr)'
    xextent = total(xrange*[-1,1])
    if xextent ge 6 then begin
        xstep = 3
        xminor = 3
    endif else if xextent ge 3 then begin
        xstep = 1
        xminor = 2
    endif
    xtickv = make_bins(xrange, xstep, /inner)
    xticks = n_elements(xtickv)-1

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

    xticklen_chsz = -0.2
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
        fig_file = join_path([fig_dir,'fig_thg_j_ver_mltimg_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+'.png'])
        if keyword_set(test) then fig_file = 0
        sgopen, fig_file, xsize=xsize, ysize=ysize

        timg = bytscl(reform(mltimg[time_id,*,*]), min=zrange[0], max=zrange[1])
        sgtv, timg, resize=1, position=tpos, ct=ct, reverse_ct=reverse_ct
        sgcolorbar, zrange=zrange, ztitle=ztitle, ct=ct, position=cbpos, reverse_ct=reverse_ct

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


time_range = time_double(['2014-08-28/10:00','2014-08-28/11:00'])
time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])
time_range = time_double(['2013-06-07/03:30','2013-06-07/07:00'])
test_file = join_path([homedir(),'test.mp4'])
themis_gen_j_ver_mltimg_movie, time_range, filename=test_file, test=0
end
