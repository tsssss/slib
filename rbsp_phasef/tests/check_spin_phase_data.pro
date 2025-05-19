;+
; Check spin fit data for data gap and invalid data.
;-

probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])
log_file = join_path([homedir(),'rbsp_efw_phasef_check_spin_phase_data_quality.txt'])
ftouch, log_file
tab = '    '
spinphase_range = [0,360d]
spinperiod_range = [8d,12]
ntime0 = 86401

test = 0



;rbspa    2016_0111     # of spin period out of range is 34143
;rbspa    2016_0112     # of spin period out of range is 33640
;rbspa    2016_0622     # of spin period out of range is 29351
;rbspa    2016_0623     # of spin period out of range is 41018

;rbspb    2015_0915     # of spin period out of range is 12601
;rbspb    2015_0916     # of spin period out of range is 39806



foreach probe, probes do begin
;if keyword_set(test) then probe = 'b'

    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = (probe eq 'a')? time_double(['2012-09-08','2019-10-14']): time_double(['2012-09-08','2019-07-16'])
    days = make_bins(time_range, constant('secofday'))
    
    if probe eq 'a' then begin
        days = ['2016-01-11','2016-01-12','2016-06-22','2016-06-23']
    endif else begin
        days = ['2015-09-15','2015-09-16']
    endelse
    
    foreach day, days do begin
;if keyword_set(test) then day = time_double('2015-09-16')
        lprmsg, 'Processing '+time_string(day)+' ...'
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'spice_cdfs',str_year])
        base= 'rbsp'+probe+'_spice_products_'+time_string(day,tformat='YYYY_MMDD')+'_v08.cdf'
        file = join_path([path,base])
        
        msg = rbspx+tab+time_string(day,tformat='YYYY_MMDD')+tab
        
        foreach the_var, prefix+['spin_phase','spin_period'] do begin
            cdf_load_var, the_var, filename=file
        endforeach
        
        get_data, prefix+'spin_phase', times, spinphase
        get_data, prefix+'spin_period', times, spinperiod


;if keyword_set(test) then stop
        ntime = n_elements(times)
        if ntime ne ntime0 then begin
            msg = msg+'# of time is '+string(ntime,format='(I0)')
            lprmsg, msg, log_file
            continue
        endif
        
        index = where_pro(spinphase, ')(', spinphase_range, count=count)
        if count ne 0 then begin
            msg = msg+' # of spin phase out of range is '+string(count,format='(I0)')
            lprmsg, msg, log_file
            continue
        endif
        
        index = where_pro(spinperiod, ')(', spinperiod_range, count=count)
        if count ne 0 then begin
            msg = msg+' # of spin period out of range is '+string(count,format='(I0)')
            lprmsg, msg, log_file
            stop
            continue
        endif
        
        index = where(finite(spinphase,/nan), count)
        if count ne 0 then begin
            msg = msg+' # of NaN spin phase '+string(count,format='(I0)')
            lprmsg, msg, log_file
            continue
        endif
    endforeach
endforeach

end
