;+
; Read current MLT images.
;
; time_range. Time range in unix time.
; mlt_range. MLT range in hr.
; mlat_range. MLat range for calc mltimg, in deg.
;-

pro themis_read_current_mltimg, time_range, mlat_range=mlat_range, $
    mlt_range=mlt_range, $
    varname=mltimg_var


;---Check input.
    if n_elements(mlat_range) eq 0 then mlat_range = [55.,85]
    if n_elements(varname) eq 0 then varname = 'thg_j_ver_mltimg'


;---Load MLon image.
    mlonimg_var = 'thg_j_ver_mlonimg'
    themis_read_current_mlonimg, time_range, varname=mlonimg_var
    get_data, mlonimg_var, times, j_mlonimg
    ntime = n_elements(times)
    mlon_bins = get_setting(mlonimg_var, 'mlon_bins')
    mlat_bins = get_setting(mlonimg_var, 'mlat_bins')
    mlon_range = get_setting(mlonimg_var, 'mlon_range')
    mlat_range = get_setting(mlonimg_var, 'mlat_range')
    nmlon_bin = n_elements(mlon_bins)
    nmlat_bin = n_elements(mlat_bins)
    mlon_binsize = total(mlon_bins[0:1]*[-1,1])
    mlt_binsize = mlon_binsize/15.


;---Preparation.
    if n_elements(mlt_range) ne 2 then mlt_range = [-1,1]*12
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

    store_data, varname, times, j_mltimg, limits={$
        unit: '(A)', $
        image_size: mltimg_size, $
        mlt_range: mlt_range, $
        mlat_range: mlat_range, $
        mlt_bins: mlt_bins, $
        mlat_bins: mlat_bins }

end

time_range = time_double(['2014-08-28/10:10','2014-08-28/10:20'])
time_range = time_double(['2016-10-13/14:00','2016-10-13/14:30'])
themis_read_current_mltimg, time_range
end
