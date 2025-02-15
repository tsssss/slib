;+
; Rotate a 3D vector in GSM to SPC.
;-
function ct_gsm2polar_spc, vec0, time

    compile_opt idl2
    on_error, 2

    vec1 = double(vec0)

    time_range = minmax(time)
    if check_if_update(q_var, time_range) then polar_read_quaternion, time_range, probe=probe
    q_spc2gsm = get_var_data(q_var, times=ut_cotran)
    qspc2gsm = qslerp(q_spc2gsm, ut_cotran, time)
    mspc2gsm = qtom(qspc2gsm)
    for ii=0, nrec-1 do mspc2gsm[ii,*,*] = transpose(mspc2gsm[ii,*,*])
    mgsm2spc = temporary(mspc2gsm)

    return, rotate_vector(vec1, mgsm2spc)

end
