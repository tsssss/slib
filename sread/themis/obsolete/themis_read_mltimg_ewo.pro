;+
; Read MLT image EWOgram.
;
; time_range. Time range in unix time.
; mlt_range=. MLT range in hr.
; mlat_range=. MLat range for calc EWOgram, in deg.
;-
pro themis_read_mltimg_ewo, time_range, mlat_range=mlat_range, $
    mlt_range=mlt_range, _extra=ex

    if n_elements(mlat_range) eq 0 then mlat_range = [60.,70]
    if n_elements(mlt_range) eq 0 then mlt_range = [-1,1]*6


;---Settings.
    mlt_ewo_var = 'thg_asf_ewo'


;---Load MLT image.
    mltimg_var = 'thg_mltimg'
    themis_read_mltimg, time_range, varname=mltimg_var, _extra=ex
    get_data, mltimg_var, times, j_new
    ntime = n_elements(times)
    mlt_bins = get_setting(mltimg_var, 'mlt_bins')
    mlat_bins = get_setting(mltimg_var, 'mlat_bins')
    nmlt_bin = n_elements(mlt_bins)
    nmlat_bin = n_elements(mlat_bins)
    mlt_binsize = total(mlt_bins[0:1]*[-1,1])


;---Gen ewo.
    mlat_index = where_pro(mlat_bins, '[]', mlat_range, count=mlat_count)
    if mlat_count eq 0 then return
    ewo = total(j_new[*,*,mlat_index],3)/mlat_count

    mlt_extent = abs(total(mlt_range*[-1,1]))
    if mlt_extent ge 6 then begin
        ystep = 3
    endif else if mlt_extent ge 2 then begin
        ystep = 1
    endif else if mlt_extent ge 1 then begin
        ystep = 0.5
    endif else ystep = mlt_extent/2
    ytickv = make_bins(mlt_range, ystep)
    yticks = n_elements(ytickv)-1
    yminor = ystep
    store_data, mlt_ewo_var, times, ewo, mlt_bins, limits={$
        spec: 1, $
        no_interp: 1, $
        ytitle: 'MLT (hr)', $
        ystyle: 1, $
        yrange: mlt_range, $
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
themis_read_mltimg_ewo, time_range, mlt_range=mlt_range

end
