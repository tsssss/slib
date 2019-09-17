;+
; Load one variable from one file, load all recs and depend_0.
; Save data to tplot.
; range=. The range of dep_0
;-
pro cdf_load_var, var, range=range, depend=time_var, filename=cdf0, errmsg=errmsg

    errmsg = ''

    ; Check if var is a string.
    if n_elements(var) eq 0 then return
    the_var = var[0]

    ; Check if given file is a cdf_id or filename.
    if n_elements(cdf0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return
    endif
    input_is_file = size(cdf0, /type) eq 7
    if input_is_file then begin
        file = cdf0
        if file_test(file) eq 0 then begin
            errmsg = handle_error('Input file does not exist ...')
            return
        endif
        cdfid = cdf_open(file)
    endif else begin
        cdfid = cdf0
    endelse

    ; Loop through variables in the file.
    if ~cdf_has_var(the_var, filename=cdfid, iszvar=iszvar) then begin
        errmsg = handle_error(cdfid=cdfid, 'File does not have var: '+the_var+' ...')
        return
    endif


;---Get vatts and check if depend_0 exists.
    vatt = cdf_read_setting(the_var, filename=cdfid)
    
    
    if n_elements(time_var) eq 0 then begin
        no_time = 0
        keys = vatt.keys()
        nkey = n_elements(keys)
        if nkey gt 0 then begin
            the_key = 'depend_0'    ; dict key is case insensitive.
            if vatt.haskey(the_key) then time_var = vatt[the_key]
        endif
    endif
    if n_elements(time_var) eq 1 then times = cdf_read_var(time_var, filename=cdfid, errmsg=errmsg)


;---Load the_var.
    ; Figure out the record range.
    if n_elements(range) eq 2 then begin
        if n_elements(times) ne 0 then begin
            index = where(times ge range[0] and times le range[1], count)
            if count eq 0 then begin
                errmsg = handle_error(cdfid=cdfid, 'Invalid range on time ...')
                return
            endif
            rec_range = index[[0,count-1]]
            times = times[index]
        endif
    endif else rec_range = !null
    vals = cdf_read_var(the_var, range=rec_range, filename=cdfid)


;---Save to tplot.
    if n_elements(times) eq 0 then times = 0
    store_data, the_var, times, vals
    add_setting, the_var, /smart, vatt.tostruct()
;    time_range = minmax(times)
;    nsec = total(time_range*[-1,1])
;    if nsec gt 0 then timespan, time_range[0], nsec, /seconds

end

var = 'tha_efs_dot0_gse'
dep_var = 'tha_efs_dot0_time'
fn = '/Users/shengtian/Downloads/tha_l2_efi_20110101_v01.cdf'
time = time_double(['2011-01-01/01:00','2011-01-01/02:00'])
cdf_load_var, var, depend=dep_var, range=time, filename=fn, errmsg=errmsg
end