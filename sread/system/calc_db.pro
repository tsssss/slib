;+
; Calculate dB and B0
; 1. If bmodvar is set, then
;   dB = B - B_model. If smooth is set, then dB = dB - smooth(dB, width)
; 2. Otherwise, dB = B - smooth(B, width)
; 
; B0 = B - dB.
; 
; Save pre0+[db,b0]_coord.
; 
; bvar. A string of variable name for the total B field, e.g., rbspb_b_gsm.
; bmodvar. A string of variable name for the model B field, e.g., rbspb_bmod_gsm.
; db_name. A string of varaible name for the dB field, e.g., rbspb_db_gsm.
; b0_name. A string of varaible name for the background B0 field, e.g., rbspb_b0_gsm.
; smooth. A number in sec for smoothing width.
;-
pro calc_db, bvar, bmodvar, db_name=dbvar, b0_name=b0var, smooth=width

    get_data, bvar, times, bgsm
    dt = times[1]-times[0]
    ndim = 3
    coord = get_setting(bvar, 'coord')
    
    pre0 = get_prefix(bvar)
    suf0 = '_'+strlowcase(coord)
    if n_elements(dbvar) eq 0 then dbvar = pre0+'db'+suf0
    if n_elements(b0var) eq 0 then b0var = pre0+'b0'+suf0
    
    if n_elements(bmodvar) eq 0 then begin
        if n_elements(width) eq 0 then width = (times[-1]-times[0])*0.25
        drec = width/dt
        dbgsm = bgsm
        for i=0, ndim-1 do $
            dbgsm[*,i] -= smooth(dbgsm[*,i], drec, edge_mirror=1, nan=1)
    endif else begin
        if coord ne get_setting(bmodvar, 'coord') then $
            message, 'B model and B are in different coord ...'
        
        get_data, bmodvar, tmp, bmodgsm
        if n_elements(tmp) ne n_elements(times) then $
            bmodgsm = sinterpol(bmodgsm, tmp, times)
        
        ; Calculate the perturbation B field.
        dbgsm = bgsm - bmodgsm
        ; Smooth if a valid window size is provided.
        no_smooth = 0
        if n_elements(width) eq 0 then no_smooth = 1 else if width le dt then no_smooth = 1
        if ~no_smooth then begin
            drec = width/dt
            for i=0, ndim-1 do dbgsm[*,i] -= smooth(dbgsm[*,i], drec, edge_mirror=1, nan=1)
        endif
    endelse
    
    unit = get_setting(bvar, 'unit')
    coord_labels = get_setting(bvar, 'coord_labels')
    colors = get_setting(bvar, 'colors')
    
    store_data, dbvar, times, dbgsm
    add_setting, dbvar, /smart, {$
        display_type: 'vector', $
        unit: unit, $
        short_name: 'dB', $
        coord: coord, $
        coord_labels: coord_labels, $
        colors: colors}
    
    store_data, b0var, times, bgsm-dbgsm
    add_setting, b0var, /smart, {$
        display_type: 'vector', $
        unit: unit, $
        short_name: 'B!D0!N', $
        coord: coord, $
        coord_labels: coord_labels, $
        colors: colors}

end