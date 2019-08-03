;+
; Generate spice product file for a day.
;
; time. A time in UT sec. Only time[0] is used to determine the day.
; probe=. A string of 'a' or 'b'.
; filename=. A string to set the output file name.
;
; To replace rbsp_gen_spice_product. Need to regenerate from 2012-09-25 to 2018-09-18.
;-
pro rbsp_read_spice_gen_file, time, probe=probe, filename=file, errmsg=errmsg

;---Constant.
    secofday = 86400d
    deg = 180d/!dpi
    rad = !dpi/180
    re = 6378d & re1 = 1d/re
    errmsg = ''

;---Check inputs.
    if n_elements(file) eq 0 then begin
        errmsg = handle_error('No output file ...')
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif

    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif


;---Settings.
    posdt = 60d     ; sec.
    uvwdt = 0.25d   ; sec.

    ; load spice kernels for all times.
    defsysv,'!rbsp_spice', exists=flag
    if flag eq 0 then rbsp_load_spice_kernels, /all

    date = time[0]-(time[0] mod secofday)
    utr = date+[0,secofday]

    pre0 = 'rbsp'+probe+'_'
    odir = fgetpath(file)
    if file_test(odir,/directory) eq 0 then file_mkdir, odir
    offn = file
    if file_test(offn) eq 1 then file_delete, offn  ; overwrite old files.

    ginfo = {$
        title: 'RBSP position and boom direction from SPICE kernel',$
        text: 'Generated by Sheng Tian at the University of Minnesota'}
    scdfwrite, offn, gattribute=ginfo


;---positions.
    posuts = smkarthm(utr[0],utr[1],posdt, 'dx')
    ; Avoid overlapping with next day.
    if posuts[-1] eq utr[1] then posuts = posuts[0:-2]
    rbsp_load_spice_state, probe=probe, coord='gsm', times=posuts, /no_spice_load

    ; get posgsm, mlt, mlat, lshell,
    get_data, pre0+'state_pos_gsm', posuts, posgsm
    posgsm = posgsm*re1
    store_data, pre0+'state_*', /delete

    ; utsec.
    utname = 'ut_pos'
    ainfo = {$
        fieldnam: 'UT time', $
        units: 'sec', $
        var_type: 'support_data'}
    scdfwrite, offn, utname, value=posuts, attribute=ainfo, cdftype='CDF_DOUBLE'

    ; rgsm.
    posname = 'pos_gsm'
    tdat = posgsm
    ainfo = {$
        fieldnam: 'R GSM', $
        units: 'Re', $
        var_type: 'data', $
        depend_0: utname}
    scdfwrite, offn, posname, value=transpose(tdat), attribute=ainfo, dimensions=[3], dimvary=[1]

    ; mlt.
    posname = 'mlt'
    possm = cotran(posgsm, posuts, 'gsm2sm')
    tdat = atan(possm[*,1],possm[*,0])*deg
    tdat = (tdat+360) mod 360   ; convert to 0-360, or 0-24 hr.
    tdat = (tdat/15 + 12) mod 24
    ainfo = {$
        fieldnam: 'MLT', $
        units: 'hr', $
        var_type: 'data', $
        depend_0: utname}
    scdfwrite, offn, posname, value=tdat, attribute=ainfo

    ; mlat.
    posname = 'mlat'
    mlat = atan(possm[*,2],sqrt(possm[*,0]^2+possm[*,1]^2)) ; in rad.
    mlat = mlat*deg
    tdat = mlat
    ainfo = {$
        fieldnam: 'MLat', $
        units: 'deg', $
        var_type: 'data', $
        depend_0: utname}
    scdfwrite, offn, posname, value=tdat, attribute=ainfo

    ; dis.
    posname = 'dis'
    dis = sqrt(possm[*,0]^2+possm[*,1]^2+possm[*,2]^2)
    tdat = dis
    ainfo = {$
        fieldnam: 'Distance', $
        units: 'Re', $
        var_type: 'data', $
        depend_0: utname}
    scdfwrite, offn, posname, value=tdat, attribute=ainfo

    ; lshell
    posname = 'lshell'
    tdat = dis/(cos(mlat)^2)
    ainfo = {$
        fieldnam: 'L', $
        var_type: 'data', $
        depend_0: utname}
    scdfwrite, offn, posname, value=tdat, attribute=ainfo


;---UVW direction.
    scid = strupcase(pre0+'science')

    uvwuts = smkarthm(utr[0],utr[1],uvwdt, 'dx')
    if uvwuts[-1] eq utr[1] then uvwuts = uvwuts[0:-2]
    utname = 'ut_cotran'
    ainfo = {$
        fieldnam: 'UT time', $
        units: 'sec', $
        var_type: 'support_data'}
    scdfwrite, offn, utname, value=uvwuts, attribute=ainfo, cdftype='CDF_DOUBLE'

    tmp = time_string(uvwuts[0], tformat='YYYY-MM-DDThh:mm:ss.ffffff')
    cspice_str2et, tmp, tet0
    ets = tet0+uvwuts-uvwuts[0]
    cspice_pxform, scid, 'GSM', ets, muvw2gsm
    quvw2gsm = mtoq(transpose(muvw2gsm))

    vname = 'q_uvw2gsm'
    tdat = transpose(quvw2gsm)
    ainfo = {$
        fieldnam: 'Q UVW2GSM', $
        var_type: 'data', $
        depend_0: utname}
    scdfwrite, offn, vname, value=tdat, attribute=ainfo, dimensions=[4], dimvary=[1]

end



time = time_double(['2012-09-25','2016-12-31'])
time = time_double(['2017-01-01','2018-07-17'])
time = time_double(['2018-07-17','2018-12-13'])
probes = ['a','b']

rbsp_read_spice_gen_file, time, probes=probes
end
