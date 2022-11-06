;+
; Read THEIS keV proton flux. Save as 'thx_kev_p_flux'.
;
; pitch_angle. A dummy keyword.
;-

function themis_read_kev_proton, time_range, probe=probe, errmsg=errmsg, energy_range=energy_range, pitch_angle=pitch_angle, spec=spec

    return, themis_read_kev_flux(time_range, probe=probe, $
        id='p', errmsg=errmsg, spec=spec, energy_range=energy_range)

end

time_range = time_double(['2014-08-28/09:30','2014-08-28/11:30'])
time_range = time_double(['2017-01-01','2017-01-02'])
probe = 'a'
var = themis_read_kev_proton(time_range, probe=probe, energy=[0,1000], spec=1)
end
