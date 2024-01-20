;+
; Read GOES position.
;-

function goes_read_orbit, input_time_range, probe=input_probe, errmsg=errmsg, coord=coord, get_name=get_name, _extra=ex

    probe = goes_resolve_probe(input_probe)
    prefix = 'g'+probe+'_'
    errmsg = ''
    retval = ''
    dt = 60.0

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'r_'+coord
    if keyword_set(get_name) then return, var
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var

    files = goes_load_ssc(time_range, probe=probe)
    if errmsg ne '' then return, retval


    var_list = list()
    orig_var = prefix+'r_gsm'
    var_list.add, dictionary($
        'in_vars', 'XYZ_GSM', $
        'out_vars', orig_var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    if coord ne 'gsm' then begin
        get_data, orig_var, times, r_gsm, limits=lim
        r_coord = cotran(r_gsm, times, 'gsm2'+coord)
        store_data, var, times, r_coord, limits=lim
    endif

    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'short_name', 'R', $
        'unit', 'Re', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )
    
    return, var

end

;    ; read 'xyz_gsm'
;    goes_read_orbit_cdaweb, time_range, probe=probe, coord='gsm', errmsg=errmsg
;    if errmsg ne '' then goes_read_ssc, time_range, id='pos', probe=probe, errmsg=errmsg


var = goes_read_orbit(['2013-05-01','2013-05-02'], probe='15', coord='gsm')

stop

time_range = time_double(['2006-01-01','2007-01-01'])
time_range = time_double(['2016-01-01','2017-01-01'])
time_range = time_double(['2016-12-19','2016-12-21'])
probe = '12'

time_range = time_double(['2006-01-01','2007-01-01'])
probe = '13'

time_range = time_double(['2009-01-01','2010-01-01'])
time_range = time_double(['2009-07-09','2009-07-10'])
time_range = time_double(['2009-07-08','2009-07-09'])
probe = '14'

time_range = time_double(['2010-01-01','2011-01-01'])
probe = '15'

time_range = time_double(['2016-01-01','2017-01-01'])
probe = '16'

time_range = time_double(['2018-01-01','2019-01-01'])
probe = '17'

time_range = time_double(['2008-03-14/06:30','2008-03-14:06:40'])
probe = '13'

var = goes_read_orbit(time_range, probe=probe, coord='sm')
end