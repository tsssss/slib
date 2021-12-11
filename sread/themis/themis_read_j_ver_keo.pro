;+
; Read asf KEOgram.
;
; time_range. Time range in unix time.
; mlt_range. MLT range in hr.
;-
pro themis_read_j_ver_keo, time_range, $
    mlt_range=mlt_range, mlat_range=mlat_range, $
    mlt_center=mlt_center

    if n_elements(mlt_range) eq 0 then mlt_range = [-1,1]*6


;---Settings.
    mlt_keo_var = 'thg_j_ver_keo'


;---Load MLT image.
    mltimg_var = 'thg_j_ver_mltimg'
    themis_read_current_mltimg, time_range, varname=mltimg_var
    get_data, mltimg_var, times, j_ver_mltimg
    ntime = n_elements(times)
    mlt_bins = get_setting(mltimg_var, 'mlt_bins')
    mlat_bins = get_setting(mltimg_var, 'mlat_bins')
    nmlt_bin = n_elements(mlon_bins)
    nmlat_bin = n_elements(mlat_bins)
    mlt_binsize = total(mlt_bins[0:1]*[-1,1])

    if n_elements(mlt_center) ne ntime then mlt_center = fltarr(ntime)
    if n_elements(mlat_range) ne 2 then mlat_range = minmax(mlat_bins)
    yrange = minmax(mlat_range)
    yextent = total(yrange*[-1,1])
    if yextent gt 20 then begin
        ystep = 10
    endif else if yextent gt 10 then begin
        ystep = 5
    endif else begin
        ystep = 1
    endelse
    ytickv = make_bins(yrange, ystep, /inner)
    yticks = n_elements(ytickv)-1
    yminor = ystep


;---Gen keo.
    keo = fltarr(ntime,nmlat_bin)
    foreach time, times, ii do begin
        the_mlt_range = mlt_range+mlt_center[ii]
        index = lazy_where(mlt_bins,'[]', the_mlt_range, count=count)
        if count eq 0 then continue

        tdata = reform(j_ver_mltimg[ii,index,*])
        for jj=0,nmlat_bin-1 do begin
            index = where(tdata[*,jj] ne 0, count)
            if count eq 0 then continue
            keo[ii,jj] = total(tdata[index,jj])/count
        endfor
    endforeach

    store_data, mlt_keo_var, times, keo, mlat_bins, limits={$
        spec: 1, $
        no_interp: 1, $
        ytitle: 'MLat (deg)', $
        ystyle: 1, $
        yrange: yrange, $
        ytickv: ytickv, $
        yticks: yticks, $
        yminor: yminor, $
        ztitle: 'Vertical current (A)', $
        zlog: 0 , $
        zrange: [-1,1]*.5e5, $
        color_table: 70, $
        reverse_color_table: 1, $
        yticklen: -0.02, $
        xticklen: -0.02 }

end

mlt_range = [0,12]
time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])
;time_range = time_double(['2014-08-28/10:00','2014-08-28/11:00'])
;mlt_range = [-6,6]
;time_range = time_double(['2013-06-07/03:30','2013-06-07/07:00'])
themis_read_j_ver_keo, time_range, mlt_range=mlt_range

end
