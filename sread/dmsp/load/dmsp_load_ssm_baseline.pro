;+
; :Purpose: Load B baseline to remove it from the raw B field. Polynomial fit is used following decriptions in the CDAWeb SSM CDF file.
; :Returns: str, file name.
; :Arguments:
;   input_time_range: in, required. Time range.
; :Keywords:
;   probe: in, required. 'fxx'.
;   id: in, optional. Dummy keyword here.
;   print_datatype: in, optional. Set to print supported datatypes.
;   local_root: in, optional. Local root directory to save the data.
;   local_files: in, optional. A string or an array of N full file names.
;   file_times: in, optional. Set to fine tune the files to read data from.
;   version: in, optional. Version of the data to read.
;   errmsg: out, optional. Error message.
;   
;-

function dmsp_load_ssm_baseline, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root

    compile_opt idl2
    errmsg = ''
    retval = !null

;---Check inputs.
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','dmsp'])
    if n_elements(version) eq 0 then version = 'v01'
    if n_elements(datatype) eq 0 then datatype = 'ssm_baseline'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Init settings.
    type_dispatch = hash()

    valid_range = time_double('1990')
    base_name = 'dmsp'+probe+'_ssm_baseline_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'ssm_baseline','dmsp'+probe,'%Y']
    type_dispatch['ssm_baseline'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]) ), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name) )
    
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ''
    endif


;---Dispatch patterns.
    if n_elements(datatype) eq 0 then datatype = 'ssm_baseline'

    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, ''
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            files = dmsp_load_ssm_baseline_gen_file(file_time, probe=probe, filename=local_file)
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    endif

    if n_elements(files) eq 0 then return, '' else return, files

    return, retval

end


