;+
; Read MLT images in circle.
;
; time_range. Time range in unix time.
; min_mlat=. By default is 50 deg.
; save_file=. Boolean, set to save the data to a file.
;-

pro themis_read_mltimg_circ, time_range, min_mlat=min_mlat, sites=sites, save_file=save_file

    if n_elements(min_mlat) eq 0 then min_mlat = 50


    base_name = 'thg_mltimg_circ_'+$
        strjoin(time_string(time_range,tformat='YYYY_MMDD_hhmm_ss'),'_to_')+'_'+$
        strjoin(sort_uniq(sites),'_')+'_v01.tplot'
    file = join_path([default_local_root(),'sdata','themis','thg','mltimg_circ',base_name])
    if file_test(file) eq 1 then begin
        tplot_restore, filename=file
        return
    endif

    mltimg_circ_var = 'thg_mltimg_circ'
    if ~check_if_update(mltimg_circ_var, time_range) then begin
        if keyword_set(save_file) then begin
            path = file_dirname(file)
            if file_test(path,directory=1) eq 0 then file_mkdir, path
            tplot_save, mltimg_circ_var, filename=file
        endif
        return
    endif


;---Load MLon image.
    mlonimg_var = 'thg_mlonimg'
    if check_if_update(mlonimg_var,time_range) then begin
        site_infos = themis_read_mlonimg_default_site_info(sites)
        foreach site_info, site_infos, ii do site_infos[ii].min_elev = 0d
        themis_read_mlonimg, time_range, varname=mlonimg_var, sites=sites, site_infos=site_infos
    endif
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

;---Get MLT range covered by sites.
    mlt_range = []
    foreach tmp, mlon_range do begin
        mlt_ranges = mlon2mlt(tmp, times)
        dmlt = mlt_ranges[1:-1]-mlt_ranges[0:-2]
        index = where(dmlt lt 0, count)
        for ii=0, count-1 do mlt_ranges[index[ii]+1:*] += 24
        mlt_range = [mlt_range, mlt_ranges]
    endforeach
    mlt_range = minmax(mlt_range)
    mlt_bins = make_bins(mlt_range, mlt_binsize)
    nmlt_bin = n_elements(mlt_bins)

;---Get MLT images in MLT and MLat.
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

    if n_elements(mltimg_var) eq 0 then mltimg_var = 'thg_mltimg'
    store_data, mltimg_var, times, mltimgs, limits={$
        unit: '(#)', $
        image_size: mltimg_size, $
        mlt_range: mlt_range, $
        mlat_range: mlat_range, $
        mlt_bins: mlt_bins, $
        mlat_bins: mlat_bins }

;---Convert to the circular version.
    ntime = n_elements(times)
    nmlat_bin = n_elements(mlat_bins)
    npixel = nmlat_bin*2+1
    mltimg_circ = fltarr(ntime,npixel,npixel)

    nmlt_bin = n_elements(mlt_bins)
    nmlat_bin = n_elements(mlat_bins)
    old_image_size = [nmlt_bin,nmlat_bin]
    mlt_2d = mlt_bins # (fltarr(nmlat_bin)+1)
    mlat_2d = (fltarr(nmlt_bin)+1) # mlat_bins
    sphere = 1
    foreach time, times, time_id do begin
        old_image = reform(mltimgs[time_id,*,*])
        get_mlt_image, old_image, mlat_2d, mlt_2d, min_mlat, sphere, mcell=npixel, new_image
        mltimg_circ[time_id,*,*] = new_image
    endforeach
    store_data, mltimg_circ_var, times, mltimg_circ, limits={$
        unit: '(#)', $
        image_size: [npixel,npixel], $
        mlat_range: [min_mlat,90d] }

    if keyword_set(save_file) then tplot_save, mltimg_circ_var, filename=file

end


time_range = time_double(['2007-09-23/09:24','2007-09-23/09:25'])
sites = ['kian','inuv','fsmi','tpas','gill']

time_range = time_double(['2014-08-28/10:10','2014-08-28/10:20'])
sites = ['whit','fsim','atha']

time_range = time_double(['2013-06-07/04:40','2013-06-07/05:10'])
sites = ['pina','kapu','chbg']

time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])
sites = ['kian','mcgr','gako','whit']


themis_read_mltimg_circ, time_range, sites=sites, save_file=1
end
