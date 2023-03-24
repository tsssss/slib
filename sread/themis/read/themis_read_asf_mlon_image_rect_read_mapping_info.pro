;+
; Get the info for mapping a raw ASF image to the MLon-MLat plane, which flattens the fish-eye perspective in the raw ASF image.
; To replace themis_read_mlonimg_metadata.
;-

pro themis_read_asf_mlon_image_rect_read_mapping_info_gen_file, input_time_range, $
    site=site, filename=file

;---Get pixel info for ASF image.
    asf_info = themis_asi_read_pixel_info(input_time_range, site=site, errmsg=errmsg)
    ; Get the pixel's center position.
    center_elevs = asf_info.pixel_elev
    center_azims = asf_info.pixel_azim
    center_mlons = asf_info.pixel_mlon
    center_mlats = asf_info.pixel_mlat
    corner_mlons = asf_info.asf_mlon
    corner_mlats = asf_info.asf_mlat
    old_image_size = size(center_elevs, dimensions=1)
    ; Get the size and good pixels of the old image.
    old_uniq_pixels = where(finite(center_elevs) and finite(center_mlons), nold_pixel)
    ;old_uniq_pixels = where(finite(center_elevs) and finite(center_mlons) and center_elevs ge 5, nold_pixel)


;---Get pixel info for the MLat-MLon plane center image.
    mlon_image_rect_info = mlon_image_rect_info()
    new_image_size = mlon_image_rect_info.image_size
    new_mlons = mlon_image_rect_info.pixel_mlon
    new_mlats = mlon_image_rect_info.pixel_mlat


;---Map old image to new image.
    old_pixels = list()
    new_pixels = list()
    crop_xrange = list()
    crop_yrange = list()
    foreach old_index_1d, old_uniq_pixels do begin
        old_index_2d = array_indices(old_image_size, old_index_1d, dimensions=1)
        pixel_mlons = corner_mlons[old_index_2d[0]:old_index_2d[0]+1,old_index_2d[1]:old_index_2d[1]+1]
        pixel_mlats = corner_mlats[old_index_2d[0]:old_index_2d[0]+1,old_index_2d[1]:old_index_2d[1]+1]
        mlon_image_rect_lonlat2xy, mlon=pixel_mlons, mlat=pixel_mlats, xpos=pixel_xpos, ypos=pixel_ypos, info=mlon_image_rect_info
        ; Round works better than floor.
        xpos_range = minmax(round(pixel_xpos))
        ypos_range = minmax(round(pixel_ypos))
        xpos_range >= 0
        ypos_range >= 0
        xpos_range <= (new_image_size[0]-1)      
        ypos_range <= (new_image_size[1]-1)

        foreach xpos, make_bins(xpos_range,1) do begin
            foreach ypos, make_bins(ypos_range,1) do begin
                new_index_1d = ulong64(xpos+ypos*new_image_size[0])
                old_pixels.add, old_index_1d
                new_pixels.add, new_index_1d
            endforeach
        endforeach

        crop_xrange.add, xpos_range
        crop_yrange.add, ypos_range
    endforeach
    old_pixels = old_pixels.toarray()
    new_pixels = new_pixels.toarray()
    new_uniq_pixels = sort_uniq(new_pixels)
    crop_xrange = minmax(crop_xrange.toarray())
    crop_yrange = minmax(crop_yrange.toarray())

;---Map old image to new.
;   new_pixel = new_uniq_pixels[ii]
;   old_pixels = map_old2new[ii]
;   new_image[new_pixel] = median(old_image[old_pixels])
    map_old2new = list()
    map_old2new_count = list()
    foreach new_pixel, new_uniq_pixels do begin
        ; Find no. times current new pixel appears.
        index = where(new_pixels eq new_pixel, count)
        map_old2new.add, old_pixels[index]
        map_old2new_count.add, count
    endforeach
    map_old2new_count = map_old2new_count.toarray()
    map_old2new_uniq = where(map_old2new_count eq 1, complement=map_old2new_mult)

;---Map new image to old.
;   old_pixel = old_uniq_pixels[ii]
;   new_pixels = map_new2old[ii]
;   old_image[old_pixel] = median(new_image[new_pixels])
    map_new2old = list()
    map_new2old_count = list()
    foreach old_pixel, old_uniq_pixels do begin
        ; Find no. times current old pixel appears.
        index = where(old_pixels eq old_pixel, count)
        map_new2old.add, new_pixels[index]
        map_new2old_count.add, count
    endforeach
    map_new2old_count = map_new2old_count.toarray()
    ; one old pixel maps to one new pixel.
    map_new2old_uniq = where(map_new2old_count eq 1, complement=map_new2old_mult)


