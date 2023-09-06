;+
; Read MLT image in MLT and MLat for a given range. This is useful for a small area.
;
; Adopted from themis_read_mltimg
;-

function themis_asf_read_mlt_image_rect, input_time_range, $
    errmsg=errmsg, get_name=get_name, $
    mlat_range=mlat_range, mlt_range=mlt_range, $
    output=mlt_image_var, calibration_method=calibration_method, _extra=ex

    if n_elements(mlt_image_var) eq 0 then mlt_image_var = 'thg_asf_mlt_image_rect'
    if keyword_set(get_name) then return, mlt_image_var
    time_range = time_double(input_time_range)
    if ~check_if_update(mlt_image_var, time_range) then return, mlt_image_var
    
    
;---Check input.
    if n_elements(mlat_range) eq 0 then mlat_range = [55.,85]

;---Load MLon image.
    mlon_image_var = themis_asf_read_mlon_image_rect(time_range, calibration_method=calibration_method, _extra=ex)
    get_data, mlon_image_var, times, mlon_images, limits=lim
    index = where(finite(mlon_images,nan=1), count)
    if count ne 0 then mlon_images[index] = 0
    
;---Prepare.
    illuminated_index = where(lim.illuminated_pixels eq 1)
    if n_elements(mlat_range) ne 2 then begin
        pixel_mlat = lim.pixel_mlat
        mlat_range = minmax(pixel_mlat[illuminated_index])
    endif
    if n_elements(mlt_range) ne 2 then begin
        pixel_mlon = lim.pixel_mlon
        mlon_range = minmax(pixel_mlon[illuminated_index])

        mlt_range = []
        foreach tmp, mlon_range do begin
            mlt_ranges = mlon2mlt(tmp, times)
            dmlt = mlt_ranges[1:-1]-mlt_ranges[0:-2]
            index = where(dmlt lt 0, count)
            for ii=0, count-1 do mlt_ranges[index[ii]+1:*] += 24
            mlt_range = [mlt_range, mlt_ranges]
        endforeach
        mlt_range = minmax(mlt_range)
    endif

    mlt_binsize = lim.dmlon/15.
    mlt_bins = make_bins(mlt_range, mlt_binsize)
    nmlt_bin = n_elements(mlt_bins)
    mlat_bins = lim.mlat_bins
    mlat_index = where_pro(mlat_bins, '[]', mlat_range, count=nmlat_bin)

;---Convert to MLT image.
    mltimg_size = [nmlt_bin,nmlat_bin]
    ntime = n_elements(times)
    fillval = !values.f_nan
    mlt_images = fltarr([ntime,mltimg_size])+fillval
    mlon_bins = lim.mlon_bins
    foreach time, times, time_id do begin
        the_mlt = mlon2mlt(mlon_bins, time)
        the_dmlt = the_mlt[1:-1]-the_mlt[0:-2]
        index = where(the_dmlt lt 0, count)
        for ii=0, count-1 do the_mlt[index[ii]+1:*] += 24
        index = where(the_mlt ge 12, count)
        if count ne 0 then the_mlt[index] -= 24 ; make it in [12,12]
        mlt_index = where_pro(the_mlt, '[]', minmax(mlt_bins), count=count)
        if count eq 0 then continue
        the_mlt = the_mlt[mlt_index]
        mlon_image = reform(mlon_images[time_id,mlt_index,mlat_index])
        mlt_image = sinterpol(mlon_image, the_mlt, mlt_bins)
        index = where_pro(mlt_bins,'][', minmax(the_mlt), count=count)
        if count ne 0 then mlt_image[index,*] = 0
        mlt_images[time_id,*,*] = mlt_image
    endforeach

    store_data, mlt_image_var, times, mlt_images, limits={$
        requested_time_range: time_range, $
        unit: '(#)', $
        image_size: mltimg_size, $
        mlt_range: mlt_range, $
        mlat_range: mlat_range, $
        mlt_bins: mlt_bins, $
        mlat_bins: mlat_bins[mlat_index] }
        
    return, mlt_image_var
    
end


time_range = time_double(['2015-01-05/00:00','2015-01-05/02:00'])
sites = ['nrsq']
min_elevs = float([2.5])
merge_method = 'max_elev'
calibration_method = 'moon'
mlt_image_var = themis_asf_read_mlt_image_rect(time_range, sites=sites, min_elev=min_elevs, merge_method=merge_method, calibration_method=calibration_method)
stop

mlat_range = [55,70]
mlt_range = [-2,0.5]
sites = ['atha']
time_range = ['2013-05-01/07:25','2013-05-01/07:55']
var = themis_asf_read_mlt_image_rect(time_range, $
    sites=sites, $
    mlat_range=mlat_range, mlt_range=mlt_range)
end