;+
; Type: function.
; Purpose: Interpolate given data of at abscissa x to new x.
; Parameters:
;   data, in, [*], req. For scalar array, dimension is [n0].
;     For m dimension vector array, dimension is [m, n0] or [n0, m].
;   oldabs, in, [n0], req. Old abscissa.
;   newabs, in, [n1], req. New abscissa.
; Keywords:
;   is_quaternion=.
;   _extra = extra, in, struct, opt. Keywords for interpol, see idl help.
;     /LSQuadratic, /NaN, /Quatradic, /Spline.
;   interp_range=. 
; Return: [*]. If data is array of [n0], then return [n1];
;     if data is array of [m, n0], then return, [m, n1].
;     if data is array of [n0, m], then return, [n1, m].
; Notes: Do not work if given data has more than 2 dimensions. Do NOT set /NaN 
;   automatically for interpol().
; History:
;   2011-07-20, Sheng Tian, create.
;   2011-08-16, Sheng Tian, add throw exterpolate.
;   2012-09-17, Sheng Tian, auto deal with dims.
;-

function sinterpol, data, oldabs, newabs, interp_range=interp_range, is_quaternion=is_quaternion, _extra = extra
  compile_opt idl2
  on_error, 0
  
  errmsg = ''
  retval = !null
  
  oldyy = data
  oldxx = oldabs
  newxx = newabs
  
  oldsize = size(oldyy)
  old_ndim = oldsize[0]
  

  if old_ndim eq 0 then begin
    message, 'data is scalar, return ...', continue=1
    return, data
  endif
  
  ; quaternion.
  if keyword_set(is_quaternion) then begin
      old_dims = size(data,/dimensions)
      nold_dim = n_elements(old_dims)
      ncomp = product(old_dims[1:nold_dim-1])
      if ncomp ne 4 then begin
        errmsg = 'Invalid dimension ...'
        return, retval
      endif
      old_dim1 = [old_dims[0],ncomp]
      old_data = reform(data, old_dim1)
      return, qslerp(old_data, oldabs, newabs)
  endif
  
  ; scalar array.
  if old_ndim eq 1 then $
    return, interpol(oldyy, oldxx, newxx, /nan, _extra = extra)
  
  ; vector array.
  old_dims = size(data,/dimensions)
  nold_dim = n_elements(old_dims)
  ncomp = product(old_dims[1:nold_dim-1])
  old_dim1 = [old_dims[0],ncomp]
  old_data = reform(data, old_dim1)
  new_dims = [n_elements(newabs),old_dims[1:nold_dim-1]]
  new_dim1 = [new_dims[0],ncomp]
  new_data = dblarr(new_dim1)
  for ii=0, ncomp-1 do begin
    new_data[*,ii] = interpol(old_data[*,ii], oldxx, newxx, /nan, _extra=extra)
  endfor
  ; do not extrapolate.
  if n_elements(interp_range) eq 0 then interp_range = minmax(oldxx)
  index = where_pro(newxx, ')(', interp_range, count=count)
  if count ne 0 then begin
        new_data[index,*] = !values.f_nan
  endif
  new_data = reform(new_data, new_dims)
  return, new_data
  
;  ; data in [n0, m].
;  if oldsize[1] eq n_elements(oldxx) then begin
;    newdims = [n_elements(newxx), oldsize[2]]
;    newyy = replicate(oldyy[0], newdims)    ; keep type.
;    for ii = 0, newdims[1]-1 do $
;      newyy[*,ii] = interpol(oldyy[*,ii], oldxx, newxx, _extra = extra)
;  ; data in [m, n0].
;  endif else begin
;    if oldsize[2] ne n_elements(oldxx) then $
;      message, 'data incorrect dimension ...'
;    newdims = [oldsize[1], n_elements(newxx)]
;    newyy = replicate(oldyy[0], newdims)
;    for ii = 0, newdims[0]-1 do $
;      newyy[ii,*] = interpol(oldyy[ii,*], oldxx, newxx, _extra = extra)
;  endelse
;    
;  return, newyy
end
