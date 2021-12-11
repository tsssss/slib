;+
; Read current MLon images.
;
; time_range. Time range in unix time.
; mlon_range=. MLon range for calc mltimg, in deg.
; mlat_range=. MLat range for calc mltimg, in deg.
; varname=. The var name.
;-

pro themis_read_current_mlonimg, time_range, mlat_range=mlat_range, $
    mlon_range=mlon_range, $
    varname=mlonimg_var


;---Check input.
    if n_elements(mlon_range) eq 0 then mlon_range = [-150.,50]
    if n_elements(mlat_range) eq 0 then mlat_range = [55.,85]
    if n_elements(varname) eq 0 then varname = 'thg_j_ver_mlonimg'


;---Read images in glon/glat.
    if n_elements(j_var) eq 0 then j_var = 'thg_j_ver'
    if check_if_update(j_var, time_range) then themis_read_weygand, time_range
    j_orig = get_var_data(j_var, in=time_range, times=times)
    glonbins = get_setting(j_var, 'glonbins')
    glatbins = get_setting(j_var, 'glatbins')
    glonbinsize = total(glonbins[[0,1]]*[-1,1])
    glatbinsize = total(glatbins[[0,1]]*[-1,1])
    nglonbin = n_elements(glonbins)
    nglatbin = n_elements(glatbins)
    old_image_size = [nglonbin,nglatbin]

    ; Get the mlon/mlat for glon/glat bins.
    pixel_glons = fltarr(nglonbin,nglatbin)
    pixel_glats = fltarr(nglonbin,nglatbin)
    for ii=0,nglatbin-1 do pixel_glons[*,ii] = glonbins
    for ii=0,nglonbin-1 do pixel_glats[ii,*] = glatbins
    apexfile = join_path([homedir(),'Projects','idl','spacephys','aurora','image','support','mlatlon.1997a.xdr'])
    geotoapex, pixel_glats, pixel_glons, apexfile, pixel_mlats, pixel_mlons


;---Map to uniform mlon/mlat bins.
    mlon_binsize = 4.
    mlon_bins = make_bins(mlon_range,mlon_binsize)
    nmlon_bin = n_elements(mlon_bins)

    mlat_binsize = 2.
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
        img_old = reform(j_orig[ii,*,*])
        img_new = fltarr(mlonimg_size)
        foreach pixel_new, index_map_to_new, pixel_id do begin
            img_new[pixel_new] = mean(img_old[index_map_from_old[pixel_id]])
        endforeach
        j_new[ii,*,*] = img_new
    endfor

    ; Positive for upward current.
    store_data, varname, times, j_new, limits={$
        unit: '(A)', $
        image_size: mlonimg_size, $
        mlon_range: mlon_range, $
        mlat_range: mlat_range, $
        mlon_bins: mlon_bins, $
        mlat_bins: mlat_bins }

end
