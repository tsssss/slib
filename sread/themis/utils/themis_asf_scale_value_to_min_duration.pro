;+
; An empirical adaptive threshold to exclude fluctuations due to aurora:
; 1. Short duration fluctuations (several min) like auroral streamers.
; 2. Longer duration fluctuations (several 10 min) like the stable arcs.
;
; Check test_themis_asf_scale_value_to_duration.
;-

function themis_asf_scale_value_to_min_duration, xxs
;    return, 1e3/(xxs/1e4)^3.5
;    return, 0.5e3/(xxs/1e4)^2.5 ; v05
;    return, 0.5e3/(xxs/1e4)^2 ; v06
    return, 0.5e3/(xxs/0.75e4)^1.5 ; v08
end