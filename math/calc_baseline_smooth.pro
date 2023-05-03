
function calc_baseline_smooth, asi_raw, window, times

    if finite(window,nan=1) then return, min(asi_raw)
    if n_elements(times) eq 0 then times = findgen(n_elements(asi_raw))
    if window ge total(minmax(times)*[-1,1])*0.25 then return, min(asi_raw)
    time_step = total(times[0:1]*[-1,1])
    width = window/time_step

    ; Get the smooth, overal trend.
    imgs_bg = smooth(asi_raw, width, nan=1, edge_mirror=1)

    ; Adjust for standar deviation, estimate using smooth+abs.
    imgs_cal = asi_raw-imgs_bg
    imgs_offset = smooth(abs(imgs_cal), width, nan=1, edge_mirror=1)
    imgs_bg -= imgs_offset

    
;    index = where(imgs_cal lt 0, count)
;    if count eq 0 then return, imgs_bg
;    
;    sectors = time_to_range(index,time_step=1)
;    nsector = n_elements(sectors[*,0])
;    sector_offsets = dblarr(nsector)
;    sector_times = dblarr(nsector)
;    for ii=0,nsector-1 do begin
;        the_sector = imgs_cal[sectors[ii,0]:sectors[ii,1]]
;        the_times = times[sectors[ii,0]:sectors[ii,1]]
;        sector_offsets[ii] = min(the_sector, index)
;        sector_times[ii] = the_times[index]
;    endfor
;    imgs_offset = interpol(sector_offsets, sector_times, times)
;    imgs_bg += imgs_offset


    return, imgs_bg

end