;+
; Read DC B field from L1 data.
; 
; type can be magi_survey, mago_survey.
;-
;

pro spp_read_bfield_l1, time0, type, remove_offset=remove_offset

    time = time0
    if n_elements(type) eq 0 then type = 'magi_survey'
    xyz = ['x','y','z']
    
    vars = ['time_unix','avg_period_raw','range_bits',$
        'mag_bx_2d','mag_by_2d','mag_bz_2d']
    spp_read_fields, time, type, level='l1', errmsg=errmsg, variable=vars
    
    vars = ['time_unix','mag_'+xyz+'test']
    spp_read_fields, time, strmid(type,0,4)+'_hk', level='l1', errmsg=errmsg, variable=vars
    

    get_data, 'avg_period_raw', data=d_ppp
    get_data, 'range_bits', data=d_range_bits
    
    times_2d = d_ppp.x
    times_1d = list()
    ;range_bits_1d = []
    ;packet_index = []
    
    foreach time, times_2d, ind do begin
        ppp = d_ppp.y[ind]
        navg = 2l^ppp
        
        ; If the number of averages is less than 16, then
        ; there are 512 vectors in the packet.  Otherwise, there
        ; are fewer (See FIELDS CTM)
        if navg lt 16 then begin
            nvec = 512l
            nseconds = 2l*navg
        endif else begin
            nvec = 512l/2l^(ppp-3)
            nseconds = 16l
        endelse
        
        ; rate = Vectors per NYS
        rate = 512l / (2l^(ppp+1))
        
        ; (2.^25 / 38.4d6) is the FIELDS NYS
        ; 512 vectors with no averaging yields 256 vectors per NYS
        timedelta = dindgen(nvec) / rate * (2.^25/38.4e6)
        times_1d.add, list(time+timedelta,/extract), /extract
;        packet_index = [packet_index, dindgen(nvec)]
        
        ; There are 2 range bits per second, left justified
        ; in a 32 bit range_bit item.  Depending on the averaging
        ; period, there can be 2, 4, 8, or 16 seconds worth of data
        ; in the packet, yielding 4, 8, 16, or 32 range bits.
        ; The data item is always 32 bits long.  If there are fewer than
        ; 32 range bits required for the length of the packet,
        ; the first 2 * (# of seconds) bits are used and the
        ; remainder are zero filled.
;        range_bits_i = d_range_bits.y[ind]
;        range_bits_str = string(range_bits_i, format = '(b032)')
;        range_bits_list = []
;        for j=0, nseconds-1 do begin
;            range_bits_int_j = 0
;            range_bits_str_j = strmid(range_bits_str, j*2, 2)
;            reads, range_bits_str_j, range_bits_int_j, format = '(B)'
;            range_bits_arr_j = lonarr(rate) + range_bits_int_j
;            range_bits_list = [range_bits_list,range_bits_arr_j]
;        endfor
;        range_bits_1d = [range_bits_1d, range_bits_list]
    endforeach
    
    times_1d = times_1d.toarray()
    vars = 'mag_b'+xyz+'_2d'
    nrec = n_elements(times_1d)
    dat = fltarr(nrec,3)
    foreach var, vars, j do begin
        get_data, var, data=d_b_2d
        dat[*,j] = reform(transpose(d_b_2d.y), n_elements(d_b_2d.y))
    endforeach
    
    ; convert to nT.
    dat *= 0.03125
    if keyword_set(remove_offset) then begin
        for i=0, 2 do dat[*,i] -= mean(dat[*,i],/nan)
    endif
    
    ; flip sign for magi.
    if type eq 'magi_survey' then dat[*,1:2] = -dat[*,1:2]
    
    var = 'spp_b_xyz'
    store_data, var, times_1d, dat
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: 'XYZ', $
        coord_labels: xyz, $
        colors: [6,4,2]}

end

utr0 = time_double(['2018-09-20','2018-09-21'])
spp_read_bfield_l1, utr0, 'magi_survey'

end