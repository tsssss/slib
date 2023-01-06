;+
; Read MLT image EWOgram.
;
; time_range. Time range in unix time.
; mlt_range=. MLT range in hr.
; mlat_range=. MLat range for calc EWOgram, in deg.
;-
function themis_read_mlt_image_ewo, time_range, mlat_range=mlat_range, $
    mlt_range=mlt_range, mlt_image_var=mlt_image_var, _extra=ex

    errmsg = ''
    retval = ''

    if n_elements(mlat_range) eq 0 then mlat_range = [60.,70]
    if n_elements(mlt_range) eq 0 then mlt_range = [-1,1]*6

;---Settings.
    the_var = 'thg_asf_ewo'
    if keyword_set(get_name) then return, the_var


;---Load MLT image.
    if n_elements(mlt_image_var) eq 0 then begin 
        mlt_image_var = themis_read_asf_mlt_image(time_range, varname=mlt_image_var, _extra=ex)
    endif
    get_data, mlt_image_var, times, data, limits=lim
    ntime = n_elements(times)

;---Preparation.
    pixel_mlts = lim.pixel_mlt
    pixel_mlats = lim.pixel_mlat
    pixel_index = where($
        pixel_mlts ge mlt_range[0] and $
        pixel_mlts le mlt_range[1] and $
        pixel_mlats ge mlat_range[0] and $
        pixel_mlats le mlat_range[1], count)
    if count eq 0 then begin
        errmsg = 'No valid pixel ...'
        return, retval
    endif
    ntime = n_elements(times)
    npixel = n_elements(pixel_mlts)
    data = reform(data,[ntime,npixel])
    data = data[*,pixel_index]
    ydata = pixel_mlts[pixel_index]
    xdata = pixel_mlats[pixel_index]
    yrange = mlt_range
    xrange = mlat_range
    ytitle = 'MLT (h)'

    if n_elements(binsize) eq 0 then begin
        image_size = lim.image_size[0]
        image_mlt_range = lim.mlt_range
        binsize = total(image_mlt_range*[-1,1])/(image_size*0.5)
    endif
    ybins = make_bins(yrange,binsize, inner=1)
    nybin = n_elements(ybins)
    
    hehe = fltarr(ntime,nybin)
    for ii=0,nybin-1 do begin
        yr = ybins[ii]+[-1,1]*binsize*0.5
        index = where(ydata ge yr[0] and ydata le yr[1], count)
        if count eq 0 then continue
        hehe[*,ii] = total(data[*,index],2)/count
    endfor

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

mlt_image_var = 'thg_asf_mlt_image'
mlt_range = [-2,0.5]
mlat_range = [64,66]
time_range = time_double(['2013-05-01/07:25','2013-05-01/07:50'])
ewo_var = themis_read_mlt_image_ewo(time_range, mlt_range=mlt_range, mlat_range=mlat_range, mlt_image_var=mlt_image_var)

mlt_range = [-1.1,-0.9]
mlat_range = [60,67]
keo_var = themis_read_mlt_image_keo(time_range, mlt_range=mlt_range, mlat_range=mlat_range, mlt_image_var=mlt_image_var)


vars = [ewo_var,keo_var]
zlim, vars, 1, 1e4
tplot, vars, trange=time_range
end