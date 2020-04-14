;+
; Convert a vector in FAC to certain coord, which is
; pre-defined by define_fac.
; 
; to=. The output var name.
; q_var=. The quaternion.
;-
pro from_fac, var, to=out_var, q_var=q_var

    coord = strlowcase(get_setting(var, 'coord'))
    if coord ne 'fac' then message, 'Input vector is not in FAC ...'

    if tnames(q_var) eq '' then message, 'Define FAC first ...'
    coord = get_setting(q_var, 'in_coord')

    if n_elements(out_var) eq 0 then out_var = strjoin(strsplit(var, 'fac', /regex, /extract, /preserve_null), strlowcase(coord))


    get_data, var, times, vec
    ntime = n_elements(times)
    get_data, q_var, qtimes, q_xxx2fac
    if ntime ne n_elements(times) then q_xxx2fac = qslerp(q_xxx2fac, qtimes, times)
    m_fac2xxx = qtom(q_xxx2fac)
    for ii=0,ntime-1 do m_fac2xxx[ii,*,*] = transpose(m_fac2xxx[ii,*,*])
    vec = rotate_vector(vec, m_fac2xxx)

    store_data, out_var, times, vec
    add_setting, out_var, /smart, {$
        display_type: 'vector', $
        short_name: get_setting(var,'short_name'), $
        unit: get_setting(var,'unit'), $
        coord: get_setting(q_var,'in_coord'), $
        coord_labels: get_setting(q_var,'in_coord_labels')}

end
