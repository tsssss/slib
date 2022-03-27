;+
; Read EWOgram.
;-

pro polar_read_ewo, time, errmsg=errmsg, $
    mlat_range=mlat_range, mlt_range=mlt_range

    compile_opt idl2
    on_error, 0
    errmsg = ''

    if n_elements(mlat_range) ne 2 then mlat_range = [60d,70]
    if n_elements(mlt_range) ne 2 then mlt_range = [-1d,1]*6

    polar_read_mlt_image, time, errmsg=errmsg
    if errmsg ne '' then return

    bin_size = 0.25d
    mlt_bins = make_bins([-12d,12],bin_size)
    nmlt_bin = n_elements(mlt_bins)-1
    mlt_vals = mlt_bins[0:nmlt_bin-1]+0.5

    get_data, 'po_mltimg', times, mltimgs, limits=lim

    pixel_mlts = lim.mlt_bins
    pixel_mlats = lim.mlat_bins
    index_list = list()
    index_counts = fltarr(nmlt_bin)
    for ii=0,nmlt_bin-1 do begin
        index_list.add, where($
            pixel_mlats ge mlat_range[0] and $
            pixel_mlats le mlat_range[1] and $
            pixel_mlts ge mlt_bins[ii] and $
            pixel_mlts le mlt_bins[ii+1], count)
        index_counts[ii] = count
    endfor

    ntime = n_elements(times)
    ewo = dblarr(ntime,nmlt_bin)
    for time_id=0,ntime-1 do begin
        mltimg = (reform(mltimgs[time_id,*,*]))[*]
        for ii=0,nmlt_bin-1 do begin
            index = index_list[ii]
            count = index_counts[ii]
            if count eq 0 then continue
            the_ewo = mltimg[index]
            ewo[time_id,ii] = total(the_ewo)
        endfor
    endfor


    ystep = 3
    ytickv = make_bins(mlt_range, ystep)
    yticks = n_elements(ytickv)-1
    yminor = ystep

    store_data, 'po_ewo', times, ewo, mlt_vals, limits={$
        spec: 1, $
        no_interp: 1, $
        ytitle: 'MLT (hr)', $
        ystyle: 1, $
        yrange: mlt_range, $
        ytickv: ytickv, $
        yticks: yticks, $
        yminor: yminor, $
        ztitle: 'UVI (#)', $
        zlog: 0 , $
        zrange: [1e2,3e4], $
        yticklen: -0.02, $
        xticklen: -0.02 }

end

time_range = time_double(['2001-10-22/10:00','2001-10-22/12:00'])
time_range = time_double(['2007-12-18/10:00','2007-12-18/12:30'])
polar_read_ewo, time_range, mlat_range=[50d,80]
end