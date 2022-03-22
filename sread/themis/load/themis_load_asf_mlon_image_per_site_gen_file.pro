;+
; Load calibrated mlon image.
;-

pro themis_load_asf_mlon_image_per_site_gen_file, time, site=site, filename=file, errmsg=errmsg

;---Init settings.
    errmsg = ''
    cadence = 3600d
    start_time = time_double(time[0])
    time_range = start_time-(start_time mod cadence)+[0,cadence]

;---Load MLon image and calibrate the count.
;   Calibration needs a longer time range to be perfect.
    pad_time = 1800d*0.5
    data_time_range = time_range+[-1,1]*pad_time
    ; Read asf to test data_time_range.
    themis_read_asf, data_time_range, site=site, errmsg=errmsg
    if errmsg ne '' then return
    asf_var = 'thg_'+site+'_asf'
    get_data, asf_var, times
    time_step = 3d
    min_time = min(times)
    max_time = max(times)
    ; This means data starts in the current hour.
    if min_time gt time_range[0] then data_time_range = time_range+[-1,2]*pad_time
    ; This means data ends in the current hour.
    if max_time lt time_range[1] then data_time_range = time_range+[-2,1]*pad_time
    
    themis_calc_asf_mlon_image_per_site, data_time_range, site=site, errmsg=errmsg
    if errmsg ne '' then return
    mlon_image_var = 'thg_'+site+'_mlon_image'
    get_data, mlon_image_var, times
    cal_mlon_image_var = mlon_image_var+'_norm'
    themis_asi_cal_brightness, mlon_image_var, newname=cal_mlon_image_var


    get_data, cal_mlon_image_var, times, mlon_images, limits=lim
    index = lazy_where(times, '[)', time_range, count=ntime)
    if ntime eq 0 then begin
        errmsg = 'Inconsistency ...'
        return
    endif
    times = times[index]
    mlon_images = float(mlon_images[index,*,*])
    image_size = lim.image_size
    image_pos = lim.image_pos
    crop_xrange = lim.crop_xrange
    crop_yrange = lim.crop_yrange


;---Save data.
    if file_test(file) eq 1 then file_delete, file
    cdf_touch, file

    gatts = dictionary($
        'text', 'THEMIS ASI full-res images converted to MLon-MLat plane and background removed. Generated by Sheng Tian, ts0110@atmos.ucla.edu' )
    cdf_save_setting, gatts, filename=file

    time_var = 'time'
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', 'sec', $
        'var_notes', 'unix time' )
    cdf_save_var, time_var, filename=file, value=times
    cdf_save_setting, vatts, varname=time_var, filename=file

    vatts = dictionary($
        'var_type', 'data', $
        'unit', '#', $
        'var_notes', 'background removed images in digital count', $
        'depend_0', time_var )
    cdf_save_var, mlon_image_var, filename=file, value=mlon_images
    cdf_save_setting, vatts, varname=mlon_image_var, filename=file

    var = 'pixel_mlon'
    val = float(lim.pixel_mlon)
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', 'deg', $
        'var_notes', 'mlon of each pixel' )
    cdf_save_var, var, filename=file, value=val, save_as_one=1
    cdf_save_setting, vatts, varname=var, filename=file

    var = 'pixel_mlat'
    val = float(lim.pixel_mlat)
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', 'deg', $
        'var_notes', 'mlat of each pixel' )
    cdf_save_var, var, filename=file, value=val, save_as_one=1
    cdf_save_setting, vatts, varname=var, filename=file

    var = 'pixel_elev'
    val = float(lim.pixel_elev)
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', 'deg', $
        'var_notes', 'elevation of each pixel' )
    cdf_save_var, var, filename=file, value=val, save_as_one=1
    cdf_save_setting, vatts, varname=var, filename=file

    var = 'pixel_xpos'
    val = float(lim.pixel_xpos)
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', '#', $
        'var_notes', 'xpos of each pixel in overall image' )
    cdf_save_var, var, filename=file, value=val, save_as_one=1
    cdf_save_setting, vatts, varname=var, filename=file

    var = 'pixel_ypos'
    val = float(lim.pixel_ypos)
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', '#', $
        'var_notes', 'ypos of each pixel in overall image' )
    cdf_save_var, var, filename=file, value=val, save_as_one=1
    cdf_save_setting, vatts, varname=var, filename=file

    var = 'image_pos'
    val = image_pos
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', '#', $
        'var_notes', '[x,y]pos of lower left corner in overall image' )
    cdf_save_var, var, filename=file, value=val, save_as_one=1
    cdf_save_setting, vatts, varname=var, filename=file

    var = 'image_size'
    val = image_size
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', '#', $
        'var_notes', '[x,y]size of the image' )
    cdf_save_var, var, filename=file, value=val, save_as_one=1
    cdf_save_setting, vatts, varname=var, filename=file

    var = 'crop_xrange'
    val = crop_xrange
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', '#', $
        'var_notes', 'xrange in the overall image' )
    cdf_save_var, var, filename=file, value=val, save_as_one=1
    cdf_save_setting, vatts, varname=var, filename=file

    var = 'crop_yrange'
    val = crop_yrange
    vatts = dictionary($
        'var_type', 'metadata', $
        'unit', '#', $
        'var_notes', 'yrange in the overall image' )
    cdf_save_var, var, filename=file, value=val, save_as_one=1
    cdf_save_setting, vatts, varname=var, filename=file


end


time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])
site = 'fykn'

; Only a little data.
time_range = time_double(['2016-11-24/13:00','2016-11-24/14:00'])
site = 'tpas'

file = join_path([homedir(),'test','test_mlon_image.cdf'])
themis_load_asf_mlon_image_per_site_gen_file, time_range, site=site, filename=file, errmsg=errmsg
end