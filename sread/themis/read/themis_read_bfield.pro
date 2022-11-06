function themis_read_bfield, input_time_range, id=datatype, probe=probe, errmsg=errmsg, coord=coord, get_name=get_name, _extra=ex


    prefix = 'th'+probe+'_'
    errmsg = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'b_'+coord
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = themis_load_fgm(time_range, probe=probe, id='l2')


;---Read data.
    if n_elements(datatype) eq 0 then datatype = 'fgs'
    var_list = list()
    in_vars = prefix+[datatype+'_gsm','fgm_'+datatype+'_quality']
    out_vars = prefix+['b_gsm','fgm_'+datatype+'_quality']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix+datatype+'_time', $
        'time_var_type', 'unix' )
    time_step = (datatype eq 'fgs')? 3d: 8e-3
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''



;---Calibrate the data.
    ; Convert to wanted coord.
    if coord ne 'gsm' then begin
        get_data, prefix+'b_gsm', times, vec_gsm, limits=lim
        vec_coord = cotran(vec_gsm, times, 'gsm2'+coord)
        store_data, var, times, vec_coord, limits=lim
    endif

    add_setting, var, smart=1, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: strupcase(coord), $
        coord_labels: constant('xyz') }

    ; To uniform time.
    uniform_time, var, time_step
    flag_var = prefix+'fgm_'+datatype+'_quality'
    uniform_time, flag_var, time_step

    ; Remove data out of normal range.
    get_data, var, times, vec_coord
    index = where(snorm(vec_coord) ge 4e4, count)
    if count ne 0 then begin
        vec_coord[index,*] = !values.f_nan
        store_data, var, times, vec_coord
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
        for ii=0, nbad_time-1 do vec_coord[lazy_where(times,'[]',reform(bad_times[ii,*])),*] = !values.f_nan
        store_data, var, times, vec_coord
    endif

    return, var
end


probe = 'a'
time_range = ['2008-01-19','2008-01-20']
var = themis_read_bfield(time_range, probe=probe)
end