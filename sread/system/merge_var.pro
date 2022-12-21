;+
; Merge tplot vars into one.
;-

function merge_var, vars, output=output_var
    
    if n_elements(output_var) eq 0 then message, 'no output_var ...'

    ndim = n_elements(vars)    
    if ndim eq 0 then message, 'no variables ...'
    if ndim eq 1 then begin
        copy_data, vars[0], output_var
    endif
    get_data, vars[0], t0, f0, limits=lim
    nrec = n_elements(t0)
    
    ; combine.
    s0 = make_array(nrec, ndim, type = size(f0[0],/type))
    for ii=0, ndim-1 do begin
        s0[*,ii] = get_var_data(vars[ii], at=t0)
    endfor

    store_data, output_var, t0, s0, limits=lim
    return, output_var

end