;+
; Read spacecraft potential in V.
;-

function polar_read_vsc_sdt, input_time_range, polar=polar, errmsg=errmsg, $
    get_name=get_name, update=update, suffix=suffix, _extra=ex

    prefix = 'po_'
    errmsg = ''
    retval = ''

;---Preparation
    if n_elements(suffix) eq 0 then suffix = ''
    var = prefix+'vsc'+suffix
    if keyword_set(get_name) then return, var
    if keyword_set(update) then del_data, var
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var

    ; Load files.
    files = polar_ld_ebv(time_range, errmsg=errmsg)
    if errmsg ne '' then return, retval

stop

;---Read data.
    var_list = list()
    in_vars = 'vsc_uvw'
    out_vars = prefix+in_vars
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    vsc_uvw_var = 'po_vsc_uvw'
    get_data, vsc_uvw_var, times, vsc_uvw
    vsc_var = 'po_vsc'
    store_data, vsc_var, times, vsc_uvw[*,0]
    add_setting, vsc_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'Vsc', $
        'unit', 'V' )



end

time_range = time_double(['2007-09-25','2007-09-27'])
time_range = time_double('2006-09-25')+[0,86400d]
time_range = time_double(['2006-09-20','2006-09-30'])
secofday = 86400d
time_range = time_double('2006-03-01')+[0,5*secofday]
time_range = time_double(['1996-09-14','1996-09-16'])
vsc_var = polar_read_vsc_sdt(time_range)
polar_read_density, time_range
polar_read_orbit, time_range
tplot, ['po_vsc','po_ele_n','po_pos_gsm'], trange=time_range
end
