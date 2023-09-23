;+
; A wrapper.
; id=. can be integrate, esa_l2.
;-
function themis_read_en_spec, input_time_range, probe=probe, errmsg=errmsg, $
    species=species0, get_name=get_name

    if n_elements(id) eq 0 then id = 'integrate'
    routine = 'themis_read_en_spec_'+id
    return, call_function(routine, input_time_range, probe=probe, errmsg=errmsg, $
        species=species0, get_name=get_name)

end