;+
; Uniform interface for converting among standard coordinates:
; 'GSE','SM','GSM','GEI','GEO','MAG'.
; and mission specific coordinates.
;
; vec0. An array in [3] or [n,3]. In GEI, in any unit.
; times. An array of UT sec, in [n].
; msg. A string in the format of 'gsm2gse', where 2 separates the
;   input and output coordinates.
; print_coord=. A boolean to return all supported coords.
;-

function cotran_pro_find_path, path, stop_coord, supported_funcs, $
    parsed_coords

    if n_elements(path) eq 0 then return, !null

    current_coord = path[-1]
    if n_elements(parsed_coords) eq 0 then parsed_coords = list(current_coord)
    if current_coord eq stop_coord then return, path


    index = where(stregex(supported_funcs, current_coord+'2') ne -1, count)
    if count eq 0 then return, !null
    useful_funcs = supported_funcs[index]
    
    new_path_list = list()
    foreach the_func, useful_funcs do begin
        next_coord = (strsplit(the_func,'2',extract=1))[1]
        if parsed_coords.where(next_coord) ne !null then continue
        parsed_coords.add, next_coord
        the_path = cotran_pro_find_path([path,next_coord], stop_coord, supported_funcs, parsed_coords)
        if n_elements(the_path) ne 0 then return, the_path
    endforeach

    return, !null

end


function cotran_pro, input_vec, times, msg, errmsg=errmsg, print_coord=print_coord, probe=probe, mission=mission, _extra=ex

    compile_opt idl2
    on_error, 2

    errmsg = ''
    retval = !null

;    supported_coord_info = dictionary($
;        'rbsp', ['uvw','mgse'], $
;        'themis', ['smc','spg','ssl','dsl'], $
;        'general', ['gei', 'geo','gse','gsm','sm','mag','aacgm'] )
;    supported_coords = supported_coord_info.general
;    foreach key, supported_coord_info.keys() do begin
;        if key eq 'general' then continue
;        supported_coords.add, key+'_'+supported_coord_info[key], extract=1
;    endforeach


    
    ; This needs to be updated.
    supported_funcs = [$
    ;---mission specific
        ; THEMIS.
        'themis_smc2themis_spg', 'themis_spg2themis_smc', $
        'themis_spg2themis_ssl', 'themis_ssl2themis_spg', $
        'themis_ssl2themis_dsl', 'themis_dsl2themis_ssl', $
        'themis_dsl2gse', 'gse2themis_dsl', $
        ; RBSP.
        'rbsp_uvw2gse', 'gse2rbsp_uvw', $
        'rbsp_mgse2gse', 'gse2rbsp_mgse', $
    ;---General
        'gei2geo','geo2gei', $
        'gei2gse','gse2gei', $
        'geo2aacgm', 'aacgm2geo', $
        'geo2mag','mag2geo', $
        'gse2gsm','gsm2gse', $
        'gsm2sm','sm2gsm' ]

    supported_coord = strsplit(supported_funcs,'2',extract=1)
    supported_coord = supported_coord.toarray()
    supported_coord = supported_coord[*]
    supported_coord = sort_uniq(supported_coord)
    if keyword_set(print_coord) then return, supported_coord


    coord_msg = strsplit(msg,'2',extract=1)
    input_coord = coord_msg[0]
    output_coord = coord_msg[1]

;    supported_coord = [ $
;        'rbsp_'+['uvw','mgse'], $
;        'themis_'+['smc','spg','ssl','dsl'], $
;        ['gei', 'geo','gse','gsm','sm','mag','aacgm'] ]
    if where_pro(supported_coord, 'eq', input_coord) eq !null then begin
        errmsg = 'Unkown input_coord: '+input_coord+' ...'
        return, retval
    endif
    if where_pro(supported_coord, 'eq', output_coord) eq !null then begin
        errmsg = 'Unkown output_coord: '+output_coord+' ...'
        return, retval
    endif

    ; Find the path from input_coord to output_coord.
    paths = cotran_pro_find_path(input_coord, output_coord, supported_funcs)
    npath = n_elements(paths)
    if npath eq 0 then begin
        errmsg = 'No valid path found ...'
        return, retval
    endif

    routines = strarr(npath-1)
    for ii=0,npath-2 do routines[ii] = strjoin(paths[ii:ii+1],'2')
    output_vec = float(input_vec)
    foreach routine, routines do begin
        output_vec = call_function(routine, output_vec, times, probe=probe, errmsg=errmsg)
        if errmsg ne '' then return, retval
    endforeach
    return, output_vec
    
end


test_vec = [[1,2,3]]
times = [1]
probe = 'a'
vec_out = cotran_pro(test_vec, times, 'gse2gsm', probe=probe)
end