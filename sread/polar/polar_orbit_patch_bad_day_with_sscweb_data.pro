;+
; There are 2 days when the orbit data at CDAWeb are bad. I manually got
; the corrected r_gsm data from the SSCWeb and saved them in CDF.
;-

pro polar_orbit_patch_bad_day_with_sscweb_data

    ; Find the sscweb files.
    ssc_dir = join_path([diskdir('Research'),'sdata','polar','orbit','sscweb_for_bad_days'])
    cdf_pattern = join_path([diskdir('Research'),'sdata','polar','orbit','%Y','po_or_def_%Y%m%d_v02.cdf'])
    if file_test(ssc_dir,/directory) eq 0 then begin
        lprmsg, 'No SSCWeb data, returning ...'
        return
    endif

    ; Read the data from CDF and interpolate to 1 min resolution.
    secofday = 86400d   ; sec.
    secofmin = 60d      ; sec.
    re = 6378d  ; km.
    deg = 180d/!dpi
    rad = !dpi/180d
    ntime = round(secofday/secofmin)
    ssc_files = file_search(join_path([ssc_dir,'*.cdf']))
    foreach ssc_file, ssc_files do begin
        basename = fgetbase(ssc_file)
        date = strmid(basename,6,9)
        times = smkarthm(time_double(date,tformat='YYYY_MMDD'),secofmin,ntime, 'x0')
        epochs = convert_time(times, from='unix', to='epoch')

        cdf = scdfread(ssc_file)
        ets = *cdf[0].value     ; 'Epoch'
        rgsm = *cdf[2].value    ; 'XYZ_GSM'
        ilat = *cdf[1].value    ; 'INVAR_LAT'.
        rgsm = sinterpol(rgsm, ets, epochs, /quadratic)
        ilat = sinterpol(ilat, ets, epochs, /quadratic)
        foreach tmp, cdf do ptr_free, tmp.value

        dis = snorm(rgsm)
        rgse = cotran(rgsm,times, 'gsm2gse')

        ; MLat is in deg, [-90,90], MLT calculated from MLon.
        rmag = cotran(rgsm,times, 'gsm2mag')
        mlat = asin(rmag[*,2]/dis)*deg
        mlon = atan(rmag[*,1],rmag[*,0])*deg
        mlt = mlon2mlt(mlon, times)

        ; MLT is in hr, [0,24].
        index = where(mlt le 0, count)
        if count ne 0 then mlt[index] += 24

        ; ILat is in deg, signed using MLat.
        index = where(mlat le 0, count)
        if count ne 0 then ilat[index] = -ilat[index]


        ; Save data to CDF.
        cdf_file = apply_time_to_pattern(cdf_pattern, times[0])
        if file_test(cdf_file) eq 1 then file_delete, cdf_file

        time_var = 'Epoch'
        scdfwrite, cdf_file, time_var, value=epochs, cdftype='CDF_EPOCH'

        var = 'ilat'
        ainfo = {unit: 'deg'}
        scdfwrite, cdf_file, var, value=ilat, cdftype='CDF_FLOAT', attribute=ainfo

        var = 'mlt'
        ainfo = {unit: 'hr'}
        scdfwrite, cdf_file, var, value=mlt, cdftype='CDF_FLOAT', attribute=ainfo

        var = 'Re'
        ainfo = {unit: 'km', fieldnam: 'Polar Earth radius'}
        scdfwrite, cdf_file, var, value=re, cdftype='CDF_DOUBLE', attribute=ainfo

        var = 'dis'
        ainfo = {unit: 'Re'}
        scdfwrite, cdf_file, var, value=dis, cdftype='CDF_FLOAT', attribute=ainfo

        var = 'pos_gse'
        ainfo = {unit: 'km'}
        for ii=0,2 do rgse[*,ii] *= re
        scdfwrite, cdf_file, var, value=transpose(rgse), cdftype='CDF_DOUBLE', attribute=ainfo, dimensions=[3], dimvary=[1]

        var = 'mlat'
        ainfo = {unit: 'deg'}
        scdfwrite, cdf_file, var, value=mlat, cdftype='CDF_FLOAT', attribute=ainfo
    endforeach

end
