;+
; Read GOES SSC data.
;
; input_time_range. A time range in unix time or string. Set time to find files
;   automatically, or set files to read data in them directly.
; id=. A string sets the data type to read. Check supported ids by setting
;   print_datatype.
; print_datatype=. A boolean. Set to print all supported ids.
; local_root=. A string to set the local root directory.
; local_files=. A string or an array of N full file names. Set to fine
;   tuning the files to read data from.
; file_times=. An array of N times. Set to fine tuning the times of the files.
;-

function goes_load_ssc, input_time_range, probe=input_probe, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root

    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''

;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(input_probe) eq 0 then begin
        errmsg = 'No input probe ...'
        return, retval
    endif
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'goes'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/goes'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

    datatype = 'pos'


;---Init settings.
    type_dispatch = hash()
    probe = goes_resolve_probe(input_probe)
    goesx = 'goes'+probe
    gx = 'g'+probe

    case probe of
        '10': valid_range = ['2006-01-01','2017-01-01']
        '11': valid_range = ['2006-01-01','2017-01-01']
        '12': valid_range = ['2006-01-01','2017-01-01']
        '13': valid_range = ['2006-01-01']
        '14': valid_range = ['2009-01-01']
        '15': valid_range = ['2010-01-01']
        '16': valid_range = ['2016-01-01']
        '17': valid_range = ['2018-01-01']
        '18': valid_range = ['2022-01-01']
    endcase

    ; position.
    base_name = goesx+'_ephemeris_ssc_%Y0101_v01.cdf'
    local_path = [local_root,goesx,'orbit','%Y']
    remote_path = [remote_root,goesx,'orbit','%Y']
    type_dispatch['pos'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'valid_range', time_double(valid_range), $
        'cadence', 'year', $
        'extension', fgetext(base_name) )

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ids
    endif

;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return, retval
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, retval
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)

    if n_elements(files) eq 0 then return, '' else return, files

end


time_range = ['2013-05-01','2013-05-02']
probe = 15
files = goes_load_ssc(time_range, probe=probe)
end