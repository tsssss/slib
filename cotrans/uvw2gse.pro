;+
; Convert a vector from UVW to GSE.
;
; vec0. An array in [3] or [n,3]. In mGSM, in any unit.
; times. An array of UT sec, in [n].
; probe. A string of 'a' or 'b'. Doesn't need this if wsc is set.
;-

function uvw2gse, vec0, time, probe=probe, _extra=ex
    compile_opt idl2 & on_error, 2

    vec1 = double(vec0)
    n1 = n_elements(vec1)/3

    time_range = minmax(time)
    if n_elements(probe) eq 0 then message, 'Needs probe ...'
    prefix = 'rbsp'+probe+'_'
    q_var = prefix+'q_uvw2gse'
    ;if check_if_update(q_var, time_range) then rbsp_read_quaternion, time_range, probe=probe
    if check_if_update(q_var, time_range) then rbsp_read_q_uvw2gse, time_range, probe=probe
    q_uvw2gse = get_var_data(q_var, times=ut_cotran)
    quvw2gse = qslerp(q_uvw2gse, ut_cotran, time)
    muvw2gse = qtom(quvw2gse)

    ; do rotation.
    vec1 = rotate_vector(vec1, muvw2gse)
    return, vec1

end
