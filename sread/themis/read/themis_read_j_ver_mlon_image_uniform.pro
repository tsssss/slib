;+
; Read the MLon image at uniform MLon and MLat bins.
; To replace themis_read_current_mlonimg.
;-

function themis_read_j_ver_mlon_image_uniform, input_time_range, mlat_range=mlat_range, mlon_range=mlon_range, errmsg=errmsg, get_name=get_name

    errmsg = ''
    time_range = time_double(input_time_range)
    mlon_image_var = 'thg_j_ver_mlon_image_uniform'
    if keyword_set(get_name) then return, mlon_image_var

    if n_elements(mlon_range) eq 0 then mlon_range = [-150.,50]
    if n_elements(mlat_range) eq 0 then mlat_range = [55.,85]

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
    old_image_size = [nglon_bin,nglat_bin]

    ; Get the mlon/mlat for glon/glat bins.
    pixel_glons = (fltarr(nglat_bin)+1) ## glon_bins
    pixel_glats = glat_bins ## (fltarr(nglon_bin)+1)
    geo2mag2d, times, glon=pixel_glons, glat=pixel_glats, mlon=pixel_mlons, mlat=pixel_mlats, use_apex=1

;---Map to uniform mlon/mlat bins.
    mlon_binsize = 4.
    mlon_bins = make_bins(mlon_range,mlon_binsize)
    nmlon_bin = n_elements(mlon_bins)

    mlat_binsize = 1.5
    mlat_bins = make_bins(mlat_range,mlat_binsize)
    nmlat_bin = n_elements(mlat_bins)
    mlonimg_size = [nmlon_bin,nmlat_bin]

    mlon_bin_min = mlon_range[0]
    mlat_bin_min = mlat_range[0]
    i0_bins = round((pixel_mlons-mlon_bin_min)/mlon_binsize)
    j0_bins = round((pixel_mlats-mlat_bin_min)/mlat_binsize)

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
                pixel_mlons ge the_mlon_range[0] and $
                pixel_mlons lt the_mlon_range[1] and $
                pixel_mlats ge the_mlat_range[0] and $
                pixel_mlats lt the_mlat_range[1], count)
            if count eq 0 then continue
            index_map_from_old.add, index
            index_map_to_new.add, ii+jj*nmlon_bin
        endfor
    endfor

    ntime = n_elements(times)
    j_new = fltarr([ntime,mlonimg_size])
    for ii=0,ntime-1 do begin
        img_old = reform(old_images[ii,*,*])
        img_new = fltarr(mlonimg_size)
        foreach pixel_new, index_map_to_new, pixel_id do begin
            img_new[pixel_new] = mean(img_old[index_map_from_old[pixel_id]])
        endforeach
        j_new[ii,*,*] = img_new
    endfor

    ; Positive for upward current.
    store_data, mlon_image_var, times, j_new*1e-3, limits={$
        unit: '(kA)', $
        image_size: mlonimg_size, $
        mlon_range: mlon_range, $
        mlat_range: mlat_range, $
        mlon_bins: mlon_bins, $
        mlat_bins: mlat_bins }
    
    return, mlon_image_var

end