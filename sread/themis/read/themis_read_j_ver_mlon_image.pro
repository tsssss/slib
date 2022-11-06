;+
; Read vertical currents.
;-

function themis_read_j_ver_mlon_image, input_time_range, errmsg=errmsg, get_name=get_name

    errmsg = ''
    time_range = time_double(input_time_range)
    mlon_image_var = 'thg_j_ver_mlon_image'
    if keyword_set(get_name) then return, mlon_image_var

    datatype = 'j_ver'
    j_var = themis_read_weygand_j(time_range, id=datatype)
    get_data, j_var, times, old_images, limits=lim
    dims = size(old_images, dimensions=1)
    ndim = n_elements(dims)
    if (ndim ne 2) and (ndim ne 3) then begin
        errmsg = 'Data in invalid dimensions ...'
        return, ''
    endif
    if dims[ndim-1] eq 2 then old_images = reform(old_images,[1,dims])

    ; Convert center to edge.
    glon_bins = lim.glon_bins
    glat_bins = lim.glat_bins
    nglon_bin = n_elements(glon_bins)
    nglat_bin = n_elements(glat_bins)
    glon_bin_size = mean(glon_bins[1:-1]-glon_bins[0:-2])
    glat_bin_size = mean(glat_bins[1:-1]-glat_bins[0:-2])
    corner_glon_bins = [glon_bins[0]-glon_bin_size,glon_bins]+glon_bin_size*0.5
    corner_glat_bins = [glat_bins[0]-glat_bin_size,glat_bins]+glat_bin_size*0.5

    ; Mesh 1d bins to 2d bins.
    corner_glons = (fltarr(nglat_bin+1)+1) ## corner_glon_bins
    corner_glats = corner_glat_bins ## (fltarr(nglon_bin+1)+1)    
    geo2mag2d, times, glon=corner_glons, glat=corner_glats, $
        mlon=corner_mlons, mlat=corner_mlats, use_apex=1
    
    if n_elements(half_size) eq 0 then begin
        mlat_range = [50d,90]
        half_size = floor(total(mlat_range*[-1,1])/glat_bin_size)
    endif

    mlon_image_info = mlon_image_info(half_size)
    pixel_mlon = mlon_image_info.pixel_mlon
    pixel_mlat = mlon_image_info.pixel_mlat

;---Map old image to new image.
    old_pixels = list()
    new_pixels = list()
    crop_xrange = list()
    crop_yrange = list()
    old_uniq_pixels = findgen(nglon_bin*nglat_bin)
    old_image_size = [nglon_bin,nglat_bin]
    new_image_size = mlon_image_info.image_size
    foreach old_index_1d, old_uniq_pixels do begin
        old_index_2d = array_indices(old_image_size, old_index_1d, dimensions=1)
        pixel_mlons = corner_mlons[old_index_2d[0]:old_index_2d[0]+1,old_index_2d[1]:old_index_2d[1]+1]
        pixel_mlats = corner_mlats[old_index_2d[0]:old_index_2d[0]+1,old_index_2d[1]:old_index_2d[1]+1]
        mlon_image_lonlat2xy, mlon=pixel_mlons, mlat=pixel_mlats, xpos=pixel_xpos, ypos=pixel_ypos, info=mlon_image_info

        ; Round works better than floor.
        xpos_range = minmax(round(pixel_xpos))
        ypos_range = minmax(round(pixel_ypos))

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
    prefix2 = 'thg_'+datatype+'_mlon_image_'
    ; It selects all non-duplicate pixels in the old/new image.
    store_data, prefix2+'old_uniq_pixels', 0, old_uniq_pixels
    store_data, prefix2+'new_uniq_pixels', 0, new_uniq_pixels
    ; Old/new image size.
    store_data, prefix2+'old_image_size', 0, old_image_size
    store_data, prefix2+'new_image_size', 0, new_image_size
    ; Old/new pixels.
    store_data, prefix2+'old_pixels', 0, old_pixels
    store_data, prefix2+'new_pixels', 0, new_pixels
    ; Map each pixel in old_uniq_pixels to pixels in the new image.
    ; map_old2new_count saves how many pixels in the new image each old pixel maps to.
    store_data, prefix2+'map_old2new', 0, map_old2new
    store_data, prefix2+'map_old2new_count', 0, map_old2new_count
    ; Map each pixel in new_uniq_pixels to pixels in the old image.
    ; map_new2old_count saves how many pixels in the new image each old pixel maps to.
    store_data, prefix2+'map_new2old_count', 0, map_new2old_count
    store_data, prefix2+'map_new2old', 0, map_new2old
    ; Split the pixels into two categories: map to 1 pixel or multiple pixels.
    store_data, prefix2+'map_old2new_uniq', 0, map_old2new_uniq
    store_data, prefix2+'map_old2new_mult', 0, map_old2new_mult
    store_data, prefix2+'map_new2old_uniq', 0, map_new2old_uniq
    store_data, prefix2+'map_new2old_mult', 0, map_new2old_mult

    ; Pixel range for clipping the new image.
    store_data, prefix2+'crop_xrange', 0, crop_xrange
    store_data, prefix2+'crop_yrange', 0, crop_yrange

    vars = ['uniq_pixels','image_size','pixel_index']
    save_vars = prefix2+['old_'+vars,'new_'+vars, $
        'map_old2new'+['','_count','_uniq','_mult'], $
        'map_new2old'+['','_count','_uniq','_mult'], $
        'crop_'+['x','y']+'range']
