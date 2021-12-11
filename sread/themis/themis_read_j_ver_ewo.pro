;+
; Read downward or upward current EWOgram.
;
; time_range. Time range in unix time.
; mlt_range=. MLT range in hr.
; mlat_range=. MLat range for calc EWOgram, in deg.
; direction=. 'up' or 'down'.
;-
pro themis_read_j_ver_ewo, time_range, mlat_range=mlat_range, $
    mlt_range=mlt_range, $
    direction=direction

    if n_elements(mlat_range) eq 0 then mlat_range = [60.,70]
    if n_elements(mlt_range) eq 0 then mlt_range = [-1,1]*6
    if n_elements(direction) eq 0 then direction = 'up'


;---Settings.
    mlt_ewo_var = 'thg_j_'+direction+'_ewo'


;---Load MLon image.
    mltimg_var = 'thg_j_ver_mltimg'
    themis_read_current_mltimg, time_range, varname=mltimg_var
    get_data, mltimg_var, times, j_new
    ntime = n_elements(times)
    mlt_bins = get_setting(mltimg_var, 'mlt_bins')
    mlat_bins = get_setting(mltimg_var, 'mlat_bins')
    nmlt_bin = n_elements(mlt_bins)
    nmlat_bin = n_elements(mlat_bins)
    mlt_binsize = total(mlt_bins[0:1]*[-1,1])


;---Gen ewo.
    ; J is positive for upward current.
    ; For downward current, we want negative value, then flip ewo to positive to let color works better.
    ewo = fltarr(ntime,nmlt_bin)
    mlat_index = lazy_where(mlat_bins, '[]', mlat_range, count=mlat_count)
    if mlat_count eq 0 then return
    if direction eq 'up' then begin
        j_new = j_new>0
        ewo = total(j_new[*,*,mlat_index],3)/mlat_count
    endif else begin
        j_new = j_new<0
        ewo = -total(j_new[*,*,mlat_index],3)/mlat_count
    endelse
;    foreach time, times, ii do begin
;        for jj=0, nmlt_bin-1 do begin
;            tmp = reform(j_new[ii,jj,mlat_index])
;            index = where(tmp lt 0, count)
;            if count eq 0 then continue
;            ewo[ii,jj] = -mean(tmp)
;        endfor
;           ; total -> zrange [0.2.5e5], max -> zrange [0,2.5e5], mean -> zrange [0,1.5e5], total -> zrange [3e5]
;    endforeach
    ystep = 3
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
        ztitle: str_cap(direction)+'ward current (A)', $
        zlog: 0 , $
        zrange: [0,.5e5], $
        yticklen: -0.02, $
        xticklen: -0.02 }


end

mlt_range = [-1,1]*6
time_range = time_double(['2013-06-07/04:00','2013-06-07/07:00'])
;themis_read_upward_current_ewo, time_range, mlt_range=mlt_range
themis_read_j_ver_ewo, time_range, mlt_range=mlt_range

end
