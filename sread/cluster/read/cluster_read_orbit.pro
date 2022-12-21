;+
; Read Cluster orbit. Save as 'cx_r_<coord>', Default <coord> is gsm.
;
; input_time_range. Unix time or string for time range.
; probe=. A string for probe. '1','2','3','4'.
;-

function cluster_read_orbit, input_time_range, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, resolution=resolution, _extra=ex
    
    if size(probe,type=1) ne 7 then probe = string(probe,format='(I0)')
    prefix = 'c'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'r_'+coord
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = cluster_load_ssc(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval


    var_list = list()

    orig_var = prefix+'r_gse'
    suffix = '_xyz_gse__CL_JP_PGP'
    var_list.add, dictionary($
        'in_vars', ['sc_r','sc_dr'+probe]+suffix, $
        'out_vars', prefix+['r0_gse','r1_gse'], $
        'time_var_name', 'Epoch__CL_JP_PGP', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    get_data, prefix+'r0_gse', times, r0_gse
    get_data, prefix+'r1_gse', times, r1_gse
    r_gse = (r0_gse+r1_gse)/constant('re')
    store_data, orig_var, times, r_gse

    if coord ne 'gse' then begin
        get_data, orig_var, times, r_gse, limits=lim
        r_coord = cotran(r_gse, times, 'gse2'+coord)
        store_data, var, times, r_coord, limits=lim
    endif

    add_setting, var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'R', $
        'unit', 'Re', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )
    
    return, var

end

time_range = ['2013-06-07','2013-06-08']
probe = '1'
var = cluster_read_orbit(time_range, probe=probe)
end