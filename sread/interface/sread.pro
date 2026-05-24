;+
; :Returns: The variable name.
; :Arguments:
;   var: in, required, str. The variable name to read.
;   mission: in, required, str. The mission to read from.
;   time_range: in, required, str. The time range to read.
; :Keywords:
;   update: in, optional, bool. Whether to update the data file if it is out of date. Default is true.
;   filename: in, optional, str. The name of the data file to read from.
;   get_name: in, optional, str. The name of the function to call to get the data.
;   get_func: in, optional, str. The name of the function to call to read the data.
;   _extra: in, optional, any. Additional keyword arguments to pass to the reading function.
;-

; functions need to have the following interface:
;   1. get_name: returns the variable name to read the data into.

function sread, var, mission, time_range, $
    get_func=get_func, get_name=get_name, $
    update=update, filename=data_file, $
    _extra=extra

    compile_opt idl2

;---Get the function name to call to read the data.
    function_name = mission+'_read_'+var
    if keyword_set(get_func) then return, function_name


;---Get the variable name to read the data into.
    var_name = call_function(function_name, time_range, get_name=1, _extra=extra)
    if keyword_set(get_name) then return, var_name


;---Avoid reloading data unless update is set.
    if n_elements(data_file) eq 0 then data_file = ''
    if keyword_set(update) then begin
        tmp = delete_var_from_memory(var_name)
        tmp = delete_var_from_file(var_name, file=data_file)
    endif
    if ~check_if_update_memory(var_name, time_range, _extra=extra) then return, var_name

    ; Try to load the data from the saved file.
    update_file = 0
    if file_test(data_file) then begin
        update_file = 1
    endif else begin
        update_file = ~file_has_var(var_name, file=data_file)
    endelse

    if ~update_file then begin
        var_name = load_var_from_file(var_name, file=data_file)
        return, var_name
    endif

    ; Load the data using the specified function.
    the_var = call_function(function_name, time_range, _extra=extra)
    if the_var ne var_name then begin
        var_name = rename_var(the_var, var_name)
    endif

    ; Save the data to the file.
    if data_file ne '' then begin
        tmp = save_var_to_file(var_name, file=data_file)
    endif


;---Done.
    return, var_name


end

compile_opt idl2
test_inputs = list()
test_inputs.add, dictionary($
    'var', 'efield', $
    'mission', 'rbsp', $
    'time_range', ['2014-01-01','2014-01-02'], $
    'probe', 'a')
test_inputs.add, dictionary($
    'var', 'bfield', $
    'mission', 'themis', $
    'time_range', ['2014-01-01','2014-01-02'], $
    'probe', 'c')
foreach input, test_inputs do begin
    var = input['var']
    mission = input['mission']
    time_range = input['time_range']
    input = input.toStruct()
    func_name = sread(var, mission, time_range, get_func=1, _extra=input)
    print, func_name
    var_name = sread(var, mission, time_range, get_name=1, _extra=input)
    print, var_name
endforeach

end