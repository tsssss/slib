;+
; Make a variable's time uniform in data rate.
; 
; var. A string of variable name.
; dt. Data rate. By default, times are used to find the median data rate.
;-

pro uniform_time, var, dt
    
    if tnames(var) eq '' then return
    get_data, var, times
    ntime = n_elements(times)
    if ntime eq 0 then return
    if times[0] eq 0 then return
    
    if n_elements(dt) eq 0 then dt = sdatarate(times)
    dtime = times[1:ntime-1]-times[0:ntime-2]
    if min(dtime) eq dt and max(dtime) eq dt then return
    
    t0 = times[0]
    t1 = times[ntime-1]
    t0 = t0-(t0 mod dt)
    t1 = t1-(t1 mod dt)
    if t1 ne times[ntime-1] then t1 += dt
    
    times = smkarthm(t0,t1,dt, 'dx')
    interp_time, var, times
end