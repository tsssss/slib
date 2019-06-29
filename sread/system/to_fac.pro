
pro to_fac, var, to=var1

    coord = strlowcase(get_setting(var, 'coord'))
    if coord eq 'fac' then return
    
    if n_elements(var1) eq 0 then $
        var1 = strjoin(strsplit(var, coord, /regex, /extract, /preserve_null), 'fac')
    
    pre0 = get_prefix(var)
    if n_elements(tnames(pre0+['b','w','o']+'hat_'+coord)) ne 3 then $
        message, 'Define FAC first ...'
    
    get_data, var, times, vec, limits=info
    get_data, pre0+'bhat_'+coord, tmp, bhat
    if n_elements(tmp) ne n_elements(times) then $
        message, 'FAC unit vectors and given vectors do not share the same time ...'
    get_data, pre0+'what_'+coord, tmp, what
    get_data, pre0+'ohat_'+coord, tmp, ohat
    
    vec = [$
        [sdot(vec,bhat)], $
        [sdot(vec,what)], $
        [sdot(vec,ohat)]]
    store_data, var1, times, vec
    add_setting, var1, info
    add_setting, var1, /smart, {$
        coord: 'FAC', $
        coord_labels: ['||','west','outward']}

end