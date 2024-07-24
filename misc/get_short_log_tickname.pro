
function get_short_log_tickname, tickv0, $
    linear=linear, is_range=is_range

    log_tickv = tickv0
    if keyword_set(linear) then log_tickv = alog10(tickv0)
    if keyword_set(is_range) then log_tickv = make_bins(log_tickv,1, inner=1)
    log_tickv = fix(log_tickv)
    tickv = 10d^log_tickv
    tickname = '10!U'+string(log_tickv,format='(I0)')
    ntick = n_elements(tickv)

    ; Eliminate 10^0, 10^1, 10^-1
    index = where(log_tickv eq 0, count)
    if count ne 0 then tickname[index] = '1'
    index = where(log_tickv eq 1, count)
    if count ne 0 then tickname[index] = '10'
    index = where(log_tickv eq -1, count)
    if count ne 0 then tickname[index] = '0.1'

    return, tickname

end