;+
; Read AST raw image for one given site.
;
; input_time_range. Input time in string or unix time.
; site=. Required input, a string for site.
;-
pro themis_read_ast, input_time_range, site=site, errmsg=errmsg

    time_range = time_double(input_time_range)
    files = themis_load_asi(time_range, site=site, id='l1%ast', errmsg=errmsg)
    if errmsg ne '' then return

    var_list = list()

    ast_var = 'thg_'+site+'_ast'
    var_list.add, dictionary($
        'in_vars', 'thg_ast_'+site, $
        'out_vars', ast_var, $
        'time_var_name', 'thg_ast_'+site+'_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return


;---Reconstruct the thumbnail image.
    pixel_info = themis_read_asi_pixel_info(time_range, site=site, thumbnail=1)
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

    get_data, ast_var, times, imgs
    ntime = n_elements(times)

    imgs_ast = fltarr(ntime,product(image_size))
    foreach time, times, time_id do begin
        img = reform(imgs[time_id,*,*])
        imgs_ast[time_id,map_index] = img[*]
    endforeach
    imgs_ast = reform(imgs_ast,[ntime,image_size])


;;---Reconstruct the thumbnail image. This is more straightforward but slower.
;    info = themis_read_asi_pixel_info(time_range, site=site, thumbnail=1)
;    ; This is the bin # of a mosaic column (c) and row (r).
;    binc = info.ast_binc
;    binr = info.ast_binr
;    nc = n_elements(binc)
;    nr = n_elements(binr)
;    ; The mapping index to map each pixel to the 2D field of view.
;    map_index = binr+binc*nr
;    image_size = [nr,nc]
;
;    get_data, ast_var, times, imgs
;    ntime = n_elements(times)
;
;    imgs_ast = fltarr(ntime,product(image_size))
;    foreach time, times, time_id do begin
;        img = reform(imgs[time_id,*,*])
;        imgs_ast[time_id,map_index] = img[*]
;    endforeach
;    imgs_ast = reform(imgs_ast,[ntime,image_size])
;
;    ; Crop image.
;    crange = minmax(binc)
;    rrange = minmax(binr)
;    imgs_ast = imgs_ast[*,rrange[0]:rrange[1],crange[0]:crange[1]]

    ; Save the raw image.
    store_data, ast_var, times, imgs_ast
    add_setting, ast_var, /smart, {$
        display_type: 'image', $
        image_size: image_size, $
        unit: 'Count', $
        short_name: strupcase(site[0])}
        
    ; Read pixel and site info.
    pixel_info = themis_read_asi_pixel_info(time_range, site=site, id='ast')
    foreach key, pixel_info.keys() do begin
        options, ast_var, key, pixel_info[key]
    endforeach
    asc_info = themis_read_asi_site_info(site)
    foreach key, asc_info.keys() do begin
        options, ast_var, key, asc_info[key]
    endforeach
end

time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
site = 'gako'

time_range = time_double(['2008-01-17/03:00','2008-01-17/04:00'])   ; moon, at 40,140
site = 'kuuj'

time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon, at 160,70 at t=0.
site = 'inuv'

time_range = time_double(['2007-09-23/09:00','2007-09-23/10:00'])  ; Doesn't work for ast.
site = 'gill'


themis_read_ast, time_range, site=site
ast_var = 'thg_'+site+'_ast'
get_data, ast_var, times, imgs, limits=lim
stop
foreach time, times, time_id do sgtv, bytscl(reform(imgs[time_id,*,*]),max=65535,min=0), ct=49

end
