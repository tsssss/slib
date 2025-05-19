;+
; Return the optimum boom pair to use for the given day and probe.
;-
function rbsp_efw_phasef_get_boom_pair, day, probe=probe

    ; Use 12 for -B
    boom_pair = '12'
    if probe eq 'b' then return, boom_pair

    ; Use 24 for -A after 2015-01-01.
    if time_double(day[0]) ge time_double('2015') then boom_pair = '24'
    return, boom_pair

end
