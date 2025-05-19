;+
; Check times when both B1 and B2 are available but at different cadence.
; 
; 
; As of 2021-10-19. The time tags are fixed in v03 of the split files.
; So now if one runs this program, the 'original' time tags are correct, whereas the shifted time tags are off.
;-



probes = ['a','b']
root_dir = '/Users/shengtian/Projects/idl/spacephys/topics/rbsp_phasef/file_production/utils'
foreach probe, probes do begin
    ; Read B1 data info.
    base = 'burst1_times_rates_RBSP'+probe+'.sav'
    file = join_path([root_dir,base])
    restore, file

    nsec = n_elements(d0)
    b1_trs = dblarr(nsec,2)
    b1_trs[*,0] = time_double(d0)
    b1_trs[*,1] = time_double(d1)
    b1_drs = sr
    b1_nsec = nsec


    ; Read B2 data info.
    base = 'burst2_times_RBSP'+probe+'.sav'
    file = join_path([root_dir,base])
    restore, file
    nsec = n_elements(d0)
    b2_trs = dblarr(nsec,2)
    b2_trs[*,0] = time_double(d0)
    b2_trs[*,1] = time_double(d1)
    b2_dr = 16384.
    b2_nsec = nsec

    start_time = time_double('2012-10-01')
    for sec_id=0,b1_nsec-1 do begin
        b1_tr = reform(b1_trs[sec_id,*])
        if b1_tr[0] lt start_time then continue
        tmp = where(b2_trs[*,1] gt b1_tr[0] and b2_trs[*,0] lt b1_tr[1], count)
        if count eq 0 then continue
        b1_dr = b1_drs[sec_id]
        foreach index, tmp do begin
            b2_tr = reform(b2_trs[index,*])
            tr = [max([b1_tr[0],b2_tr[0]]),min([b1_tr[1],b2_tr[1]])]
            dur = total(tr*[-1,1])
            if dur lt 5 then continue
            if b1_dr eq b2_dr then continue
            if round(b1_dr) lt 4096 then continue
            print, 'TR: '+strjoin(time_string(tr),',')
            print, 'RBSP-'+strupcase(probe)
            print, 'B1: '+strjoin(time_string(b1_tr),',')
            print, 'B2: '+strjoin(time_string(b2_tr),',')
            print, 'B1 (S/s): '+string(b1_dr)
            print, 'B2 (S/s): '+string(b2_dr)
            
            
            
            ;time_range = time_double(['2012-10-01/00:03:12','2012-10-01/00:03:17'])
            ;probe = 'a'
            time_range = tr
            prefix = 'rbsp'+probe+'_efw_'
            boom_id = 1
            boom_str = string(boom_id+1,format='(I0)')
            dtypes = ['vb1','vb2']
            foreach dtype, dtypes do begin
                rbsp_efw_read_burst, time_range, probe=probe, datatype=dtype
                var = prefix+dtype
                get_data, var, times, data
                store_data, var+'_v'+boom_str, times, data[*,boom_id], limits={labels:'V'+boom_str, ysubtitle:'[V]'}
            endforeach

            tplot_options, 'ynozero', 1
            tplot_options, 'version', 1
            tplot_options, 'labflag', -1
            vars = prefix+dtypes
            foreach var, vars do begin
                get_data, var, times, data
                the_var = var+'_v'+boom_str
                store_data, the_var, times, data[*,boom_id]
                time_step = sdatarate(times)
                store_data, the_var+'_shift', times-time_step, data[*,boom_id]
            endforeach
           

            vars = prefix+dtypes+'_v'+boom_str
            vars = [vars,vars+'_shift']
            options, vars, 'psym', -1
            sgopen, 0, xsize=8, ysize=5
            tpos = sgcalcpos(n_elements(vars), margins=[15,4,4,2])
            
            plot_tr = time_double('2012-11-08/15:28')+[11.1,11.11]
            tplot, vars, trange=plot_tr, position=tpos
            stop
            
            interp_time, prefix+'vb1_v'+boom_str, to=prefix+'vb2_v'+boom_str
            stplot_merge, prefix+dtypes+'_v'+boom_str, newname=prefix+'_v'+boom_str, $
                labels=dtypes, colors=sgcolor(['blue','red'])
            options, prefix+'_v'+boom_str, 'ytitle', prefix+'V'+boom_str+'_[V]'

            interp_time, prefix+'vb1_v'+boom_str+'_shift', to=prefix+'vb2_v'+boom_str+'_shift'
            stplot_merge, prefix+dtypes+'_v'+boom_str+'_shift', newname=prefix+'_v'+boom_str+'_shift', $
                labels=dtypes, colors=sgcolor(['blue','red'])
            options, prefix+'_v'+boom_str+'_shift', 'ytitle', prefix+'V'+boom_str+'_[V]_shift'

            vars = prefix+'_v'+boom_str+['','_shift']
            foreach var, vars do begin
                get_data, var, times, data
                index = where_pro(times, '[]', plot_tr)
                foreach val, data[0,*], val_id do data[*,val_id] -= mean(data[index,val_id],/nan)
                store_data, var, times, data
            endforeach
            options, vars, 'psym', -1
            sgopen, 1, xsize=8, ysize=5
            tpos = sgcalcpos(n_elements(vars), margins=[15,4,4,2])
            tplot, vars, trange=plot_tr, position=tpos
            
            stop
        endforeach
    endfor
endforeach


end
