;+
; Read RBSP spin phase in deg. Save as 'rbspx_spin_phase'
;
; time. A time or a time range in ut sec.
; probe. A string sets the probe, 'a' or 'b'.
; times=. An array to interpolate to.
; time_step=. The time step to interpolate to.
;-
pro rbsp_read_spin_phase, time, probe=probe, errmsg=errmsg, times=common_times, time_step=time_step

    ; read 'rbspx_spin_phase'.
    rbsp_read_spice, time, id='spin_phase', probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    ; Remove overlapping times.
    prefix = 'rbsp'+probe+'_'
    the_var = prefix+'spin_phase'
    get_data, the_var, times, data
    index = uniq(times, sort(times))
    store_data, the_var, times[index], data[index]
    add_setting, the_var, /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', tex2str('theta') )

    ; Interpolate to new times.
    if n_elements(common_times) eq 0 and n_elements(time_step) eq 0 then return
    if n_elements(common_times) eq 0 then common_times = make_bins(minmax(times), time_step, /inner)

    get_data, the_var, times, data
    ntime = n_elements(times)
    ncommon_time = n_elements(common_times)
    if ntime eq ncommon_time then return
    
    data = double(data)
    spin_phase = interpol(data, times, common_times)

    boundary_index = where((data[1:ntime-1]-data[0:ntime-2]) lt 0, nboundary)
    for ii=0,nboundary-1 do begin
        i0 = boundary_index[ii]
        the_time = times[i0:i0+1]
        index = lazy_where(common_times, '[]', the_time, count=count)
        if count eq 0 then continue
        the_data = data[i0:i0+1]+[0,360]
        spin_phase[index] = interpol(the_data, the_time, common_times[index])
    endfor
    store_data, the_var, common_times, spin_phase


end

time = time_double('2014-08-28')+[0,86400d]
rbsp_read_spin_phase, time, probe=probe, time_step=1d/16
end
