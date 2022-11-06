;+
; Calculates EWOgram based on the MLon image.
;-

pro themis_read_mlonimg_ewo, mlonimg_var, to=ewo_var, $
    errmsg=errmsg, mlat_range=mlat_range

    errmsg = ''
    if tnames(mlonimg_var) eq '' then begin
        errmsg = handle_error('Load MLon image first ...')
        return
    endif

    if n_elements(ewo_var) eq 0 then ewo_var = mlonimg_var+'_ewo'

    get_data, mlonimg_var, times, mlonimgs
    mlat_bins = get_setting(mlonimg_var, 'mlat_bins')
    mlon_bins = get_setting(mlonimg_var, 'mlon_bins')
    if n_elements(mlat_range) eq 2 then begin
        index = lazy_where(mlat_bins, mlat_range, count=count)
        if count eq 0 then begin
            errmsg = handle_error('No pixel in given range ...')
            return
        endif
        mlonimgs = mlonimgs[*,*,index]
        mlat_bins = mlat_bins[index]
    endif

    nbin = n_elements(mlat_bins)
    ewo = total(mlonimgs,3)/nbin
    store_data, ewo_var, times, ewo, mlon_bins
    add_setting, ewo_var, /smart, {$
        ytitle:'MLon (deg)', $
        unit:'#', $
        short_name:'Photon count', $
        display_type:'spec'}

end

mlonimg_var = 'thg_mlonimg'
ewo_var = mlonimg_var+'_ewo'
mlat_range = [63.5,65.5]
themis_read_mlonimg_ewo, mlonimg_var, to=ewo_var+'_1', mlat_range=mlat_range
mlat_range = [67,69]
themis_read_mlonimg_ewo, mlonimg_var, to=ewo_var+'_2', mlat_range=mlat_range
tplot, 'thg_mlonimg_ewo_?'
end
