;+
; Read AST images into the unified format of mlon image.
;-

function themis_ast_read_mlon_image_per_site_map_2d, data, image_size, map_index
    out = fltarr(product(image_size))
    out[map_index] = data
    return, reform(out, image_size)
end

function themis_ast_read_mlon_image_per_site, input_time_range, site=site, $
    errmsg=errmsg, calibration_method=calibration_method, no_crop=no_crop, _extra=ex

    errmsg = ''
    retval = ''
    mlon_image_var = 'thg_ast_'+site+'_mlon_image'
    if keyword_set(get_name) then return, mlon_image_var
    time_range = time_double(input_time_range)
    ;if ~check_if_update(mlon_image_var, time_range) then return, mlon_image_var

    ; Load files.
    datatype = 'ast'
    files = themis_load_asi(time_range, site=site, id='l1%ast', errmsg=errmsg)
    if errmsg ne '' then return, retval

    ; Read vars.
    var_list = list()
    ast_var = 'thg_ast_'+site
    var_list.add, dictionary($
        'in_vars', 'thg_ast_'+site, $
        'out_vars', ast_var, $
        'time_var_name', 'thg_ast_'+site+'_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    ; Reconstruct 2D image.
    pixel_info = themis_asi_read_pixel_info(time_range, site=site, thumbnail=1)
    ; This is the bin # of a mosaic column (c) and row (r).
    binc = pixel_info.ast_binc
    binr = pixel_info.ast_binr
    ; Shrink it to the current field of view.
    binc = binc-min(binc)
    binr = binr-min(binr)
    nc = max(binc)+1
    nr = max(binr)+1
    ; The mapping index to map each pixel to the 2D field of view.
    map_index = binr+binc*nr
    image_size = [nr,nc]

    get_data, ast_var, times, ast_images
    ntime = n_elements(times)

    asi_images = fltarr(ntime,product(image_size))
    test_image = fltarr(max(pixel_info.ast_binc)+1,max(pixel_info.ast_binr)+1)
    foreach time, times, time_id do begin
        ast_image = reform(ast_images[time_id,*,*])
        asi_images[time_id,map_index] = ast_image[*]
;        for ii=0,1023 do test_image[pixel_info.ast_binc[ii],pixel_info.ast_binr[ii]] = ast_image[ii]
;        stop
    endforeach
    asi_images = reform(asi_images,[ntime,image_size])
    pixel_azim = themis_ast_read_mlon_image_per_site_map_2d(pixel_info.ast_azim, image_size, map_index)
    pixel_elev = themis_ast_read_mlon_image_per_site_map_2d(pixel_info.ast_elev, image_size, map_index)
    pixel_mlon = themis_ast_read_mlon_image_per_site_map_2d(total(pixel_info.ast_mlon,1)/4, image_size, map_index)
    pixel_mlat = themis_ast_read_mlon_image_per_site_map_2d(total(pixel_info.ast_mlat,1)/4, image_size, map_index)
    pixel_glon = themis_ast_read_mlon_image_per_site_map_2d(total(pixel_info.ast_glon,1)/4, image_size, map_index)
    pixel_glat = themis_ast_read_mlon_image_per_site_map_2d(total(pixel_info.ast_glat,1)/4, image_size, map_index)
    store_data, ast_var, times, asi_images
    asc_info = themis_asi_read_site_info(site)
    foreach key, asc_info.keys() do begin
        options, ast_var, key, asc_info[key]
    endforeach
    add_setting, ast_var, smart=1, dictionary($
        'display_type', 'image', $
        'image_size', image_size, $
        'unit', 'Count #', $
        'short_name', strupcase(site[0]), $
        'pixel_azim', pixel_azim, $
        'pixel_elev', pixel_elev, $
        'pixel_mlon', pixel_mlon, $
        'pixel_mlat', pixel_mlat, $
        'pixel_glon', pixel_glon, $
        'pixel_glat', pixel_glat )

    ; Add center and edge pixel index (1d).
    pixel_elevs = pixel_info.pixel_elev
    edge_index = where(finite(pixel_elevs,nan=1) or pixel_elevs le 0, complement=center_index)
    options, ast_var, 'edge_index', edge_index
    options, ast_var, 'center_index', center_index


    ; Calibrate brightness.
    

    ; Map to the mlon_image grid.
    get_data, ast_var, times, asi_images, limits=lim
    crop = 1
    if keyword_set(no_crop) then crop = 0
    datatype = 'ast'
    mlon_images = mlon_image_map_old2new(asi_images, site=site, crop=crop, id=datatype)
    pixel_elev = mlon_image_map_old2new(lim.pixel_elev, site=site, crop=crop, id=datatype)
    pixel_azim = mlon_image_map_old2new(lim.pixel_azim, site=site, crop=crop, id=datatype)

    ; The default pixel position.
    mlon_image_info = mlon_image_info()
    image_size = mlon_image_info.image_size
    image_pos = [0d,0]
    pixel_mlon = mlon_image_info.pixel_mlon
    pixel_mlat = mlon_image_info.pixel_mlat
    pixel_xpos = mlon_image_info.pixel_xpos
    pixel_ypos = mlon_image_info.pixel_ypos
    crop_xrange = [0,image_size[0]-1]
    crop_yrange = [0,image_size[1]-1]

    ; Get the MLon image and its pixel positions.
    if crop then begin
        prefix = 'thg_ast_'+site+'_mlon_image_'
        crop_xrange = get_var_data(prefix+'crop_xrange')
        crop_yrange = get_var_data(prefix+'crop_yrange')
        pixel_mlon = pixel_mlon[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        pixel_mlat = pixel_mlat[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        pixel_xpos = pixel_xpos[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        pixel_ypos = pixel_ypos[crop_xrange[0]:crop_xrange[1],crop_yrange[0]:crop_yrange[1]]
        image_pos = [crop_xrange[0],crop_yrange[0]]
        image_size = size(pixel_mlon, dimensions=1)
    endif


    ; Save to the uniform format of asf and ast.
    index = where_pro(times, '[)', time_range, count=ntime)
    if ntime eq 0 then begin
        errmsg = 'Inconsistency ...'
        return, retval
    endif
    times = times[index]
    mlon_images = float(mlon_images[index,*,*])
    store_data, mlon_image_var, times, mlon_images
    add_setting, mlon_image_var, smart=1, dictionary($
        'display_type', 'image', $
        'unit', 'Count #', $
        'image_size', lim.image_size, $     ; image size of the mlon image.
        'image_pos', image_pos, $           ; image's lower left corner in the overall image.
        'site', lim.site, $
        'asc_glon', lim.asc_glon, $
        'asc_glat', lim.asc_glat, $
        'pixel_mlon', pixel_mlon, $
        'pixel_mlat', pixel_mlat, $
        'pixel_elev', pixel_elev, $
        'pixel_azim', pixel_azim, $
        'pixel_xpos', pixel_xpos, $
        'pixel_ypos', pixel_ypos, $
        'crop_xrange', crop_xrange, $
        'crop_yrange', crop_yrange, $
        'requested_time_range', time_range )
    
    return, mlon_image_var

end

time_range = time_double(['2018-10-09/10:00','2018-10-09/12:00'])
site = 'kian'
; ast image mapping is wrong, confirmed using thm_asi_create_mosaic.
time_range = time_double(['2015-02-17/09:40','2015-02-17/10:40'])
site = 'atha'
;thm_asi_create_mosaic, time_string(time_range[1]), thumb=1, show=site, verbose=1
;stop
var = themis_ast_read_mlon_image_per_site(time_range, site=site)
end
