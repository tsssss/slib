;+
; Read MLT images.
;
; time_range. Time range in unix time.
; mlt_range. MLT range in hr.
; mlat_range. MLat range for calc mltimg, in deg.
;-

pro themis_read_mltimg, time_range, mlat_range=mlat_range, $
    mlt_range=mlt_range, $
    varname=mltimg_var, _extra=ex


;---Check input.
    if n_elements(mlat_range) eq 0 then mlat_range = [55.,85]
    if n_elements(varname) eq 0 then varname = 'thg_mltimg'


;---Load MLon image.
    mlonimg_var = 'thg_mlonimg'
    if check_if_update(mlonimg_var,time_range) then $
        themis_read_mlonimg, time_range, varname=mlonimg_var, _extra=ex
    get_data, mlonimg_var, times, mlonimgs
    ntime = n_elements(times)
    mlon_bins = get_setting(mlonimg_var, 'mlon_bins')
    mlat_bins = get_setting(mlonimg_var, 'mlat_bins')
    mlon_range = minmax(mlon_bins)
    mlat_range = minmax(mlat_bins)
    nmlon_bin = n_elements(mlon_bins)
    nmlat_bin = n_elements(mlat_bins)
    mlon_binsize = total(mlon_bins[0:1]*[-1,1])
    mlt_binsize = mlon_binsize/15.


;---Preparation.
    if n_elements(mlt_range) ne 2 then begin
        mlt_range = []
        foreach tmp, mlon_range do begin
            mlt_ranges = mlon2mlt(tmp, times)
            dmlt = mlt_ranges[1:-1]-mlt_ranges[0:-2]
            index = where(dmlt lt 0, count)
            for ii=0, count-1 do mlt_ranges[index[ii]+1:*] += 24
            mlt_range = [mlt_range, mlt_ranges]
        endforeach
        mlt_range = minmax(mlt_range)
    endif
    mlt_bins = make_bins(mlt_range, mlt_binsize)
    nmlt_bin = n_elements(mlt_bins)
    mltimg_size = [nmlt_bin,nmlat_bin]
    ntime = n_elements(times)
    fillval = !values.f_nan
    mltimgs = fltarr([ntime,mltimg_size])+fillval
    foreach time, times, time_id do begin
        the_mlt = mlon2mlt(mlon_bins, time)
        the_dmlt = the_mlt[1:-1]-the_mlt[0:-2]
        index = where(the_dmlt lt 0, count)
        for ii=0, count-1 do the_mlt[index[ii]+1:*] += 24
        mlonimg = reform(mlonimgs[time_id,*,*])
        mltimg = sinterpol(mlonimg, the_mlt, mlt_bins)
        index = lazy_where(mlt_bins,'][', minmax(the_mlt), count=count)
        if count ne 0 then mltimg[index,*] = 0
        mltimgs[time_id,*,*] = mltimg
    endforeach

    store_data, varname, times, mltimgs, limits={$
        unit: '(#)', $
        image_size: mltimg_size, $
        mlt_range: mlt_range, $
        mlat_range: mlat_range, $
        mlt_bins: mlt_bins, $
        mlat_bins: mlat_bins }

end



time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])
sites = ['mcgr','gako','whit']
min_elevs = [5,5,5]
mlat_range = [55,70]
mlon_range = !null
merge_method = 'merge_elev'

site_infos = themis_read_mlonimg_default_site_info(sites)
foreach min_elev, min_elevs, ii do site_infos[ii].min_elev = min_elev

themis_read_mltimg, time_range, sites=sites, site_infos=site_infos, $
    mlon_range=mlon_range, mlat_range=mlat_range, merge_method=merge_method

end
