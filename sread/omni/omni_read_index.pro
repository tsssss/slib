;+
; Read OMNI geomagnetic indices, e.g., AE, Dst.
; resolution can be '1min', '5min'.
;-
;
pro omni_read_index, utr0, resolution=resolution, errmsg=errmsg, index=index

    if n_elements(resolution) eq 0 then resolution = '1min'
    if n_elements(index) eq 0 then index = ['ae','dst']
    
    indices = ['ae','dst']
    vnames = ['AE_INDEX','SYM_H']
    
    nvar = n_elements(index)
    if nvar eq 0 then begin
        errmsg = 'No index selected ...'
        return
    endif
    
    vars = strarr(nvar)
    for i=0, nvar-1 do vars[i] = vnames[where(indices eq index[i])]

    omni_read, utr0, resolution, errmsg=errmsg, variable=['Epoch',vars]
    if errmsg ne '' then return
    
    case resolution of
        '1min': dt = 60d
        '5min': dt = 300d
    endcase
    for i=0, nvar-1 do begin
        tvar = index[i]
        case tvar of
            'ae': short_name = 'AE'
            'dst': short_name = 'Dst'
        endcase
        rename_var, strlowcase(vars[i]), to=tvar
        add_setting, tvar, /smart, {$
            display_type: 'scalar', $
            unit: 'nT', $
            short_name: short_name}
            
        uniform_time, tvar, dt
    endfor

end
