;+
; Read GOES B in GSM. Save as 'gxx_b_gsm'.
; 
; utr0. A time or a time range in ut sec.
; probe. A string sets the probe, e.g., '13','15'.
;
; Need spedas to run.
;-
;
pro goes_read_bfield, utr0, probe=probe, resolution=resolution, errmsg=errmsg, _extra=ex

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif
    
    resolution = (keyword_set(resolution))? strlowcase(resolution): '512ms'
    case resolution of
        '512ms': dt = 0.512d
        '1min': dt = 60d
        '5min': dt = 300d
    endcase
    
    ; read 'gxx_b_gsm'
    goes_read_fgm, utr0, probe=probe, coord='gsm', resolution=resolution, errmsg=errmsg, _extra=ex
    if errmsg ne '' then return
    

    bvar = pre0+'b_gsm'
    rename_var, 'mag', to=bvar
    add_setting, bvar, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}
        
    uniform_time, bvar, dt

end