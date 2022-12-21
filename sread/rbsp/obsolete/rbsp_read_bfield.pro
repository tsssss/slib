;+
; Read RBSP DC B field. Default is to read '4sec' data.
; Save as rbspx_b_gsm.
; 
; utr0.
; probe=.
; resolution=. 'hires', '1sec', '4sec'.
;-
pro rbsp_read_bfield, utr0, probe=probe, resolution=resolution, errmsg=errmsg, coord=coord, _extra=ex

    pre0 = 'rbsp'+probe+'_'
    if n_elements(coord) eq 0 then coord = 'gsm'
    b_coord_var = pre0+'b_'+coord

    resolution = (keyword_set(resolution))? strlowcase(resolution): '4sec'
    case resolution of
        'hires': dt = 1d/64
        '1sec': dt = 1d
        '4sec': dt = 4d
    endcase

    ; read 'rbspx_b_gsm'
    rbsp_read_emfisis, utr0, id='l3%magnetometer', probe=probe, $
        resolution=resolution, coord='gsm', errmsg=errmsg

    bvar = pre0+'b_gsm'
    get_data, bvar, times, bgsm
    index = where(bgsm le -99999, count)
        if count ne 0 then begin
        bgsm[index] = !values.f_nan
        store_data, bvar, times, bgsm
    endif
    if n_elements(utr0) eq 2 then begin
        index = lazy_where(times, utr0, count=count)
        if count ne 0 then begin
            times = times[index]
            bgsm = bgsm[index,*]
            store_data, bvar, times, bgsm
        endif
    endif
    uniform_time, bvar, dt
    
    ; convert to the wanted coord.
    if coord ne 'gsm' then begin
        get_data, bvar, times, bgsm
        b_coord = cotran(bgsm, times, 'gsm2'+coord, probe=probe)
        store_data, b_coord_var, times, b_coord
    endif
    
    add_setting, bvar, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: constant('rgb') }

end

utr0 = time_double(['2013-06-10/05:57:20','2013-06-10/05:59:40'])   ; a shorter time range for test purpose.
utr0 = time_double(['2013-06-07/04:40','2013-06-07/05:10'])         ; a longer time range for test purpose.
utr0 = time_double(['2015-09-15','2015-09-16'])         ; a day with data gap.
rbsp_read_bfield, utr0, probe='b'
end