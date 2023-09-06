;+
; Read B field from cdaweb.
;-

pro goes_read_bfield_cdaweb, time, probe=probe, errmsg=errmsg, coord=coord

    errmsg = ''

    files = goes_read_fgm_l2_netcdf_prepare_files(time, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return

    if n_elements(coord) eq 0 then coord = 'gsm'
    the_probe = (strmid(probe,0,1) eq 'g')? strmid(probe,1): probe
    the_probe = string(fix(the_probe),format='(I02)')

    prefix = 'g'+the_probe+'_'
    in_var = 'b_gsm'
    out_var = prefix+'b_'+coord
    time_var_name = 'time'
    time_var_type = 'goes_time'

    ; Read data.
    times = []
    b_coord = []
    foreach file, files do begin
        b_coord = [b_coord, transpose(netcdf_read_var(in_var, filename=file))]
        times = [times, netcdf_read_var(time_var_name, filename=file)]
    endforeach
    times = goes_time_to_unix(times)
    
    ; Remove invalid data.
    fillval = !values.f_nan
    index = where(b_coord eq -9999, count)
    if count ne 0 then begin
        b_coord[index] = fillval
    endif
    
    ; Trim to wanted time.
    if n_elements(time) eq 2 then begin
        index = where_pro(times, '[]', time, count=count)
        if count eq 0 then begin
            errmsg = 'No data in time ...'
            return
        endif
        times = times[index]
        b_coord = b_coord[index,*]
    endif
    
    if coord ne 'gsm' then b_coord = cotran(b_coord, times, 'gsm2'+coord)
    store_data, out_var, times, b_coord
    add_setting, out_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', strupcase(coord), $
        'coord_labels', ['x','y','z'] )

end


probe = '11'
time_range = time_double(['2008-03-14/06:30','2008-03-14:06:40'])

probe = '10'
time_range = time_double(['2008-02-29/08:00','2008-02-29/10:00'])
goes_read_bfield_cdaweb, time_range, probe=probe
end
