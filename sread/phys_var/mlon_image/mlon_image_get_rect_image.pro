;+
; Get the rectangular image from the circular image.
; From themis_read_j_ver_mlon_image_uniform.pro.
;-

function mlon_image_get_rect_image, mlon_image_var, $
    mlon_binsize=mlon_binsize, mlon_range=mlon_range, mlon_bins=mlon_bins, $
    mlat_binsize=mlat_binsize, mlat_range=mlat_range, mlat_bins=mlat_bins, $
    update=update

    old_images = get_var_data(mlon_image_var, times=times, settings=settings)
    pixel_mlon = settings['pixel_mlon']
    pixel_mlat = settings['pixel_mlat']

    image_key = 'rect_image'
    if keyword_set(update) then if settings.haskey(image_key) then settings.remove, image_key
    if settings.haskey(image_key) then begin
        new_images = settings[image_key]
        return, new_images
    endif

    if n_elements(mlat_bins) eq 0 then begin
        if n_elements(mlat_range) ne 2 then mlat_range = minmax(pixel_mlat)
        if n_elements(mlat_binsize) eq 0 then begin
            mlat_binsize = 1.5
        endif
        mlat_bins = make_bins(mlat_range, mlat_binsize, inner=1)
    endif else begin
        mlat_range = minmax(mlat_bins)
        mlat_binsize = mlat_bins[1]-mlat_bins[0]
    endelse
    nmlat_bin = n_elements(mlat_bins)

    if n_elements(mlon_bins) eq 0 then begin
        if n_elements(mlon_range) ne 2 then mlon_range = minmax(pixel_mlon)
        if n_elements(mlon_binsize) eq 0 then begin
            mlon_binsize = 4.
        endif
        mlon_bins = make_bins(mlon_range, mlon_binsize, inner=1)
    endif else begin
        mlon_range = minmax(mlon_bins)
        mlon_binsize = mlon_bins[1]-mlon_bins[0]
    endelse
    nmlon_bin = n_elements(mlon_bins)


;---Map to uniform mlon/mlat bins.
    mlon_bin_min = mlon_range[0]
    mlat_bin_min = mlat_range[0]
    i0_bins = round((pixel_mlon-mlon_bin_min)/mlon_binsize)
    j0_bins = round((pixel_mlat-mlat_bin_min)/mlat_binsize)

    i1_range = [0,nmlon_bin-1]
    j1_range = [0,nmlat_bin-1]

    i_bins = make_bins(i1_range, 1)
    j_bins = make_bins(j1_range, 1)
    ni_bin = nmlon_bin
    nj_bin = nmlat_bin

    index_map_from_old = list()
    index_map_to_new = list()
    for ii=0, nmlon_bin-1 do begin
        the_mlon_range = mlon_bins[ii]+[-1,1]*mlon_binsize*0.5
        for jj=0, nmlat_bin-1 do begin
            the_mlat_range = mlat_bins[jj]+[-1,1]*mlat_binsize*0.5
            index = where($
                pixel_mlon ge the_mlon_range[0] and $
                pixel_mlon lt the_mlon_range[1] and $
                pixel_mlat ge the_mlat_range[0] and $
                pixel_mlat lt the_mlat_range[1], count)
            if count eq 0 then continue
            index_map_from_old.add, index
            index_map_to_new.add, ii+jj*nmlon_bin
        endfor
    endfor

    ntime = n_elements(times)
    new_image_size = [nmlon_bin,nmlat_bin]
    new_images = fltarr([ntime,new_image_size])
    for ii=0,ntime-1 do begin
        old_image = reform(old_images[ii,*,*])
        new_image = fltarr(new_image_size)
        foreach pixel_new, index_map_to_new, pixel_1d do begin
            new_image[pixel_new] = mean(old_image[index_map_from_old[pixel_1d]])
        endforeach
        new_images[ii,*,*] = new_image
    endfor

    ; Store the new images in the settings.
    options, mlon_image_var, mlat_bins=mlat_bins, mlon_bins=mlon_bins
    options, mlon_image_var, image_key, new_images

    return, new_images 

end