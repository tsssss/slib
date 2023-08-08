;+
; Type: function.
; Purpose: Convert IDL type to CDF type.
; Parameters:
;   types, in, int/intarr[n]/string, req. IDL type(s). If in string, then
;       it will return a structure, where the elements are 1 if the tags
;       match the string(s).
; Keywords:
;   structure, in, boolean, opt. Set to return a structure can be passed
;       to cdf_varcreate.
; Return: string/strarr[n] or structure. CDF data type code.
; Notes: none.
; Dependence: none.
; History:
;   2018-02-04, Sheng Tian, create.
;-
function cdf_type_from_idl_type, types, structure=structure
    on_error, 2

    cdftypes = 'CDF_'+['XXX','BYTE','UINT1','INT1','CHAR','UCHAR',$
        'INT2','UINT2','INT4','UINT4','REAL4','FLOAT','DOUBLE','REAL8',$
        'EPOCH','EPOCH16','LONG_EPOCH']
    idltypes = [0,1,1,1,7,7,2,12,3,13,4,4,5,5,5,9,9]


    ntype = n_elements(types)
    ncdftype = n_elements(cdftypes)
    if size(types,/type) eq 7 then begin
        for i=ncdftype-1,0,-1 do begin
            if n_elements(vinfo) eq 0 then begin
                vinfo = create_struct(cdftypes[i],0)
            endif else begin
                vinfo = create_struct(cdftypes[i],0,vinfo)
            endelse
        endfor
        for i=0, ntype-1 do begin
            idx = where(cdftypes eq strupcase(types[i]), cnt)
            if cnt ne 0 then vinfo.(idx[0]) = 1
        endfor
        return, vinfo
    endif


    if ~keyword_set(structure) then begin
        vtpys = strarr(ntype)
        for i=0, ntype-1 do begin
            idx = where(idltypes eq types[i], cnt)
            vtpys[i] = (cnt ne 0)? cdftypes[idx[0]]: 'CDF_XXX'
        endfor
        if ntype eq 1 then vtpys = vtpys[0]
        return, vtpys
    endif else begin
        for i=ncdftype-1,0,-1 do begin
            if n_elements(vinfo) eq 0 then begin
                vinfo = create_struct(cdftypes[i],0)
            endif else begin
                vinfo = create_struct(cdftypes[i],0,vinfo)
            endelse
        endfor
        for i=0, ntype-1 do begin
            idx = where(idltypes eq types[i], cnt)
            if cnt ne 0 then vinfo.(idx[0]) = 1
        endfor
        return, vinfo
    endelse
end

print, cdf_type_from_idl_type(size(0d,/type))
help, cdf_type_from_idl_type(size(0d,/type),/structure)
help, cdf_type_from_idl_type('cdf_epoch')
end
