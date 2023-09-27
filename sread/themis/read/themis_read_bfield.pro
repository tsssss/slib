;+
; Read Themis DC B field.
;
; id=. 'fgs','fgh','fgl'. Default is 'fgl'.
;-
function themis_read_bfield, input_time_range, id=datatype, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, update=update, _extra=ex


    errmsg = ''
    retval = ''

    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'

    ; Prepare var name.
    default_coord = 'gsm'
    if n_elements(coord) eq 0 then coord = default_coord
    vec_coord_var = prefix+'b_'+coord
    if keyword_set(get_name) then return, vec_coord_var
    if keyword_set(update) then del_data, vec_coord_var
    

    ; Load files.
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    files = themis_load_fgm(time_range, probe=probe, id='l2', errmsg=errmsg)
    if errmsg ne '' then return, retval

    datatype = (keyword_set(datatype))? strlowcase(datatype): 'fgl'
    case datatype of
        'fgs': time_step = 3d       ; Spin resolution.
        'fgl': time_step = 1d/4     ; Low resolution.
        'fge': time_step = 1d/8     ; Engineering mode.
        'fgh': time_step = 1d/128   ; High resolution.
    endcase



;---Read data.
    var_list = list()
    in_vars = prefix+[datatype+'_'+default_coord,'fgm_'+datatype+'_quality']
    out_vars = prefix+['b_'+default_coord,'fgm_'+datatype+'_quality']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix+datatype+'_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    add_setting, out_vars[0], id='bfield', dictionary($
        'requested_time_range', time_range, $
        'coord', default_coord )


;---Calibrate the data.
    ; Convert to wanted coord.
    if coord ne 'gsm' then begin
        get_data, prefix+'b_gsm', times, vec_gsm, limits=lim
        vec_coord = cotran_pro(vec_gsm, times, 'gsm2'+coord, probe=probe)
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, id='bfield', dictionary($
        'requested_time_range', time_range, $
        'coord', coord )

    ; To uniform time.
    uniform_time, vec_coord_var, time_step
    flag_var = prefix+'fgm_'+datatype+'_quality'
    uniform_time, flag_var, time_step

    ; Remove data out of normal range.
    get_data, vec_coord_var, times, vec_coord
    index = where(snorm(vec_coord) ge 4e4, count)
    if count ne 0 then begin
        vec_coord[index,*] = !values.f_nan
        store_data, vec_coord_var, times, vec_coord
    endif

    ; Flags for bad data.
    ; Looks like: 2 for eclipse, 1 for commisional phase.
    pad = 120.  ; sec.
    flag_time = time_double('2007-01-14')

    get_data, flag_var, times, flags
    ntime = n_elements(times)
    all_flags = bytarr(ntime)+1
    
    index = where(times lt flag_time and flags gt 1, count)
    if count ne 0 then all_flags[index] = 0
    index = where(times le flag_time and flags gt 0, count)
    if count ne 0 then all_flags[index] = 0
    
    
    index = where(all_flags eq 0, count)
    if count ne 0 then begin
        bad_times = time_to_range(times[index], time_step=time_step)
        bad_times[*,0] -= pad
        bad_times[*,1] += pad
        nbad_time = n_elements(bad_times)/2
        for ii=0, nbad_time-1 do vec_coord[where_pro(times,'[]',reform(bad_times[ii,*])),*] = !values.f_nan
        store_data, vec_coord_var, times, vec_coord
    endif

    return, vec_coord_var
end


probe = 'a'
time_range = ['2008-01-19','2008-01-20']
var = themis_read_bfield(time_range, probe=probe)
end