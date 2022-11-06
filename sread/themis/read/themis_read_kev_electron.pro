;+
; Read THEIS keV electron flux. Save as 'thx_kev_e_flux'.
;
; pitch_angle. A dummy keyword.
;-

function themis_read_kev_electron, time_range, probe=probe, errmsg=errmsg, energy_range=energy_range, pitch_angle=pitch_angle, spec=spec

    return, themis_read_kev_flux(time_range, probe=probe, $
        id='e', errmsg=errmsg, spec=spec, energy_range=energy_range)

end

time_range = time_double(['2014-08-28/09:30','2014-08-28/11:30'])
time_range = time_double(['2017-01-01','2017-01-02'])
time_range = time_double(['2013-01-01','2013-01-02'])
probe = 'e'
var = themis_read_kev_electron(time_range, probe=probe, spec=1)
end