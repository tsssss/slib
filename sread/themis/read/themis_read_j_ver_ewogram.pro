;+
; Read the ewogram for upward or downward currents.
; To replace themis_read_j_ver_ewo
;-

function themis_read_j_ver_ewogram, input_time_range, mlat_range=mlat_range, mlt_range=mlt_range, direction=direction, errmsg=errmsg, get_name=get_name


    if n_elements(mlat_range) eq 0 then mlat_range = [60.,80]
    if n_elements(mlt_range) eq 0 then mlt_range = [-1,1]*6
    if n_elements(direction) eq 0 then direction = 'up'
    ewo_var = 'thg_j_'+direction+'_ewogram'
    if keyword_set(get_name) then return, ewo_var

    mlt_image_var = themis_read_j_ver_mlt_image_uniform(input_time_range, errmsg=errmsg)
    if errmsg ne '' then return, ''
    get_data, mlt_image_var, times, j_new, limits=lim
    
    ntime = n_elements(times)
    mlt_bins = lim.mlt_bins
    mlat_bins = lim.mlat_bins
    nmlt_bin = n_elements(mlt_bins)
    nmlat_bin = n_elements(mlat_bins)
    mlt_binsize = total(mlt_bins[0:1]*[-1,1])


;---Gen ewo.
    ; J is positive for upward current.
    ; For downward current, we want negative value, then flip ewo to positive to let color works better.
    ewo = fltarr(ntime,nmlt_bin)
    mlat_index = where_pro(mlat_bins, '[]', mlat_range, count=mlat_count)
    if mlat_count eq 0 then return, ''
    if direction eq 'up' then begin
        j_new = j_new>0
        ewo = total(j_new[*,*,mlat_index],3)/mlat_count
        ct = 62
    endif else begin
        j_new = j_new<0
        ewo = -total(j_new[*,*,mlat_index],3)/mlat_count
        ct = 49
    endelse
    ystep = 3
    ytickv = make_bins(mlt_range, ystep)
    yticks = n_elements(ytickv)-1
    yminor = ystep
    store_data, ewo_var, times, ewo, mlt_bins
    add_setting, ewo_var, smart=1, dictionary($
        'spec', 1, $
        'no_interp', 1, $
        'ytitle', 'MLT (hr)', $
        'ystyle', 1, $
        'yrange', mlt_range, $
        'ytickv', ytickv, $
        'yticks', yticks, $
        'yminor', yminor, $
        'color_table', ct, $
        'ztitle', 'J '+direction+' (kA)', $
        'zlog', 0 , $
        'zrange', [0,.5e2] )


    return, ewo_var

end


time_range = ['2008-01-19/06:00','2008-01-19/09:00']
mlat_range = [65,80]
var = themis_read_j_ver_ewogram(time_range, mlat_range=mlat_range, direction='up')
end