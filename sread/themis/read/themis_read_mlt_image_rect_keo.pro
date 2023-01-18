;+
; Read MLT image rect KEOgram.
;
; time_range. Time range in unix time.
; mlt_range=. MLT range in hr.
; mlat_range=. MLat range for calc KEOgram, in deg.
;-
function themis_read_mlt_image_rect_keo, time_range, mlat_range=mlat_range, $
    mlt_range=mlt_range, mlt_image_var=mlt_image_var, _extra=ex

    errmsg = ''
    retval = ''

    if n_elements(mlat_range) ne 2 then mlat_range = [60.,70]
    if n_elements(mlt_range) ne 2 then mlt_range = [-1,1]*6

;---Settings.
    the_var = 'thg_asf_keo'
    if keyword_set(get_name) then return, the_var


;---Load MLT image.
    if n_elements(mlt_image_var) eq 0 then begin 
        mlt_image_var = themis_read_asf_mlt_image_rect(time_range, varname=mlt_image_var, _extra=ex)
    endif
    get_data, mlt_image_var, times, data, limits=lim
    ntime = n_elements(times)

;---Preparation.
    mlt_bins = lim.mlt_bins
    mlt_index = lazy_where(mlt_bins, '[]', mlt_range, count=nxbin)
    if nxbin eq 0 then begin
        errmsg = 'Invalid MLT range ...'
        return, retval
    endif

    mlat_bins = lim.mlat_bins
    mlat_index = lazy_where(mlat_bins, '[]', mlat_range, count=nybin)
    if nybin eq 0 then begin
        errmsg = 'Invalid MLat range ...'
        return, retval
    endif

    hehe = total(data[*,mlt_index,mlat_index],2)/nxbin
    xbins = mlt_bins[mlt_index]
    ybins = mlat_bins[mlat_index]
    xrange = mlt_range
    yrange = mlat_range
    ytitle = 'MLat (deg)'
    
    if n_elements(ystep) eq 0 then ystep = 2
    ytickv = make_bins(yrange, ystep, inner=1)
    yticks = n_elements(ytickv)-1
    yminor = ystep
    store_data, the_var, times, hehe, ybins, limits={$
        spec: 1, $
        no_interp: 1, $
        mlt_range: mlt_range, $
        mlat_range: mlat_range, $
        ytitle: ytitle, $
        ystyle: 1, $
        yrange: yrange, $
        ytickv: ytickv, $
        yticks: yticks, $
        yminor: yminor, $
        color_table: 49, $
        ztitle: 'Photon count (#)', $
        zlog: 0 , $
        zrange: [1,1000], $
        yticklen: -0.02, $
        xticklen: -0.02 }
    return, the_var

end

mlt_image_var = 'thg_asf_mlt_image_rect'
mlt_range = [-1,-0.8]
mlat_range = [60,67]
time_range = time_double(['2013-05-01/07:25','2013-05-01/07:55'])
keo_var = themis_read_mlt_image_rect_keo(time_range, mlt_range=mlt_range, mlat_range=mlat_range, mlt_image_var=mlt_image_var)

end