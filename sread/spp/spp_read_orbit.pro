;+
; Read spacecraft position in km.
;-
;

pro spp_read_orbit, time

    vars = ['time_unix','position']
    spp_read_fields, time, 'ephem_spp_rtn', level='l1', variable=vars, errmsg=errmsg
    if errmsg ne 0 then return
    
    pre0 = 'spp_'
    var = pre0+'r_rtn'
    xyz = ['x','y','z']
    rtn = ['r','t','n']
    
    rename_var, 'position', to=var
    sys_multiply, var, 1e-6, to=var ; km to Gm.
    settings = { $
        display_type: 'vector', $
        unit: 'Gm', $
        short_name: 'R', $
        coord: 'RTN', $
        coord_labels: rtn, $
        colors: [6,4,2]}
    add_setting, var, settings, /smart
    

end