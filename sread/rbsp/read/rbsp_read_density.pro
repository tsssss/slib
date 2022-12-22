;+
; Read HOPE density.
;-

function rbsp_read_density, input_time_range, probe=probe, id=id, errmsg=errmsg

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(id) eq 0 then id = 'hope'
    supported_ids = ['emfisis','hope','efw']
    index = where(supported_ids eq id, count)
    if count eq 0 then begin
        errmsg = 'Invalid id: '+id+' ...'
        return, retval
    endif

    routine = 'rbsp_read_density_'+id
    return, call_function(routine, input_time_range, probe=probe, errmsg=errmsg)

end

time_range = time_double(['2013-06-07','2013-06-08'])
probe = 'a'
rbsp_read_density, time_range, probe=probe
end