;    tplot_save, save_vars, filename=file



;---Map original image to mlon image.
    old_image_size = get_var_data(prefix2+'old_image_size')
    old_1d_size = product(old_image_size)
    nframe = n_elements(old_images)/old_1d_size

    reform_old_image = 1
    if nframe gt 1 then reform_old_image = 0
    if size(old_images, n_dimensions=1) eq 3 then reform_old_image = 0
    if reform_old_image then begin
        old_dims = size(old_images, dimensions=1)
        old_images = reform(old_images, [nframe,old_image_size])
    endif

    new_image_size = get_var_data(prefix2+'new_image_size')
    new_1d_size = product(new_image_size)
    new_images = fltarr([nframe,new_image_size])

    new_uniq_pixels = get_var_data(prefix2+'new_uniq_pixels')
    map_old2new = get_var_data(prefix2+'map_old2new')
    map_old2new_uniq = get_var_data(prefix2+'map_old2new_uniq')
    map_old2new_mult = get_var_data(prefix2+'map_old2new_mult')

    ; one new -> one old.
    old_one = map_old2new[map_old2new_uniq].toarray()
    new_one = new_uniq_pixels[map_old2new_uniq]
    ; one new -> mult old.
    old_mult = map_old2new[map_old2new_mult]
    new_mult = new_uniq_pixels[map_old2new_mult]

    for time_id=0,nframe-1 do begin
        old_image = reform(old_images[time_id,*,*],old_1d_size)
        new_image = fltarr(new_1d_size)
        new_image[new_one] = old_image[old_one]
        foreach old_id, old_mult, new_id do begin
            val = old_image[old_id]
            val = median(val)
;            val = mean(val, nan=1)
            new_image[new_mult[new_id]] = val
        endforeach
        new_images[time_id,*,*] = reform(new_image, new_image_size)
    endfor


    store_data, mlon_image_var, times, new_images*1e-3
    add_setting, mlon_image_var, smart=1, dictionary($
        'display_type', 'image', $
        'unit', '(kA)', $
        'image_size', new_image_size, $ ; image size of the mlon image.
        'pixel_mlon', pixel_mlon, $
        'pixel_mlat', pixel_mlat, $
        'pixel_xpos', mlon_image_info.pixel_xpos, $
        'pixel_ypos', mlon_image_info.pixel_ypos, $
        'crop_xrange', crop_xrange, $
        'crop_yrange', crop_yrange )

    return, mlon_image_var
end


time_range = time_double(['2008-01-19/06:00','2008-01-19/09:00'])
var = themis_read_j_ver_mlon_image(time_range)
end