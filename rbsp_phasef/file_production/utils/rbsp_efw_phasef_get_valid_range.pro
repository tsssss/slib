;+
; Return the valid range for certain data_type and probe.
;
; data_type. A string for the data type.
; probe=probe. A string 'a' or 'b'.
;-

function phasef_get_valid_range_string, data_type, probe=probe


;---L1 data.
    if data_type eq 'vsvy_l1' then begin
        ; vsvy and esvy L1 data do not share the same time tag, but available in the same date range.
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-14/24:00'] ; 2019-10-14 is the last day has data.
        endif else begin
            return, ['2012-09-05','2019-07-16/24:00'] ; 2019-07-16 is the last day has data.
        endelse
    endif else if data_type eq 'esvy_l1' then begin
        return, phasef_get_valid_range_string('vsvy_l1', probe=probe)
    endif else if data_type eq 'density_uh' then begin
        return, phasef_get_valid_range_string('vsvy_l1', probe=probe)
    endif else if data_type eq 'e_uvw' then begin   ; e_uvw_diagonal is the same.
        return, phasef_get_valid_range_string('vsvy_l1', probe=probe)
            
;---Intermediate data.    
    endif else if data_type eq 'spice' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-14/24:00'] ; 2019-10-14 is the last day spice_var can be generated.
        endif else begin
            return, ['2012-09-05','2019-07-16/24:00'] ; 2019-07-16 is the last day spice_var can be generated.
        endelse
    endif else if data_type eq 'orbit_num' then begin
        return, phasef_get_valid_range_string('spice', probe=probe)
    endif else if data_type eq 'spinaxis_gse' then begin
        return, phasef_get_valid_range_string('spice', probe=probe)
    endif else if data_type eq 'boom_property' then begin
        return, phasef_get_valid_range_string('spice', probe=probe)
    endif else if data_type eq 'pos_var' then begin
        return, phasef_get_valid_range_string('spice', probe=probe)
    endif else if data_type eq 'sunpulse_time' then begin
        ; spin period and spin phase are only available from 2012-09-08.
        if probe eq 'a' then begin
            return, ['2012-09-08','2019-10-14/24:00'] ; 2019-10-14 is the last day has data.
        endif else begin
            return, ['2012-09-08','2019-07-16/24:00'] ; 2019-07-16 is the last day has data.
        endelse
    
    endif else if data_type eq 'e_fit' then begin
        if probe eq 'a' then begin
            return, ['2012-09-08','2019-10-14/24:00'] ; 2019-10-14 is the last day has data.
        endif else begin
            return, ['2012-09-08','2019-07-16/24:00'] ; 2019-07-16 is the last day has data.
        endelse
    
    endif else if data_type eq 'b_mgse' then begin
        ; spin period and spin phase are only available from 2012-09-08.
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-14/24:00'] ; 2019-10-14 is the last day has data.
        endif else begin
            return, ['2012-09-05','2019-07-16/24:00'] ; 2019-07-16 is the last day has data.
        endelse
        
        
    endif else if data_type eq 'wobble_free_var' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-14/24:00'] ; 2019-10-14 is the last day has data.
        endif else begin
            return, ['2012-09-05','2019-07-16/24:00'] ; 2019-07-16 is the last day has data.
        endelse
    endif else if data_type eq 'e_model' then begin
        return, phasef_get_valid_range_string('wobble_free_var', probe=probe)
        
  
    endif else if data_type eq 'e_spinfit' then begin
        if probe eq 'a' then begin
            ; Start from 2012-09-23, after all spin-plane booms are fully deployed.
            return, ['2012-09-23','2019-02-23/24:00']
        endif else begin
            return, ['2012-09-23','2019-07-16/24:00']
        endelse
    endif else if data_type eq 'e_spinfit_p4' then begin
        if probe eq 'a' then begin
            return, ['2012-09-13','2019-10-14/24:00']
        endif else begin
            return, ['2012-09-13','2019-07-16/24:00']
        endelse
        
;---Flags.
    endif else if data_type eq 'flags_all' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-14/24:00']
        endif else begin
            return, ['2012-09-05','2019-07-16/24:00']
        endelse
    endif else if data_type eq 'efw_qual' then begin
        return, phasef_get_valid_range_string('flags_all', probe=probe)
        
;---HSK data.   
    endif else if data_type eq 'hsk' then begin
        if probe eq 'a' then begin
            return, ['2012-09-14','2019-10-14/24:00']
        endif else begin
            return, ['2012-09-14','2019-07-16/24:00']
        endelse
        
;---L2 data.
    endif else if data_type eq 'vsvy_hires' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-14/24:00']
        endif else begin
            return, ['2012-09-05','2019-07-16/24:00']
        endelse
    endif else if data_type eq 'e_hires_uvw' then begin
        if probe eq 'a' then begin
            return, ['2012-09-23','2019-02-23/24:00']
        endif else begin
            return, ['2012-09-23','2019-07-16/24:00']
        endelse
    endif else if data_type eq 'esvy_despun' then begin
        return, phasef_get_valid_range_string('e_hires_uvw', probe=probe)

        
    endif else if data_type eq 'spec' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-12/24:00']
        endif else begin
            return, ['2012-09-05','2019-07-14/24:00']
        endelse
    endif else if data_type eq 'fbk' then begin
        return, phasef_get_valid_range_string('spec', probe=probe)


    endif else if data_type eq 'vb1' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-10/24:00']
        endif else begin
            return, ['2012-09-05','2019-07-16/24:00']
        endelse
    endif else if data_type eq 'mscb1' then begin
        return, phasef_get_valid_range_string('vb1', probe=probe)
    endif else if data_type eq 'eb1' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2013-10-09/24:00']
        endif else begin
            return, ['2012-09-05','2013-12-20/24:00']
        endelse
    endif else if data_type eq 'vb2' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-14/24:00']
        endif else begin
            return, ['2012-09-05','2019-07-16/24:00']
        endelse
    endif else if data_type eq 'mscb2' then begin
        return, phasef_get_valid_range_string('vb2', probe=probe)
    endif else if data_type eq 'eb2' then begin
        return, phasef_get_valid_range_string('vb2', probe=probe)
    
    
    
    endif else if data_type eq 'diag_var' then begin
        if probe eq 'a' then begin
            return, ['2012-09-13','2019-02-23']
        endif else begin
            return, ['2012-09-13','2019-07-17']
        endelse
    endif

    message, 'Invalid data type ...'
    return, !null
end


function rbsp_efw_phasef_get_valid_range, data_type, probe=probe
    return, time_double(phasef_get_valid_range_string(data_type, probe=probe))
end
