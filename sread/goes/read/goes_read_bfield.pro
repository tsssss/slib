;+
; Read GOES B in GSM. Save as 'gxx_b_gsm'.
; 
; input_time_range. A time or a time range in ut sec.
; probe. A string sets the probe, e.g., '13','15'.
;
; Need spedas to run.
;-
;
function goes_read_bfield, input_time_range, probe=probe, coord=coord, $
    resolution=resolution, errmsg=errmsg, update=update, _extra=ex

    compile_opt idl2
    errmsg = ''
    retval = !null
    
    resolution = (keyword_set(resolution))? strlowcase(resolution): '512ms'
    case resolution of
        '512ms': dt = 0.512d
        '1min': dt = 60d
        '5min': dt = 300d
    endcase

    time_range = time_double(input_time_range)
    default_coord = 'gsm'
    if n_elements(coord) eq 0 then coord = default_coord
    prefix = 'g'+probe+'_'
    var_info = prefix+'b_'+coord
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    if ~check_if_update(var_info, time_range) then return, var_info
    
    ; read 'gxx_b_gsm'
    goes_read_bfield_cdaweb, time_range, probe=probe, errmsg=errmsg, coord=default_coord
    if errmsg ne '' then begin
        goes_read_fgm, time_range, probe=probe, coord=default_coord, id=resolution, errmsg=errmsg, _extra=ex
    endif
    if errmsg ne '' then return, retval
    
    if coord ne default_coord then begin
        var_default = prefix+'b_'+default_coord
        b_default = var_get_data(var_default, times, settings=settings)
        b_coord = cotran_pro(b_default, times, coord_msg=[default_coord,coord])
        var_info = var_store(var_info, b_coord, times, settings=settings)
    endif
    add_setting, var_info, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', strupcase(coord), $
        'coord_labels', ['x','y','z'])
    return, var_info

end

time = time_double(['2014-08-28/09:30','2014-08-28/11:00'])
probe = '13'

; Bad data.
time = time_double(['2019-03-07/00:00','2019-03-08/00:00'])
probe = '15'

; Test.
time = time_double(['2008-03-14/00:00','2008-03-15/00:00'])
probe = '13'


time = time_double(['2008-02-29/08:00','2008-02-29/10:00'])
probe = '10'


var = goes_read_bfield(time, probe=probe)
end