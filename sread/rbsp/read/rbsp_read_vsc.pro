;+
; Read V_sc.
; Save as rbspx_vsc.
;
; id=. 'spin_plane','median','all'. 'median', by default.
;-

function rbsp_read_vsc, input_time_range, probe=probe, $
    errmsg=errmsg, id=datatype, get_name=get_name

    errmsg = ''
    retval = ''
    on_error, 2     ; return if any error occurred.

    prefix = 'rbsp'+probe+'_'
    out_var = prefix+'vsc'
    if keyword_set(get_name) then return, out_var
    time_range = time_double(input_time_range)
    if ~check_if_update(out_var, time_range) then return, out_var

    if n_elements(datatype) eq 0 then datatype = 'median'
    rbsp_efw_phasef_read_vsvy, time_range, probe=probe
    var = prefix+'efw_vsvy'
    get_data, var, times, vsvy
    index = where_pro(times, '[]', time_range, count=ntime)
    if ntime le 1 then begin
        errmsg = 'No data ...'
        return, retval
    endif
    ntime = n_elements(times)

    
    if datatype eq 'median' then begin
        vsc = fltarr(ntime)
        for ii=0,ntime-1 do begin
            vsc[ii] = median(vsvy[ii,0:3])
        endfor
        store_data, out_var, times, vsc
        add_setting, out_var, smart=1, dictionary($
            'display_type', 'scalar', $
            'short_name', 'Vsc', $
            'unit', 'V', $
            'requested_time_range', time_range )
    endif else if datatype eq 'spin_plane' then begin
        vsc = vsvy[*,0:3]
        store_data, out_var, times, vsc
        add_setting, out_var, smart=1, dictionary($
            'display_type', 'stack', $
            'short_name', 'Vsc', $
            'unit', 'V', $
            'labels', 'V'+['1','2','3','4'], $
            'colors', sgcolor(['red','green','blue','purple']), $
            'requested_time_range', time_range )
    endif else if datatype eq 'all' then begin
        vsc = vsvy
        store_data, out_var, times, vsc
        add_setting, out_var, smart=1, dictionary($
            'display_type', 'stack', $
            'short_name', 'Vsc', $
            'unit', 'V', $
            'labels', 'V'+['1','2','3','4','5','6'], $
            'colors', sgcolor(['red','green','blue','purple','yellow','cyan']), $
            'requested_time_range', time_range )
    endif

        

    return, out_var


end


time_range = time_double(['2014-01-01','2014-01-05'])
time_range = time_double(['2012-12-08','2012-12-09'])
probe = 'a'
var = rbsp_read_vsc(time_range, probe=probe)
end