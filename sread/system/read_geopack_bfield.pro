;+
; Use an orbit variable in GSM to get in-situ model B in GSM (T89),
; footpoint in GSM, and mapping factor.
; These variables are saved as prefix_[fpt_gsm,bmod_gsm,c_map]_suffix.
;
; r_var. A string of an orbit variable.
; prefix. A string to be added before variables, e.g., 'rbspb_'. Default
;   behaviour is to figure out from r_var variable.
; igrf=. Boolean, set to use IGRF, otherwise use dipole.
; suffix. A string to be added after variables, e.g., '_t89'. Default is ''.
;-
pro read_geopack_bfield, r_var, errmsg=errmsg, $
    model=model, igrf=igrf, $
    prefix=pre0, suffix=suf0

;---Check inputs.
    errmsg = ''
    if tnames(r_var) eq '' then begin
        errmsg = handle_error('Orbit data not found: '+r_var+' ...')
        return
    endif

    ; coord = get_setting(r_var, 'coord', exist)
    ; if exist then if strlowcase(coord) ne 'gsm' then begin
    ;     errmsg = handle_error('Orbit is not in GSM ...')
    ; endif

    ; Check mapping model.
    if n_elements(model) eq 0 then model = 't89'
    index = where(model eq ['t89','t96','t01','t04s'], count)
    if count eq 0 then begin
        errmsg = handle_error('Does not support given model: '+model+' ...')
        return
    endif


;---Prepare model parameter.
    get_data, r_var, times
    ntime = n_elements(times)

    par_var = model+'_par'
    if tnames(par_var) eq '' then begin
        time_range = minmax(times)
        sgeopack_par, time_range, model
    endif
    get_data, par_var, uts, pars
    store_data, par_var, times, sinterpol(pars, uts, times)

    ndim = 3
    b0gsm = fltarr(ntime,ndim)  ; in-situ B field in GSM.
    b_igrf_gsm = fltarr(ntime,ndim)

    t89 = (model eq 't89')? 1: 0
    t96 = (model eq 't96')? 1: 0
    t01 = (model eq 't01')? 1: 0
    t04s = (model eq 't04s')? 1: 0
    storm = (model eq 't04s')? 1: 0


;---Run model through each time.
    rgsm = get_var_data(r_var)
    pars = get_var_data(par_var)

    for ii=0, ntime-1 do begin
        tilt = geopack_recalc(times[ii])
        par = reform(pars[ii,*])

        ; in-situ position
        rx = rgsm[ii,0]
        ry = rgsm[ii,1]
        rz = rgsm[ii,2]

        ; in-situ B field.
        if keyword_set(igrf) then begin
            geopack_igrf_gsm, rx,ry,rz, bx,by,bz
        endif else begin
            geopack_dip, rx,ry,rz, bx,by,bz
        endelse
        case model of
            't89': geopack_t89, par, rx,ry,rz, dbx,dby,dbz
            't96': geopack_t96, par, rx,ry,rz, dbx,dby,dbz
            't01': geopack_t01, par, rx,ry,rz, dbx,dby,dbz
            't04s': geopack_ts04, par, rx,ry,rz, dbx,dby,dbz
        endcase
        b0gsm[ii,*] = [bx,by,bz]+[dbx,dby,dbz]
        b_igrf_gsm[ii,*] = [bx,by,bz]
    endfor


;---Save data.
    if n_elements(pre0) eq 0 then pre0 = get_prefix(r_var)
    if n_elements(suf0) eq 0 then suf0 = '_'+model

    bmod_var = pre0+'bmod_gsm'+suf0
    store_data, bmod_var, times, b0gsm
    add_setting, bmod_var, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: strupcase(model)+' B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z']}

    b_igrf_var = pre0+'bmod_gsm_igrf'
    store_data, b_igrf_var, times, b_igrf_gsm
    add_setting, b_igrf_var, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'IGRF B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z']}

end


times = time_double(['2014-08-28/10:12','2014-08-28/10:13'])
the_time = times[0]
r_mag = transpose([[2.14,-6.86,0.53],[2.13,-6.89,0.53]])    ; th-d.
r_gsm = cotran(r_mag, times, 'mag2gsm')
r_gsm = transpose([[-8.64,-2.86,2.19],[-8.64,-2.87,2.20]])    ; th-e.
r_var = 'r_gsm'
model = 't89'
par = 2.
store_data, r_var, times, r_gsm
read_geopack_bfield, r_var, model=model

end
