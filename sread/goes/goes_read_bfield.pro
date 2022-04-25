;+
; Read GOES B in GSM. Save as 'gxx_b_gsm'.
; 
; utr0. A time or a time range in ut sec.
; probe. A string sets the probe, e.g., '13','15'.
;
; Need spedas to run.
;-
;
pro goes_read_bfield, utr0, probe=probe, coord=coord, $
    resolution=resolution, errmsg=errmsg, _extra=ex

    catch, err
    if err ne 0 then begin
        errmsg = handle_error('Something is wrong ...')
        return
    endif

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
    goes_read_bfield_cdaweb, utr0, probe=probe, errmsg=errmsg, coord='gsm'
    if errmsg ne '' then begin
        goes_read_fgm, utr0, probe=probe, coord='gsm', id=resolution, errmsg=errmsg, _extra=ex
    endif
    if errmsg ne '' then return
    
    pre0 = 'g'+probe+'_'
    if n_elements(coord) eq 0 then coord = 'gsm'
    bvar = pre0+'b_'+coord
    if coord ne 'gsm' then begin
        get_data, pre0+'b_gsm', times, b_gsm, limits=lim
        b_coord = cotran(b_gsm, times, 'gsm2'+coord)
        store_data, bvar, times, b_coord, limits=lim
    endif
    add_setting, bvar, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z']}
        
    ;uniform_time, bvar, dt

end

time = time_double(['2014-08-28/09:30','2014-08-28/11:00'])
probe = '13'

; Bad data.
time = time_double(['2019-03-07/00:00','2019-03-08/00:00'])
probe = '15'

; Test.
time = time_double(['2008-03-14/00:00','2008-03-15/00:00'])
probe = '13'


time = time_double(['2008-02-29/08:00','2008-02-29/10:00'])
probe = '10'


goes_read_bfield, time, probe=probe
end