;---Save the mapping info to tplot.
    prefix = 'thg_'+site+'_mlon_image_rect_'
    ; It selects all non-duplicate pixels in the old/new image.
    store_data, prefix+'old_uniq_pixels', 0, old_uniq_pixels
    store_data, prefix+'new_uniq_pixels', 0, new_uniq_pixels
    ; Old/new image size.
    store_data, prefix+'old_image_size', 0, old_image_size
    store_data, prefix+'new_image_size', 0, new_image_size
    ; Old/new pixels.
    store_data, prefix+'old_pixels', 0, old_pixels
    store_data, prefix+'new_pixels', 0, new_pixels
    ; Map each pixel in old_uniq_pixels to pixels in the new image.
    ; map_old2new_count saves how many pixels in the new image each old pixel maps to.
    store_data, prefix+'map_old2new', 0, map_old2new
    store_data, prefix+'map_old2new_count', 0, map_old2new_count
    ; Map each pixel in new_uniq_pixels to pixels in the old image.
    ; map_new2old_count saves how many pixels in the new image each old pixel maps to.
    store_data, prefix+'map_new2old_count', 0, map_new2old_count
    store_data, prefix+'map_new2old', 0, map_new2old
    ; Split the pixels into two categories: map to 1 pixel or multiple pixels.
    store_data, prefix+'map_old2new_uniq', 0, map_old2new_uniq
    store_data, prefix+'map_old2new_mult', 0, map_old2new_mult
    store_data, prefix+'map_new2old_uniq', 0, map_new2old_uniq
    store_data, prefix+'map_new2old_mult', 0, map_new2old_mult

    ; Pixel range for clipping the new image.
    store_data, prefix+'crop_xrange', 0, crop_xrange
    store_data, prefix+'crop_yrange', 0, crop_yrange

    vars = ['uniq_pixels','image_size','pixel_index']
    save_vars = prefix+['old_'+vars,'new_'+vars, $
        'map_old2new'+['','_count','_uniq','_mult'], $
        'map_new2old'+['','_count','_uniq','_mult'], $
        'crop_'+['x','y']+'range']
    tplot_save, save_vars, filename=file

end


pro themis_read_asf_mlon_image_rect_read_mapping_info, input_time_range, site=site

    compile_opt idl2
    on_error, 0
    errmsg = ''

    prefix = 'thg_'+site+'_mlon_image_rect_'
    vars = ['uniq_pixels','image_size','pixel_index']
    save_vars = prefix+['old_'+vars,'new_'+vars, $
        'map_old2new'+['','_count','_uniq','_mult'], $
        'map_new2old'+['','_count','_uniq','_mult'], $
        'crop_'+['x','y']+'range']
    update = 0
    foreach var, save_vars do begin
        if check_if_update(var) then begin
            update = 1
            break
        endif
    endforeach

    if update eq 0 then return


    ; Prepare file name.
    version = 'v01'
    local_root = join_path([default_local_root(),'sdata','themis'])
    base_name = 'thg_mlon_image_rect_mapping_info_'+site+'_'+version+'.tplot'
    local_dir = join_path([local_root,'thg','mlon_image_rect','mapping_info'])
    file = join_path([local_dir,base_name])
    if file_test(local_dir,/directory) eq 0 then file_mkdir, local_dir
    if keyword_set(renew) then if file_test(file) eq 1 then file_delete, file


    if file_test(file) eq 0 then begin
        lprmsg, 'Generating '+file[0]+' ...'
        themis_read_asf_mlon_image_rect_read_mapping_info_gen_file, input_time_range, site=site, filename=file
    endif

    if file_test(file) eq 0 then begin
        errmsg = handle_error('Cannot find the file: '+file[0]+' ...')
        return
    endif

    tplot_restore, filename=file

end


;mlon_range = list()
;mlat_range = list()
;sites = themis_read_asi_sites()
;foreach site, sites do begin
;    asf_info = themis_asi_read_pixel_info(time_range, site=site)
;    mlon_range.add, minmax(asf_info.pixel_mlon)
;    mlat_range.add, minmax(asf_info.pixel_mlat)
;endforeach
;
;foreach site, sites, site_id do begin
;    print, site+$
;        '    '+strjoin(string(mlon_range[site_id],format='(F6.1)'),',')+$
;        '    '+strjoin(string(mlat_range[site_id],format='(F6.1)'),',')
;endforeach
;stop

time_range = time_double(['2013-05-01/07:00','2013-05-01/08:00'])
site = 'atha'
file = join_path([homedir(),'asf_mlon_image_metadata.tplot'])
themis_read_asf_mlon_image_rect_read_mapping_info_gen_file, time_range, site=site, filename=file
end
