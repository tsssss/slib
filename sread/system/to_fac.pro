;+
; Convert a vector in certain coord to FAC, which is
; pre-defined by define_fac.
;-
pro to_fac, var, to=out_var, q_var=q_var

    coord = strlowcase(get_setting(var, 'coord'))
    if coord eq 'fac' then return

    if n_elements(q_var) eq 0 then q_var = get_prefix(var)+'q_'+strlowcase(coord)+'2fac'
    if tnames(q_var) eq '' then message, 'Define FAC first ...'

    if n_elements(out_var) eq 0 then $
        out_var = strjoin(strsplit(var, strlowcase(coord), /regex, /extract, /preserve_null), 'fac')


    get_data, var, times, vec
    ntime = n_elements(times)
    get_data, q_var, qtimes, q_xxx2fac
    if ntime ne n_elements(times) then q_xxx2fac = qslerp(q_xxx2fac, qtimes, times)
    m_xxx2fac = qtom(q_xxx2fac)
    vec = rotate_vector(vec, m_xxx2fac)

    store_data, out_var, times, vec
    add_setting, out_var, /smart, {$
        display_type: 'vector', $
        short_name: get_setting(var,'short_name'), $
        unit: get_setting(var,'unit'), $
        coord: 'FAC', $
        coord_labels: get_setting(q_var,'out_coord_labels')}

end
