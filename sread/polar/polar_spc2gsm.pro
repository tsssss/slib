;+
; Rotate a 3D vector in SPC to GSM.
;-
pro polar_spc2gsm, ivar, ovar, quaternion=qvar, probe=probe

    if n_elements(ovar) eq 0 then ovar = ivar+'_gsm'
    get_data, ivar, times, ivec

    pre0 = get_prefix(ivar)
    if n_elements(qvar) eq 0 then qvar = pre0+'q_spc2gsm'

    probe = ''
    time_range = minmax(times)
    if check_if_update(qvar, time_range) then polar_read_quaternion, time_range, probe=probe

    get_data, qvar, uts, quvw2gsm
    if n_elements(uts) ne n_elements(times) then quvw2gsm = qslerp(quvw2gsm, uts, times)
    muvw2gsm = qtom(quvw2gsm)

    ovec = rotate_vector(ivec, muvw2gsm)
    store_data, ovar, times, ovec
    colors = get_setting(ivar, 'colors', exist)
    if ~exist then colors = sgcolor(['red','green','blue'])
    unit = get_setting(ivar, 'unit', exist)
    if ~exist then unit = 'xxx'
    short_name = get_setting(ivar, 'short_name', exist)
    if ~exist then short_name = ''
    add_setting, ovar, /smart, {$
        display_type: 'vector', $
        unit: unit, $
        short_name: short_name, $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: colors}

end
