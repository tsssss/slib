;+
; Read upward current EWOgram.
;
; time_range. Time range in unix time.
; mlt_range. MLT range in hr.
; mlat_range. MLat range for calc EWOgram, in deg.
; mlon_range. MLon range for calc EWOgram, in deg.
;-
pro themis_read_upward_current_ewo, time_range, mlat_range=mlat_range, $
    mlt_range=mlt_range, mlon_range=mlon_range

    if n_elements(mlon_range) eq 0 then mlon_range = [-100.,50]
    if n_elements(mlat_range) eq 0 then mlat_range = [60.,70]
    if n_elements(mlt_range) eq 0 then mlt_range = [-1,1]*6


;---Settings.
    mlon_binsize = 4.
    mlat_binsize = 2.
    mlt_binsize = mlon_binsize/15.
    j_var = 'thg_j_ver'
    ewo_var = 'thg_j_ver_ewo'
    mlt_ewo_var = 'thg_j_ver_mlt_ewo'


;---Preparation.
    mlat_bins = make_bins(mlat_range,mlat_binsize)
    mlon_bins = make_bins(mlon_range,mlon_binsize)
    nmlon_bin = n_elements(mlon_bins)
    nmlat_bin = n_elements(mlat_bins)
    new_image_size = [nmlon_bin,nmlat_bin]

;---Convert images from glon/glat to mlon/mlat.
    if check_if_update(j_var, time_range) then themis_read_weygand, time_range
    get_data, j_var, times, j_orig
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

    ; Map to uniform mlon/mlat bins.
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
    j_new = fltarr([ntime,new_image_size])
    for ii=0,ntime-1 do begin
        img_old = reform(j_orig[ii,*,*])
        img_new = fltarr(new_image_size)
        foreach pixel_new, index_map_to_new, pixel_id do begin
            img_new[pixel_new] = mean(img_old[index_map_from_old[pixel_id]])
        endforeach
        j_new[ii,*,*] = img_new
    endfor

    ; Get EWOgram in terms of mlon.
    mlat_index = lazy_where(mlat_bins, '[]', mlat_range)
    ewo = total(-j_new[*,*,mlat_index], 3)/n_elements(mlat_index)
    ewo = fltarr(ntime,nmlon_bin)
    foreach time, times, ii do begin
        foreach mlon, mlon_bins, jj do begin
            tmp = reform(-j_new[ii,jj,mlat_index])
            index = where(tmp lt 0, count)
            if count ne 0 then tmp[index] = 0
            ewo[ii,jj] = mean(tmp)   ; total -> zrange [0.2.5e5], max -> zrange [0,2.5e5], mean -> zrange [0,1.5e5], total -> zrange [3e5]
        endforeach
    endforeach
    store_data, ewo_var, times, ewo, mlon_bins, limits={$
        spec: 1, $
        no_interp: 1, $
        ytitle: 'MLon (deg)', $
        ystyle: 1, $
        yrange: reverse(minmax(mlon_bins)), $
        ztitle: 'Upward current (A)', $
        zlog: 0 , $
        zrange: [0,.5e5], $
        yticklen: -0.02, $
        xticklen: -0.02 }


;---Convert images from mlon/mlat to mlt/mlat.
    mlt_bins = make_bins(mlt_range, mlt_binsize)
    nmlt_bin = n_elements(mlt_bins)
    get_data, ewo_var, times, ewo, mlon_bins
    ntime = n_elements(times)
    mlt_ewo = fltarr(ntime,nmlt_bin)
    for ii=0,ntime-1 do begin
        the_mlts = mlon2mlt(mlon_bins,times[ii])
        dmlt = the_mlts[1:-1]-the_mlts[0:-2]
        index = where(abs(dmlt) gt 12, count)
        if count ne 0 then begin
            if dmlt[index] ge 0 then begin
                the_mlts[index+1:*] -= 24
            endif else begin
                the_mlts[index+1:*] += 24
            endelse
        endif

        mlt_ewo[ii,*] = interpol(ewo[ii,*],the_mlts,mlt_bins)
        index = where(mlt_bins le min(the_mlts) or mlt_bins ge max(the_mlts), count)
        if count ne 0 then mlt_ewo[ii,index] = 0
    endfor
    ystep = 3
    ytickv = make_bins(mlt_range, ystep)
    yticks = n_elements(ytickv)-1
    yminor = ystep
    store_data, mlt_ewo_var, times, mlt_ewo, mlt_bins, limits={$
        spec: 1, $
        no_interp: 1, $
        ytitle: 'MLT (hr)', $
        ystyle: 1, $
        yrange: mlt_range, $
        ytickv: ytickv, $
        yticks: yticks, $
        yminor: yminor, $
        ztitle: 'Upward current (A)', $
        zlog: 0 , $
        zrange: [0,.5e5], $
        yticklen: -0.02, $
        xticklen: -0.02 }


end

mlt_range = [-1,1]*6
time_range = time_double(['2013-06-07/04:00','2013-06-07/07:00'])
themis_read_upward_current_ewo, time_range, mlt_range=mlt_range

end
