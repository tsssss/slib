;+
; Calculates KEOgram based on the MLon image.
;-

pro themis_read_mlonimg_keo, mlonimg_var, to=keo_var, $
    errmsg=errmsg, mlon_range=mlon_range

    errmsg = ''
    if tnames(mlonimg_var) eq '' then begin
        errmsg = handle_error('Load MLon image first ...')
        return
    endif

    if n_elements(keo_var) eq 0 then keo_var = mlonimg_var+'_keo'

    get_data, mlonimg_var, times, mlonimgs
    mlat_bins = get_setting(mlonimg_var, 'mlat_bins')
    mlon_bins = get_setting(mlonimg_var, 'mlon_bins')
    if n_elements(mlon_range) eq 2 then begin
        index = where_pro(mlon_bins, mlon_range, count=count)
        if count eq 0 then begin
            errmsg = handle_error('No pixel in given range ...')
            return
        endif
        mlonimgs = mlonimgs[*,index,*]
        mlon_bins = mlon_bins[index]
    endif

    nbin = n_elements(mlon_bins)
    keo = total(mlonimgs,2)/nbin
    store_data, keo_var, times, keo, mlat_bins
    add_setting, keo_var, /smart, {$
        ytitle:'MLat (deg)', $
        unit:'#', $
        short_name:'Photon count', $
        display_type:'spec'}

end

mlonimg_var = 'thg_mlonimg'
keo_var = mlonimg_var+'_keo'
mlon_range = [-110,-80]
themis_read_mlonimg_keo, mlonimg_var, to=keo_var+'_1', mlon_range=mlon_range
tplot, 'thg_mlonimg_keo_?'
end
