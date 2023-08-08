;+
; Return all variables in the file.
; 
; file -> groups -> 
;-
function hdf_skeleton, id0, errmsg=errmsg, _extra=ex

    errmsg = ''
    retval = !null

    return, hdf_parse(id0, orderedhash=1)

    ; Check if given file is a cdf_id or filename.
    ;fid = get_fid(id0, input_is_file=input_is_file, errmsg=errmsg, file_open_routine='h5f_open', _extra=ex)

    ; Get the hiarachy.
    ;h5_list, id0, output=finfo

    ;nline = n_elements(finfo[0,*])
    ;flist = list()
    ;for ii=0,nline-1 do flist.add, strsplit(finfo[1,ii])
    
    ;groups = orderedhash()
    ;index = where(finfo[0,*] eq 'group', count)
    ;group_names = (count eq 0)? []: finfo[1,index]
    ;foreach group_name, group_names do begin
    ;    index = where(stregex(finfo[1,*], group_name+'/.*') eq 0, count)
    ;    if count ne 0 then begin
    ;        groups[group_name] = strmid(reform(finfo[1,index]),strlen(group_name)+1)
    ;    endif else begin
    ;        groups[group_name] = !null
    ;    endelse
    ;endforeach
    ;stop
    
    ;if input_is_file then h5f_close, fid




end

file = '/Volumes/data/dmsp/madrigal/dmspf18/2013/dms_20130502_18s1.001.hdf5'
;hdf2tplot, file
vars = hdf_skeleton(file)
end