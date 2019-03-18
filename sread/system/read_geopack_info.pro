;+
; Use an orbit variable in GSM to get in-situ model B in GSM (T89),
; footpoint in GSM, and mapping factor.
; These variables are saved as prefix_[fpt_gsm,bmod_gsm,c_map]_suffix.
;
; r_var. A string of an orbit variable.
; par. Default is 2, input parameter for Txx models.
; h0. The altitude of lower boundary. Default is 100 km.
; direction. The tracing direction. 1 for parallel to B, -1 for anti-parallel.
;   The default behaviour is to use z_gsm to tell the hemisphere, and trace to
;   the ionosphere.
; prefix. A string to be added before variables, e.g., 'rbspb_'. Default
;   behaviour is to figure out from r_var variable.
; suffix. A string to be added after variables, e.g., '_t89'. Default is ''.
;-
pro read_geopack_info, r_var, errmsg=errmsg, $
    model=model, h0=h0, direction=dir, $
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

    ; Check mapping direction.
    auto_dir = not keyword_set(dir)

    ; Check mapping altitude.
    re = 6378d  ; km.
    if n_elements(h0) eq 0 then h0 = 100d   ; km.
    r0 = h0/re+1

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
    interp_time, par_var, to=r_var

    ndim = 3
    fgsm = fltarr(ntime,ndim)   ; footpoint position in GSM.
    fbgsm = fltarr(ntime,ndim)  ; footpoint B field in GSM.
    b0gsm = fltarr(ntime,ndim)  ; in-situ B field in GSM.
    fmlat = fltarr(ntime)       ; footpoint MLat in deg.
    fmlon = fltarr(ntime)       ; footpoint MLon in deg.


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
        geopack_igrf_gsm, rx,ry,rz, bx,by,bz
        case model of
            't89': geopack_t89, par, rx,ry,rz, dbx,dby,dbz
            't96': geopack_t96, par, rx,ry,rz, dbx,dby,dbz
            't01': geopack_t01, par, rx,ry,rz, dbx,dby,dbz
            't04': geopack_ts04, par, rx,ry,rz, dbx,dby,dbz
        endcase
        b0gsm[ii,*] = [bx,by,bz]+[dbx,dby,dbz]

        ; determine tracing direction and trace.
        if auto_dir then begin
            if rz ge 0 then dir = -1 else dir = 1   ; -1 is along B, i.e., to ionosphere for nothern hemisphere.
        endif
        geopack_trace, rx,ry,rz, dir, par, $
            fx,fy,fz, r0=r0, /refine, /ionosphere, $
            t89=t89, t96=t96, t01=t01, ts04=ts04, storm=storm
        fgsm[ii,*] = [fx,fy,fz]

        ; footpoint B field.
        geopack_igrf_gsm, fx,fy,fz, bx,by,bz
        fbgsm[ii,*] = [bx,by,bz]

        ; other footpoint quantities.
        geopack_conv_coord, fx,fy,fz, /from_gsm, fa,fb,fc, /to_mag
        fmlat[ii] = asin(fc/r0)
        fmlon[ii] = atan(fb,fa)
    endfor

    ; footpoint MLat, MLon, and MLT.
    deg = 180d/!dpi
    fmlat *= deg
    fmlon *= deg
    fmlt = mlon2mlt(fmlon, times)
    ; mapping coefficient, |B_footpoint|/|B_model|.
    ; this is c0map, since it uses the model field.
    ; once the measured |B| is available, we can get the real
    ; mapping coefficient cmap = c0map *|B_model|/|B|.
    c0map = vec_mag(fbgsm)/vec_mag(b0gsm)


;---Save data.
    if n_elements(pre0) eq 0 then pre0 = get_prefix(r_var)
    if n_elements(suf0) eq 0 then suf0 = '_'+model

    c0map_var = pre0+'c0map'+suf0
    store_data, c0map_var, times, c0map
    add_setting, c0map_var, /smart, {$
        display_type: 'scalar', $
        unit: '#', $
        short_name: 'C0!Dmap!N'}

    bmod_var = pre0+'bmod_gsm'+suf0
    store_data, bmod_var, times, b0gsm
    add_setting, bmod_var, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'T89 B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}

    fpt_var = pre0+'fpt_gsm'+suf0
    store_data, fpt_var, times, fgsm
    add_setting, fpt_var, /smart, {$
        display_type: 'vector', $
        unit: get_setting(r_var, 'unit'), $
        short_name: 'F', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}

    fmlat_var = pre0+'fmlat'+suf0
    store_data, fmlat_var, times, fmlat
    add_setting, fmlat_var, /smart, {$
        display_type: 'scalar', $
        unit: 'deg', $
        short_name: 'MLat'}
    ; fix steps in mlat.
    fix_model_mlat, fmlat_var, to=fmlat_var

    fmlon_var = pre0+'fmlon'+suf0
    store_data, fmlon_var, times, fmlon
    add_setting, fmlon_var, /smart, {$
        display_type: 'scalar', $
        unit: 'deg', $
        short_name: 'MLon'}

    fmlt_var = pre0+'fmlt'+suf0
    store_data, fmlt_var, times, fmlt
    add_setting, fmlt_var, /smart, {$
        display_type: 'scalar', $
        unit: 'deg', $
        short_name: 'MLT'}

end