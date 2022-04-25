;+
; Read Themis position. Default is to read 'pos@gsm'.
;-

function themis_read_orbit, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_name, _extra=ex

    prefix = 'th'+probe+'_'
    dt = 60.0
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'r_'+coord
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)

    ; read 'xyz_gsm'
    themis_read_ssc, time_range, id='pos', probe=probe, errmsg=errmsg, _extra=ex

    if coord ne 'gsm' then begin
        get_data, prefix+'r_gsm', times, r_gsm, limits=lim
        r_coord = cotran(r_gsm, times, 'gsm2'+coord)
        store_data, var, times, r_coord, limits=lim
    endif
    
    add_setting, var, smart=1, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: strupcase(coord), $
        coord_labels: constant('xyz')}

    uniform_time, var, dt, errmsg=errmsg
    if errmsg ne '' then begin
        del_data, var
        return, retval
    endif else return, var

end

time_range = ['2008-01-19/06:00','2008-01-19/09:00']
probe = 'd'
var = themis_read_orbit(time_range, probe=probe, coord='sm')
end