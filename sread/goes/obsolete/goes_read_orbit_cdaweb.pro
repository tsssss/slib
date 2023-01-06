;+
; Read R from cdaweb.
;-

pro goes_read_orbit_cdaweb, time, probe=probe, errmsg=errmsg, coord=coord

    errmsg = ''

    files = goes_read_fgm_l2_netcdf_prepare_files(time, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return

    if n_elements(coord) eq 0 then coord = 'geo'
    the_probe = (strmid(probe,0,1) eq 'g')? strmid(probe,1): probe
    the_probe = string(fix(the_probe),format='(I02)')

    prefix = 'g'+the_probe+'_'
    in_var = 'orbit_llr_geo'
    out_var = prefix+'r_'+coord
    time_var_name = 'time_orbit'
    time_var_type = 'goes_time'

    ; Read data.
    times = []
    r_coord = []
    foreach file, files do begin
        r_coord = [r_coord, transpose(netcdf_read_var(in_var, filename=file))]
        times = [times, netcdf_read_var(time_var_name, filename=file)]
    endforeach
    times = goes_time_to_unix(times)
    rad = constant('rad')
    r_lat = r_coord[*,0]*rad
    r_lon = r_coord[*,1]*rad
    r_dis = r_coord[*,2]*(1e-3/constant('re'))
    r_xy = r_dis*cos(r_lat)
    r_coord = [[r_xy*cos(r_lon)],[r_xy*sin(r_lon)],[r_dis*sin(r_lat)]]

    ; Remove invalid data.
    fillval = !values.f_nan
    index = where(r_coord eq -9999, count)
    if count ne 0 then begin
        r_coord[index] = fillval
    endif

    ; Trim to wanted time.
    if n_elements(time) eq 2 then begin
        index = lazy_where(times, '[]', time, count=count)
        if count eq 0 then begin
            errmsg = 'No data in time ...'
            return
        endif
        times = times[index]
        r_coord = r_coord[index,*]
    endif

    if coord ne 'geo' then r_coord = cotran(r_coord, times, 'geo2'+coord)
    store_data, out_var, times, r_coord
    add_setting, out_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'Re', $
        'short_name', 'R', $
        'coord', strupcase(coord), $
        'coord_labels', ['x','y','z'] )

end


probe = '13'
time_range = time_double(['2008-03-14/06:30','2008-03-14:06:40'])
goes_read_orbit_cdaweb, time_range, probe=probe, coord='gsm'
end
