;+
; Read spacecraft position.
;-

pro polar_read_orbit, time_range, errmsg=errmsg, coord=in_coord

    if n_elements(in_coord) eq 0 then coord = 'gsm' else coord = strlowcase(in_coord)

    files = polar_load_ssc(time_range, id='sheng', errmsg=errmsg)
    if errmsg ne '' then return

    prefix = 'po_'
    var_list = list()

    in_vars = ['pos_gse','mlt','ilat','mlat']
    out_vars = prefix+['r_gse','mlt','ilat','mlat']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return


;---Touch on the formats etc.
    r_gse_var = prefix+'r_gse'
    get_data, r_gse_var, times, r_gse

    ; Convert to Re.
    re = cdf_read_var('Re', filename=files[0])
    re1 = 1d/re
    for ii=0,2 do r_gse[*,ii] *= re1

    ; Convert to coord.
    r_coord_var = prefix+'r_'+coord
    if coord eq 'gse' then begin
        r_coord = temporary(r_gse)
    endif else begin
        r_coord = cotran(r_gse, times, 'gse2'+coord)
    endelse
    store_data, r_coord_var, times, r_coord

    settings = dictionary($
        'display_type', 'vector', $
        'short_name', 'R', $
        'unit', 'Re', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )
    add_setting, r_coord_var, smart=1, settings

    ; Other position info.
    add_setting, prefix+'mlt', smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'MLT', $
        'unit', 'h', $
        'yrange', [0,24], $
        'yticks', 2, $
        'yminor', 2 )
    add_setting, prefix+'mlat', smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'MLat', $
        'unit', 'deg')
    add_setting, prefix+'ilat', smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'ILat', $
        'unit', 'deg')

end

time_range = ['1996-02-27','1996-03-02']
polar_read_orbit, time_range
end
