;+
; Read Themis DC B field. Default is to read '3sec' data.
;-
; Read Themis B field in GSM. Default is 3 sec.
;+
;
pro themis_read_bfield, time, probe=probe, resolution=resolution, coord=coord, errmsg=errmsg, _extra=ex

    errmsg = ''
    pre0 = 'th'+probe+'_'

    if n_elements(coord) eq 0 then coord = 'gsm'
    ;resolution = (keyword_set(resolution))? strlowcase(resolution): '3sec'
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
    flag_var = pre0+'fgm_'+type+'_quality'
    rename_var, pre0+type+'_gsm', to=var
    uniform_time, var, dt
    uniform_time, flag_var, dt
    
    ; Remove data out of normal range.
    get_data, var, times, bgsm
    index = where(snorm(bgsm) ge 4e4, count)
    if count ne 0 then begin
        bgsm[index,*] = !values.f_nan
        store_data, var, times, bgsm
    endif
    
    ; Flags for bad data.
    ; Looks like: 2 for eclipse, 1 for commisional phase.
    pad = 120.  ; sec.
    flag_time = time_double('2007-01-14')

    get_data, flag_var, times, flags
    ntime = n_elements(times)
    all_flags = bytarr(ntime)+1
    
    index = where(times lt flag_time and flags gt 1, count)
    if count ne 0 then all_flags[index] = 0
    index = where(times le flag_time and flags gt 0, count)
    if count ne 0 then all_flags[index] = 0
    
    
    index = where(all_flags eq 0, count)
    if count ne 0 then begin
        bad_times = time_to_range(times[index], time_step=dt)
        bad_times[*,0] -= pad
        bad_times[*,1] += pad
        nbad_time = n_elements(bad_times)/2
        for ii=0, nbad_time-1 do bgsm[where_pro(times,'[]',reform(bad_times[ii,*])),*] = !values.f_nan
        store_data, var, times, bgsm
    endif

    if coord ne 'gsm' then begin
        get_data, var, times, vec
        vec = cotran(vec, times, 'gsm2'+coord)
        var = pre0+'b_'+coord
        store_data, var, times, vec
    endif
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z']}

    uniform_time, var, dt
end


time = time_double(['2013-10-30/23:00','2013-10-31/06:00'])
time = time_double(['2014-08-28','2014-08-29'])
time = time_double(['2013-08-26/20:41','2013-08-29/04:26'])

time = time_double(['2014-08-28','2014-08-29'])
probe = 'a'
;time = time_double(['2008-01-12','2008-01-15'])
themis_read_bfield, time, probe=probe, errmsg=errmsg
end
