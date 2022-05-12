;+
; Read the MLT image at uniform MLT and MLat bins.
; To replace themis_read_current_mltimg.
;-


function themis_read_j_ver_mlt_image_uniform, input_time_range, mlat_range=mlat_range, mlon_range=mlon_range, errmsg=errmsg, get_name=get_name

    errmsg = ''
    time_range = time_double(input_time_range)
    mlt_image_var = 'thg_j_ver_mlt_image_uniform'
    if keyword_set(get_name) then return, mlt_image_var

    if n_elements(mlt_range) eq 0 then mlt_range = [-12.,12]
    if n_elements(mlat_range) eq 0 then mlat_range = [55.,85]

    mlon_image_var = themis_read_j_ver_mlon_image_uniform(time_range, mlat_range=mlat_range, errmsg=errmsg)
    if errmsg ne '' then return, ''
    get_data, mlon_image_var, times, j_mlonimg
    ntime = n_elements(times)
    mlon_bins = get_setting(mlon_image_var, 'mlon_bins')
    mlat_bins = get_setting(mlon_image_var, 'mlat_bins')
    mlon_range = get_setting(mlon_image_var, 'mlon_range')
    mlat_range = get_setting(mlon_image_var, 'mlat_range')
    nmlon_bin = n_elements(mlon_bins)
    nmlat_bin = n_elements(mlat_bins)
    mlon_binsize = total(mlon_bins[0:1]*[-1,1])
    mlt_binsize = mlon_binsize/15.


;---Preparation.
    mlt_bins = make_bins(mlt_range, mlt_binsize)
    nmlt_bin = n_elements(mlt_bins)
    mltimg_size = [nmlt_bin,nmlat_bin]
    ntime = n_elements(times)
    fillval = !values.f_nan
    j_mltimg = fltarr([ntime,mltimg_size])+fillval
    foreach time, times, time_id do begin
        mlonimg = reform(j_mlonimg[time_id,*,*])
        the_mlt = mlon2mlt(mlon_bins, time)
        if total(minmax(the_mlt)*[-1,1]) gt 24 then continue
        the_dmlt = the_mlt[1:-1]-the_mlt[0:-2]
        index = where(abs(the_dmlt) ge 12, count)
        mltimg = fltarr(mltimg_size)
        if count ne 0 then begin
            index_ranges = [[0,index],[index+1,nmlon_bin-1]]
            nmlt_range = n_elements(index_ranges)*0.5
            for ii=0,nmlt_range-1 do begin
                i0 = index_ranges[0,ii]
                i1 = index_ranges[1,ii]
                if i0 eq i1 then continue   ; only 1 bin.
                index = lazy_where(mlt_bins, '[]', minmax(the_mlt[i0:i1]), count=count)
                if count eq 0 then continue
                mltimg[index,*] = sinterpol(mlonimg[i0:i1,*], the_mlt[i0:i1], mlt_bins[index])
            endfor
        endif else begin
            index = lazy_where(mlt_bins, '[]', minmax(the_mlt), count=count)
            if count eq 0 then continue
            mltimg[index,*] = sinterpol(mlonimg, the_mlt, mlt_bins[index])
        endelse
        ;index = lazy_where(mlt_bins,'][', minmax(the_mlt), count=count)
        ;if count ne 0 then mltimg[index,*] = 0
        j_mltimg[time_id,*,*] = mltimg
    endforeach

    store_data, mlt_image_var, times, j_mltimg, limits={$
        unit: '(kA)', $
        image_size: mltimg_size, $
        mlt_range: mlt_range, $
        mlat_range: mlat_range, $
        mlt_bins: mlt_bins, $
        mlat_bins: mlat_bins }
    return, mlt_image_var
    
end