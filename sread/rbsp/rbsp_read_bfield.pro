;+
; Read RBSP DC B field. Default is to read 'hires' data at 64 samples/sec.
; Save as rbspx_b_gsm.
;-
pro rbsp_read_bfield, utr0, probe=probe, resolution=resolution, errmsg=errmsg

    pre0 = 'rbsp'+probe+'_'

    resolution = (keyword_set(resolution))? strlowcase(resolution): '4sec'
    case resolution of
        'hires': dt = 1d/64
        '1sec': dt = 1d
        '4sec': dt = 4d
    endcase

    ; read 'rbspx_b_gsm'
    rbsp_read_emfisis, utr0, id='l3%magnetometer', probe=probe, $
        resolution=resolution, coord='gsm', errmsg=errmsg
    if errmsg ne '' then return

    bvar = pre0+'b_gsm'
    add_setting, bvar, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}

    get_data, bvar, times, bgsm
    if n_elements(utr0) eq 2 then begin
        index = lazy_where(times, utr0, count=count)
        if count ne 0 then begin
            times = times[index]
            bgsm = bgsm[index,*]
            store_data, bvar, times, bgsm
        endif
    endif
    uniform_time, bvar, dt

end

utr0 = time_double(['2013-06-10/05:57:20','2013-06-10/05:59:40'])   ; a shorter time range for test purpose.
utr0 = time_double(['2013-06-07/04:40','2013-06-07/05:10'])         ; a longer time range for test purpose.
rbsp_read_bfield, utr0, probe='b'
end
