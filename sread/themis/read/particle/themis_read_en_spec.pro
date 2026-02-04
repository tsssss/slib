;+
; A wrapper.
; ids=. can be integrate, esa_l2.
;-
function themis_read_en_spec, input_time_range, probe=probe, errmsg=errmsg, $
    species=species0, get_name=get_name, ids=ids

    if n_elements(ids) eq 0 then id0 = 'integrate' else id0 = ids[0]
    routine = 'themis_read_en_spec_'+id0
    return, call_function(routine, input_time_range, probe=probe, errmsg=errmsg, $
        species=species0, get_name=get_name, ids=ids[1:*])

end