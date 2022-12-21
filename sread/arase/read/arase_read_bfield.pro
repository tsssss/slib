;+
; Read Arase B field. Save as 'arase_b_gsm'.
;-

function arase_read_bfield, input_time_range, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, resolution=resolution, _extra=ex

    prefix = 'arase_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'b_'+coord
    if keyword_set(get_name) then return, var
    if keyword_set(resolution) eq 0 then resolution = '8sec'

    time_range = time_double(input_time_range)
    if resolution eq '8sec' then begin
        supported_coords = ['dsi','gse','gsm','sm']
    endif else if resolution eq '256hz' then begin
        supported_coords = ['dsi','gse','gsm','sm','sgi']
    endif else if resolution eq '64hz' then begin
        supported_coords = ['dsi','gse','gsm','sm','sgi']        
    endif else if resolution eq '128hz' then begin
        supported_coords = ['dsi','gse','gsm','sm','sgi'] 
    endif else begin
        errmsg = 'Unkown resolution ...'
        return, retval
    endelse
    index = where(supported_coords eq coord, count)
    coord_is_supported = count ne 0
    
    
    if coord_is_supported then begin
        coord_orig = coord
    endif else begin
        coord_orig = 'gsm'
    endelse
    files = arase_load_mgf(time_range, errmsg=errmsg, id='l2%'+resolution, coord=coord_orig)
    if errmsg ne '' then return, retval


    var_list = list()
    orig_var = prefix+'b_'+coord_orig
    var_list.add, dictionary($
        'in_vars', ['mag_'+resolution+'_'+coord_orig], $
        'out_vars', [orig_var], $
        'time_var_type', 'tt2000')
    
    
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    get_data, orig_var, times, vec_orig
    index = where(snorm(vec_orig) ge 1e30, count)
    if count ne 0 then begin
        vec_orig[index,*] = !values.f_nan
        store_data, orig_var, times, vec_orig
    endif

    if coord ne coord_orig then begin
        get_data, orig_var, times, vec_orig, limits=lim
        vec_coord = cotran(vec_orig, times, coord_orig+'2'+coord)
        store_data, var, times, vec_coord, limits=lim
    endif

    add_setting, var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', 'nT', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )
    
    return, var

end


time_range = ['2017-05-20','2017-05-21']
b_var = arase_read_bfield(time_range, coord='gsm')

end