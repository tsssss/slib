;+
; Read Themis DC B field. Default is to read '3sec' data.
;-
; Read Themis B field in GSM. Default is 3 sec.
;+
;
pro themis_read_bfield, time, probe=probe, resolution=resolution, errmsg=errmsg, _extra=ex

    pre0 = 'th'+probe+'_'

    resolution = (keyword_set(resolution))? strlowcase(resolution): '3sec'
    case resolution of
        '3sec': begin
            dt = 3.0
            type = 'fgs'
            end
        'hires': message, 'check data rate first ...'
    endcase

    ; read 'thx_fgs_gsm'
    themis_read_fgm, time, id='l2%'+type, probe=probe, errmsg=errmsg, _extra=ex
    if errmsg ne '' then return

    var = pre0+'b_gsm'
    rename_var, pre0+type+'_gsm', to=var
    get_data, var, times, bgsm
    index = where(snorm(bgsm) ge 1e4, count)
    if count ne 0 then begin
        bgsm[index,*] = !values.f_nan
        store_data, var, times, bgsm
    endif
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z']}

    uniform_time, var, dt
end


time = time_double(['2013-10-30/23:00','2013-10-31/06:00'])
themis_read_bfield, time, probe='a'
end
