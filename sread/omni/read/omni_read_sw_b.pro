;+
; Read omni solar wind parameters.
;-

function omni_read_sw_b, input_time_range, errmsg=errmsg, get_name=get_name, coord=coord, _extra=ex

    errmsg = ''
    retval = ''

    prefix = 'omni_'
    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'sw_b_'+coord
    if keyword_set(get_name) then return, var
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var


    if n_elements(resolution) eq 0 then resolution = '1min'
    files = omni_load(time_range, errmsg=errmsg, id='cdaweb%hro%'+resolution)
    if errmsg ne '' then return, retval



    in_vars = ['BX_GSE','BY_GSM','BZ_GSM']
    coord_orig = 'gsm'
    var_list = list()
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'time_var_type', 'epoch', $
        'time_var_name', 'Epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    get_data, in_vars[0], times
    ntime = n_elements(times)
    ndim = 3
    vec_orig = fltarr(ntime,ndim)
    xyz = constant('xyz')
    for ii=0,ndim-1 do begin
        vec_orig[*,ii] = get_var_data(in_vars[ii])
    endfor
    
    ; Remove fillval.
    vatts = cdf_read_setting(in_vars[0], filename=files[0])
    fillval = vatts['FILLVAL']
    index = where(abs(vec_orig) ge fillval, count)
    if count ne 0 then begin
        vec_orig[index] = !values.f_nan
    endif

    if strlowcase(coord) ne coord_orig then begin
        vec_coord = cotran(vec_orig, times, strlowcase(coord_orig+'2'+coord), _extra=ex)
    endif else begin
        vec_coord = temporary(vec_orig)
    endelse

    store_data, var, times, vec_coord
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'SW B', $
        'coord', strupcase(coord), $
        'coord_labels', xyz )
    return, var


end


time_range = ['2019-01-01','2019-01-02']
var = omni_read_sw_b(time_range)
end