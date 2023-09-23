;+
; Read the keogram for upward or downward currents.
; To replace themis_read_j_ver_keo
;-

function themis_read_j_ver_keogram, input_time_range, mlat_range=mlat_range, mlt_range=mlt_range, direction=direction, errmsg=errmsg, get_name=get_name


    if n_elements(mlat_range) eq 0 then mlat_range = [60.,80]
    if n_elements(mlt_range) eq 0 then mlt_range = [-1,1]*6
    if n_elements(direction) eq 0 then direction = 'up'
    keo_var = 'thg_j_'+direction+'_keogram'
    if keyword_set(get_name) then return, keo_var

    mlt_image_var = themis_read_j_ver_mlt_image_uniform(input_time_range, errmsg=errmsg)
    if errmsg ne '' then return, ''
    get_data, mlt_image_var, times, j_new, limits=lim
    
    ntime = n_elements(times)
    mlt_bins = lim.mlt_bins
    mlat_bins = lim.mlat_bins
    nmlt_bin = n_elements(mlt_bins)
    nmlat_bin = n_elements(mlat_bins)
    mlt_binsize = total(mlt_bins[0:1]*[-1,1])


;---Gen keo.
    ; J is positive for upward current.
    ; For downward current, we want negative value, then flip keo to positive to let color works better.
    keo = fltarr(ntime,nmlat_bin)
    mlt_index = where_pro(mlt_bins, '[]', mlt_range, count=mlt_count)
    if mlt_count eq 0 then return, ''
    if direction eq 'up' then begin
        j_new = j_new>0
        keo = total(j_new[*,mlt_index,*],2)/mlt_count
    endif else begin
        j_new = j_new<0
        keo = -total(j_new[*,mlt_index,*],2)/mlt_count
    endelse
    ystep = 5
    ytickv = make_bins(mlat_range, ystep)
    yticks = n_elements(ytickv)-1
    yminor = ystep
    store_data, keo_var, times, keo, mlat_bins
    add_setting, keo_var, smart=1, dictionary($
        'spec', 1, $
        'no_interp', 1, $
        'ytitle', 'MLat (deg)', $
        'ystyle', 1, $
        'yrange', mlat_range, $
        'ytickv', ytickv, $
        'yticks', yticks, $
        'yminor', yminor, $
        'color_table', 62, $
        'ztitle', 'J '+direction+' (kA)', $
        'zlog', 0 , $
        'zrange', [0,40] )

end


time_range = ['2008-01-19/06:00','2008-01-19/09:00']
mlat_range = [65,80]
var = themis_read_j_ver_keogram(time_range, mlat_range=mlat_range, direction='up')
end