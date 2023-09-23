;+
; Themis SSL to DSL.
;
; SSL (Spin Sun L-vectorZ coord)
; DSL (Despun Sun L-vectorZ coord)
;
; Adpoted from ssl2dsl in spedas.
;-

function themis_ssl2themis_dsl, vec_ssl, times, probe=probe, errmsg=errmsg

    errmsg = ''
    retval = !null
    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif

    ; Get spin phase and period.
    time_range = minmax(times)+[-1,1]*themis_get_spin_period()
    spin_phase_var = themis_read_spin_phase(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    spin_phase = get_var_data(spin_phase_var, times=uts)
    spin_period_var = themis_read_spin_period(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    spin_period = get_var_data(spin_period_var)

    ; Interpolate to wanted times.
    spin_phase = spin_phase_interpol_pro(spin_phase, spin_period, uts, times)*constant('rad')

    ; Do conversion.
    cosp = cos(spin_phase)
    sinp = sin(spin_phase)

    vec_dsl = double(vec_ssl)
    vec_dsl[*,0] = vec_ssl[*,0]*cosp - vec_ssl[*,1]*sinp
    vec_dsl[*,1] = vec_ssl[*,0]*sinp + vec_ssl[*,1]*cosp

    return, vec_dsl

end