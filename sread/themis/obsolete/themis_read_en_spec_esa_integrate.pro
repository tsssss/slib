;+
; Read themis en_spec.
;
; This is for esa only.
;-

function themis_read_en_spec_esa_integrate, input_time_range, probe=probe, $
    errmsg=errmsg, id=id, update=update, $
    species=species0, get_name=get_name
    
    id = 'esa'
    return, themis_read_en_spec_integrate(input_time_range, probe=probe, $
        errmsg=errmsg, id=id, update=update, $
        species=species, get_name=get_name)

end

time_range = time_double(['2017-03-09/07:00','2017-03-09/09:00'])
probes = ['d','e']
species = ['e','p']
probes = 'd'
update = 1
id = 'esa_sst'
foreach the_species, species do begin
    foreach probe, probes do begin
        vinfo = themis_read_en_spec_esa_sst_integrate(time_range, probe=probe, $
            species=the_species, id=id, update=update)
        stop
    endforeach
endforeach
end
