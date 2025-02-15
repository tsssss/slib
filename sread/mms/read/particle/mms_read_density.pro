;+
; Read density.
; input_time_range,
; probe=.
; id=. 'fpi'. Default is 'fpi'
;-

function mms_read_density, input_time_range, probe=probe, id=id, errmsg=errmsg, $
    suffix=suffix, get_name=get_name, update=update

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(id) eq 0 then id = 'fpi'
    supported_ids = ['fpi']
    index = where(supported_ids eq id, count)
    if count eq 0 then begin
        errmsg = 'Invalid id: '+id+' ...'
        return, retval
    endif

    if n_elements(suffix) eq 0 then suffix = ''
    routine = 'mms_read_density_'+id
    return, call_function(routine, input_time_range, probe=probe, errmsg=errmsg, $
        suff=suffix, get_name=get_name, update=update)

end