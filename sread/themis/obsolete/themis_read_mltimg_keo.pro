;+
; Read MLT image KEOgram.
;
; time_range. Time range in unix time.
; mlt_range=. MLT range for calc KEOgram, in deg.
; mlat_range=. MLat range in hr.
;-
pro themis_read_mltimg_keo, time_range, mlat_range=mlat_range, $
    mlt_range=mlt_range, _extra=ex

    if n_elements(mlat_range) eq 0 then mlat_range = [60.,70]
    if n_elements(mlt_range) eq 0 then mlt_range = [-1,1]*6


;---Settings.
    the_var = 'thg_asf_keo'


;---Load MLon image.
    mltimg_var = 'thg_mltimg'
    themis_read_mltimg, time_range, varname=mltimg_var, _extra=ex
    get_data, mltimg_var, times, j_new
    ntime = n_elements(times)
    mlt_bins = get_setting(mltimg_var, 'mlt_bins')
    mlat_bins = get_setting(mltimg_var, 'mlat_bins')
    nmlt_bin = n_elements(mlt_bins)
    nmlat_bin = n_elements(mlat_bins)
    mlt_binsize = total(mlt_bins[0:1]*[-1,1])


;---Gen keo.
    mlt_index = lazy_where(mlt_bins, '[]', mlt_range, count=mlt_count)
    if mlt_count eq 0 then return
    ewo = total(j_new[*,mlt_index,*],2)/mlt_count

    mlat_extent = abs(total(mlat_range*[-1,1]))
    if mlat_extent ge 20 then begin
        ystep = 10
    endif else if mlat_extent ge 10 then begin
        ystep = 5
    endif else if mlat_extent ge 5 then begin
        ystep = 1
    endif else ystep = mlat_extent/2
    ytickv = make_bins(mlt_range, ystep)
    yticks = n_elements(ytickv)-1
    yminor = ystep
    store_data, mlt_keo_var, times, ewo, mlat_bins, limits={$
        spec: 1, $
        no_interp: 1, $
        ytitle: 'MLat (deg)', $
        ystyle: 1, $
        yrange: mlat_range, $
        ytickv: ytickv, $
        yticks: yticks, $
        yminor: yminor, $
        ztitle: 'Photon count (#)', $
        zlog: 0 , $
        zrange: [0,300], $
        yticklen: -0.02, $
        xticklen: -0.02 }


end

mlt_range = [-1,1]*6
time_range = time_double(['2013-06-07/04:00','2013-06-07/07:00'])
themis_read_mltimg_keo, time_range, mlt_range=mlt_range

end
