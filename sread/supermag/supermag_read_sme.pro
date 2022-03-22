;+
; Read supermag SME indices.
;-


pro supermag_read_sme, input_time_range, errmsg=errmsg, mlt_limit=mlt_limit

    compile_opt idl2

;---Load omni AE as a comparison.
    time_range = time_double(input_time_range)
    omni_read_index, time_range

;---Prepare to use supermag api.
    supermag_api


;---MSE as a function of MLT.
    sme2d_var = 'supermag_sme2d'
    s = supermaggetindicesarray(time_range, $
        times, regionalsme=sme2d, $
        regionalmlat=mlat, regionalmlt=mlt, stid=stid )
    mlts = smkarthm(0d,23,1, 'dx')+0.5  ; 0.5 h to move data to center.
    ; Make midnight to be the center.
    if n_elements(mlt_limit) eq 0 then mlt_limit = 12
    if mlt_limit ge 24 then mlt_limit -= 12
    if mlt_limit le 0 then mlt_limit += 12
    mlts -= mlt_limit
    sme2d = shift(sme2d,0,mlt_limit)

    store_data, sme2d_var, $
        times, sme2d, mlts, $
        limits={ytitle:'MLT (h)', spec:1, no_interp:1, $
        yrange:minmax(mlts), ystyle:1, $
        xticklen:-0.02, yticklen:-0.02, $
        ztitle:'SME (nT)', color_table:49 }

;---MSE as a function of time.
    sme_var = 'supermag_sme'
    s = supermaggetindicesarray(time_range, $
        times, sme=sme )

    store_data, sme_var, times, sme, $
        limits={ytitle:'(nT)', $
        xticklen:-0.02, yticklen:-0.02 }

    ae = get_var_data('ae', at=times)
    store_data, sme_var, times, [[sme],[ae]], $
        limits={ytitle:'(nT)', $
        labels:['SME','AE'], colors:sgcolor(['red','black']), $
        xticklen:-0.02, yticklen:-0.02, labflag:-1 }

end
