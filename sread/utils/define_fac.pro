;+
; Define FAC in current coord, where the FAC axes are: [b, w, o].
;   b is along background B field;
;   w is along rxb, westward if r is the position.
;   o is along bxw, outward if r is the position.
; Save pre0_[b,w,o]hat_coord.
; 
; bvar.
; rvar.
; time_var=. The tplot var that provides the times. 
;-
pro define_fac, bvar, rvar, time_var=time_var

    if n_elements(bvar) eq 0 then message, 'No bvar ...'
    if n_elements(rvar) eq 0 then message, 'No rvar ...'
    if tnames(bvar) eq '' then message, 'Invalid bvar ...'
    if tnames(rvar) eq '' then message, 'Invalid rvar ...'
    
    coord = get_setting(bvar, 'coord')
    if coord ne get_setting(rvar, 'coord') then $
        message, 'B and R are in different coord ...'
    
    
    if n_elements(time_var) eq 0 then time_var = bvar
    get_data, time_var, times
    
    
    bvec = get_var_data(bvar, at=times)
    rvec = get_var_data(rvar, at=times)

    rhat = sunitvec(rvec)
    bhat = sunitvec(bvec)
    what = sunitvec(vec_cross(rhat, bhat))
    ohat = vec_cross(bhat, what)
    
    pre0 = get_prefix(bvar)
    suf0 = '_'+strlowcase(coord)
    coord_labels = get_setting(bvar, 'coord_labels')
    colors = get_setting(bvar, 'colors')
    
    tvar = pre0+'bhat'+suf0
    store_data, tvar, times, bhat
    add_setting, tvar, /smart, {$
        display_type: 'vector', $
        unit: '#', $
        short_name: 'b!Uhat!N', $
        coord: coord, $
        coord_labels: coord_labels, $
        colors: colors}
        
    tvar = pre0+'what'+suf0
    store_data, tvar, times, what
    add_setting, tvar, /smart, {$
        display_type: 'vector', $
        unit: '#', $
        short_name: 'w!Uhat!N', $
        coord: coord, $
        coord_labels: coord_labels, $
        colors: colors}
    
    tvar = pre0+'ohat'+suf0
    store_data, tvar, times, ohat
    add_setting, tvar, /smart, {$
        display_type: 'vector', $
        unit: '#', $
        short_name: 'o!Uhat!N', $
        coord: coord, $
        coord_labels: coord_labels, $
        colors: colors}

end