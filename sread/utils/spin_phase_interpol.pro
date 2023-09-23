;+
; This works when times are denser than the spin period.
; Otherwise, we need both spin phase and spin period data at given times to interpolate the spin phase to the wanted times. The latter is done in spin_phase_interpol_pro.
;-

function spin_phase_interpol, spin_phase, times, wanted_times

    new_sp = interpol(double(spin_phase), times, wanted_times)

    ntime = n_elements(times)
    boundary_index = where((spin_phase[1:ntime-1]-spin_phase[0:ntime-2]) lt 0, nboundary)
    for ii=0,nboundary-1 do begin
        i0 = boundary_index[ii]
        the_time = times[i0:i0+1]
        index = where_pro(wanted_times, '[]', the_time, count=count)
        if count eq 0 then continue
        the_data = spin_phase[i0:i0+1]+[0,360]
        new_sp[index] = interpol(the_data, the_time, wanted_times[index])
    endfor

    return, new_sp

end