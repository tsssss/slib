;+
; Themis DSL to GSE.
;
; DSL (Despun Sun L-vectorZ coord)
;
; Adpoted from dsl2gse in spedas.
;-

function themis_dsl2gse, vec_dsl, times, probe=probe, errmsg=errmsg

    errmsg = ''
    retval = !null
    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'

    ; Get spin axis direction in gei.
    time_range = minmax(times)+[-1,1]*themis_get_spin_period()
    wsc_gei_var = themis_read_spin_axis_direction(time_range, probe=probe, coord='gei')
    
    ; Define the rotation matrix/quaternion.
    q_var = prefix+'q_gse2themis_dsl'
    if check_if_update(q_var, time_range) then begin
        wsc_gei = get_var_data(wsc_gei_var, times=uts)
        nut = n_elements(uts)
        ndim = 3
        sun_gei = fltarr(nut,ndim)
        sun_gei[*,0] = 1
        yhat_gei = sunitvec(vec_cross(wsc_gei,sun_gei))

        zhat_gse = cotran(wsc_gei, uts, 'gei2gse')
        yhat_gse = cotran(yhat_gei, uts, 'gei2gse')
        xhat_gse = vec_cross(yhat_gse, zhat_gse)
        m_gse2dsl = fltarr(nut,ndim,ndim)
        m_gse2dsl[*,0,*] = xhat_gse
        m_gse2dsl[*,1,*] = yhat_gse
        m_gse2dsl[*,2,*] = zhat_gse
        
        q_gse2dsl = mtoq(m_gse2dsl)
        store_data, q_var, uts, q_gse2dsl
        xyz = constant('xyz')
        add_setting, q_var, smart=1, dictionary($
            'in_coord', 'GEI', $
            'in_coord_labels', xyz, $
            'out_coord', 'GSE', $
            'out_coord_labels', 'xyz', $
            'requested_time_range', time_range )
    endif
    

    
    ; Interpolate to the wanted times.
    q_gse2dsl = qslerp(get_var_data(q_var, times=uts), uts, times)
    q_dsl2gse = qinv(q_gse2dsl)
    m_dsl2gse = qtom(q_dsl2gse)
    vec_gse = rotate_vector(vec_dsl, m_dsl2gse)

    return, vec_gse

end