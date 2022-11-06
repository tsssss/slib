;+
; Calculates photon count at certain location based on the MLon image.
;
; mlonimg_var. A string for the MLon image data.
; to=. A string for the photon count.
; mlon_center=. A number for the center MLon in deg.
; mlat_center=. A number for the center MLat in deg.
; dmlon=2. The width of MLon range in deg.
; dmlat=1. The width of MLat range in deg. At 60 deg latitude, 1 deg in mlat is comparable to 2 deg in mlon.
; mlon_range=. Directly set the MLon range in deg.
; mlat_range=. Directly set the MLat range in deg.
; method='mean'. A string sets how to get the photon count per time. Can be 'mean','median','max'.
;-

pro themis_read_mlonimg_photon_count, mlonimg_var, to=photon_count_var, $
    errmsg=errmsg, mlon_center=mlon, mlat_center=mlat, $
    dmlon=dmlon, dmlat=dmlat, mlon_range=mlon_range, mlat_range=mlat_range, $
    method=method

    errmsg = ''
    if tnames(mlonimg_var) eq '' then begin
        errmsg = handle_error('Load MLon image first ...')
        return
    endif

    if n_elements(dmlon) eq 0 then dmlon = 2d
    if n_elements(dmlat) eq 0 then dmlat = 1d
    if n_elements(mlon_range) eq 0 then if n_elements(mlon) ne 0 then mlon_range = mlon[0]+[-1,1]*0.5*dmlon
    if n_elements(mlat_range) eq 0 then if n_elements(mlat) ne 0 then mlat_range = mlat[0]+[-1,1]*0.5*dmlat
    if n_elements(photon_count_var) eq 0 then photon_count_var = mlonimg_var+'_keo'
    if n_elements(method) eq 0 then method = 'mean'

    get_data, mlonimg_var, times, mlonimgs
    mlon_bins = get_setting(mlonimg_var, 'mlon_bins')
    mlat_bins = get_setting(mlonimg_var, 'mlat_bins')
    if n_elements(mlon_range) eq 2 then begin
        index = lazy_where(mlon_bins, mlon_range, count=count)
        if count eq 0 then begin
            errmsg = handle_error('No pixel in given mlon range ...')
            return
        endif
        mlonimgs = mlonimgs[*,index,*]
        mlon_bins = mlon_bins[index]
    endif

    if n_elements(mlat_range) eq 2 then begin
        index = lazy_where(mlat_bins, mlat_range, count=count)
        if count eq 0 then begin
            errmsg = handle_error('No pixel in given mlat range ...')
            return
        endif
        mlonimgs = mlonimgs[*,*,index]
        mlat_bins = mlat_bins[index]
    endif

    nmlon_bin = n_elements(mlon_bins)
    nmlat_bin = n_elements(mlat_bins)
    if nmlon_bin eq 1 and nmlat_bin eq 1 then begin
        photon_count = reform(mlonimgs)
    endif else begin
        ntime = n_elements(times)
        photon_count = fltarr(ntime)
        for ii=0, ntime-1 do begin
            tval = mlonimgs[ii,*,*]
            case method of
                'mean': tval = mean(tval,/nan)
                'median': tval = median(tval)
                'max': tval = max(tval,/nan)
                else: tval = mean(tval,/nan)
            endcase
            photon_count[ii] = tval
        endfor
    endelse

    store_data, photon_count_var, times, photon_count
    add_setting, photon_count_var, /smart, {$
        mlon_range:mlon_range, $
        mlat_range:mlat_range, $
        mlon_center:mean(mlon_range), $
        mlat_center:mean(mlat_range), $
        mlon_width:abs(total(mlon_range*[-1,1])), $
        mlat_width:abs(total(mlat_range*[-1,1])), $
        method:method, $
        ytitle:'Photon count (#)', $
        unit:'#', $
        short_name:'Photon count', $
        display_type:'scalar'}

end

mlonimg_var = 'thg_mlonimg'
photon_count_var = mlonimg_var+'_photon_count'
mlon = -90
mlat = 67
themis_read_mlonimg_photon_count, mlonimg_var, to=photon_count_var+'_1', mlon_center=mlon, mlat_center=mlat
tplot, 'thg_mlonimg_photon_count_?'
end
