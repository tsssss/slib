;+
; Preprocess and load q_uvw2gse to memory.
;-

pro rbsp_efw_read_q_uvw2gse, time_range, probe=probe

    prefix = 'rbsp'+probe+'_'
    the_var = prefix+'q_uvw2gse'
    if check_if_update(the_var, time_range) then rbsp_read_quaternion, time_range, probe=probe

    is_fixed = get_setting(the_var, 'is_fixed', exist)
    if ~exist then need_fix = 1 else need_fix = ~is_fixed
    if need_fix then begin
        rbsp_fix_q_uvw2gse, time_range, probe=probe
        options, the_var, 'is_fixed', 1
    endif

end

time_range = time_double(['2013-01-01','2013-01-02'])
probe = 'a'
rbsp_efw_read_q_uvw2gse, time_range, probe=probe
end