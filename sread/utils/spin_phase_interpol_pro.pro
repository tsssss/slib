;+
; This interpolation uses spin phase and spin period at low-res to get sun pulse times and then use the latter to inteprolate to higher time resolution.
;
; Adopted from thm_spin_phase and thm_sunpulse. But I updated the algorithm.
;
; The basic idea of my update is to use the fact that all sun pulses occur at spin phase mod 360 eq 0, i.e., when spin phase is multiple of 360 deg. Therefore, the steps are:
; 1. Get the sun pulse times at given times (60 sec cadence).
; 2. Calculate how many spins are in between.
; 3. Get the integrated # of spin at each given time.
; 4. Now we know how many spins there should be in the entire time range.
;    We interpolate the given time to times correspond to all integer spins.
;    This is the sunpulse times we wanted.
; 5. Once we get the sunpulse times, then it's easy to interpolate and get the full spin period and spin phase at the wanted times.
;-

function spin_phase_interpol_pro, spin_phase, spin_period, times, wanted_times

    ; Get the sun pulse times at given times.
    ; This is when the sensor passes the Sun and when phase mod 360 eq 0.
    known_sp_times = times-spin_phase/360*spin_period   ; in [ntime]
    nsector = n_elements(known_sp_times)-1

    ; Calculate how many spins are in between given times.
    dspins = (known_sp_times[1:nsector]-known_sp_times[0:nsector-1])/(spin_period[1:nsector]+spin_period[0:nsector-1])*2        ; in [ntime-1].

    ; Integrate to get spin counts at given times.
    spin_counts = [0,dspins]    ; in [ntime].
    for ii=0,nsector-1 do spin_counts[ii+1] = spin_counts[ii]+dspins[ii]

    ; Check consistency.
    exact_spin_counts = round(spin_counts)
    err = spin_counts-exact_spin_counts
    index = where(err le 0.1, count)
    if count eq 0 then begin
        errmsg = 'Something wrong with the spin phase and/or spin period ...'
        return, retval
    endif
    exact_spin_counts = exact_spin_counts[index]
    excat_sunpulse_times = known_sp_times[index]

    ; Interpolate to full sun pulse times.
    full_spin_counts = findgen(max(exact_spin_counts))
    sunpulse_times = interpol(excat_sunpulse_times, exact_spin_counts, full_spin_counts)
    sunpulse_spin_period = interpol(spin_period, times, sunpulse_times)

    ; Calculate the spin period and phase at full sun pulse times.
    exact_spin_phases = exact_spin_counts*360
    wanted_spin_phase = interpol(exact_spin_phases, excat_sunpulse_times, wanted_times)
    
    return, wanted_spin_phase
end

