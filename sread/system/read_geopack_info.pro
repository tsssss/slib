;+
; Use an orbit variable in GSM to get in-situ model B in GSM (T89),
; footpoint in GSM, and mapping factor.
; These variables are saved as prefix_[fpt_gsm,bmod_gsm,c_map]_suffix.
; 
; rvar. A string of an orbit variable.
; par. Default is 2, input parameter for Txx models.
; h0. The altitude of lower boundary. Default is 100 km.
; direction. The tracing direction. 1 for parallel to B, -1 for anti-parallel.
;   The default behaviour is to use z_gsm to tell the hemisphere, and trace to
;   the ionosphere.
; prefix. A string to be added before variables, e.g., 'rbspb_'. Default 
;   behaviour is to figure out from rvar variable.
; suffix. A string to be added after variables, e.g., '_t89'. Default is ''.
;-
pro read_geopack_info, rvar, par=par, h0=h0, direction=dir, $
    prefix=pre0, suffix=suf0

    if tnames(rvar) eq '' then message, 'Orbit data not found: '+rvar+' ...'
    coord = get_setting(rvar, 'coord', exist)
    if exist then if strlowcase(coord) ne 'gsm' then message, 'Orbit is not in GSM ...'
    auto_dir = not keyword_set(dir) 
    
    re = 6378d
    if n_elements(h0) eq 0 then h0 = 100d
    r0 = h0/re+1
    
    if n_elements(model) eq 0 then model = 't89'
    if n_elements(par) eq 0 then par = 2d
    
    get_data, rvar, times, rgsm
    ntime = n_elements(times)
    fgsm = rgsm     ; footpoint position in GSM.
    bfgsm = rgsm    ; footpoint B field in GSM.
    b0gsm = rgsm    ; in-situ B field in GSM.
    
    for i=0, ntime-1 do begin
        tilt = geopack_recalc(times[i])
        rx = rgsm[i,0]
        ry = rgsm[i,1]
        rz = rgsm[i,2]
        if auto_dir then begin
            if rz ge 0 then dir = -1 else dir = 1   ; -1 is along B, i.e., to ionosphere for nothern hemisphere.
        endif
        
        ; in-situ B field.
        geopack_igrf_gsm, rx,ry,rz, bx,by,bz
        geopack_t89, par, rx,ry,rz, dbx,dby,dbz
        b0gsm[i,*] = [bx,by,bz]+[dbx,dby,dbz]

        ; footpoint position.        
        geopack_trace, rx,ry,rz, dir, par, fx,fy,fz, r0=r0, /refine, /ionosphere, /t89
        fgsm[i,*] = [fx,fy,fz]
        
        ; footpoint B field.
        geopack_igrf_gsm, fx,fy,fz, bx,by,bz
        bfgsm[i,*] = [bx,by,bz]
    endfor
    
    bfmag = vec_mag(bfgsm)
    b0mag = vec_mag(b0gsm)
    cmap = bfmag/b0mag
    
    if n_elements(pre0) eq 0 then pre0 = get_prefix(rvar)
    if n_elements(suf0) eq 0 then suf0 = ''
    
    cmapvar = pre0+'c_map'+suf0
    store_data, cmapvar, times, cmap
    add_setting, cmapvar, /smart, {$
        display_type: 'scalar', $
        unit: '#', $
        short_name: 'C!Dmap!N'}
    
    bmodvar = pre0+'bmod_gsm'+suf0
    store_data, bmodvar, times, b0gsm
    add_setting, bmodvar, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'T89 B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}
    
    bfptvar = pre0+'fpt_gsm'+suf0
    store_data, bfptvar, times, fgsm
    add_setting, bfptvar, /smart, {$
        display_type: 'vector', $
        unit: get_setting(rvar, 'unit'), $
        short_name: 'R!Uf!N', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}

end