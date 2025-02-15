;+
; Rotate a 3D vector in SPC to GSM.
;-

function ct_polar_spc2gsm, vec0, time, _extra=ex

    compile_opt idl2
    on_error, 2

    vec1 = double(vec0)

    time_range = minmax(time)
    if check_if_update(q_var, time_range) then q_var = polar_read_q_spc2gsm(time_range, probe=probe)
    q_spc2gsm = get_var_data(q_var, times=ut_cotran)
    qspc2gsm = qslerp(q_spc2gsm, ut_cotran, time)
    mspc2gsm = qtom(qspc2gsm)

    return, rotate_vector(vec1, mspc2gsm)

end


;pro ct_polar_spc2gsm, ivar, ovar, quaternion=qvar, probe=probe
;
;    if n_elements(ovar) eq 0 then ovar = ivar+'_gsm'
;    get_data, ivar, times, ivec
;    index = uniq(times,sort(times)) ; ensure monotonic time, otherwise qslerp won't work.
;    times = times[index]
;    ivec = ivec[index,*]
;
;    prefix = get_prefix(ivar)
;    if n_elements(q_var) eq 0 then q_var = polar_read_q_spc2gsm(time_range, get_name=1)
;
;    probe = ''
;    time_range = get_var_setting(ivar, 'requested_time_range')
;    if check_if_update(q_var, time_range) then q_var = polar_read_q_spc2gsm(time_range)
;
;    get_data, qvar, uts, quvw2gsm
;    if n_elements(uts) ne n_elements(times) then quvw2gsm = qslerp(quvw2gsm, uts, times)
;    muvw2gsm = qtom(quvw2gsm)
;
;    ovec = rotate_vector(ivec, muvw2gsm)
;    store_data, ovar, times, ovec
;    colors = get_setting(ivar, 'colors', exist)
;    if ~exist then colors = sgcolor(['red','green','blue'])
;    unit = get_setting(ivar, 'unit', exist)
;    if ~exist then unit = 'xxx'
;    short_name = get_setting(ivar, 'short_name', exist)
;    if ~exist then short_name = ''
;    add_setting, ovar, /smart, {$
;        display_type: 'vector', $
;        unit: unit, $
;        short_name: short_name, $
;        coord: 'GSM', $
;        coord_labels: ['x','y','z'], $
;        colors: colors}
;
;end
