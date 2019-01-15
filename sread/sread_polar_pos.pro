;+
; Type: function.
; Purpose: Read Polar positon.
; Parameters:
;   datsrc, in, string, opt. Data source, default is 'sdata'. Can be 'cdaweb':
;       ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/orbit/pre_or/,
;       ftp://cdaweb.gsfc.nasa.gov/pub/data/polar/orbit/def_or/.
; Keywords:
;   fn0, in, string, opt. File name(s) for data.
;   t, in/out, string/double/strarr[2]/dblarr[2], opt. Epoch info. Scalar sets 
;       filename, in array[2] for time range as well. Must be valid input for
;       stoepoch.
;   rootdir, in, string, opt. Root directory for the data source.
;   dt, in, double, opt. Time interval in min, default is 1 min.
;   ivars, in, strarr[n], opt. Variable list to read.
; Return:
;   return, out, type = struct. For 'sdata',
;       { epoch: dblarr[n], epochs in double,
;         pos_gse: dblarr[n], [rx, ry, rz] position in GSE in Re,
;         dis: dblarr[n], distance in Re,
;         mlt: dblarr[n], magnetic local time,
;         ilat: dblarr[n], ivariant latitude, minus sign for s-hemisphere.}
; Notes: Data source and roodir determine pattern, maybe open an interface for
;   pattern in the future. Currently, modify roodir and source module.
; Dependence: slib.
; History:
;   2013-06-17, Sheng Tian, create.
;   2014-05-23, Sheng Tian, revise.
;-
function sread_polar_pos, datsrc, vars = ivars, $
    fn0 = fn0, t = tr0, rootdir = rootdir, dt = dt
    
    dr = 1 ; data rate, 1 min.
    if n_elements(dt) eq 0 then dt = 1
    drec = dt*dr
    
    ; rootdir module.
    if n_elements(rootdir) eq 0 then begin
        case susrhost() of
            'Sheng@Xps': rootdir = sdiskdir('Research')
            'sheng@XpsMintv': rootdir = sdiskdir('Research')
            'Sheng@Shengs-MacBook-Pro.local': rootdir = sdiskdir('Research')
            else: rootdir = sdiskdir('Research')
        endcase
    endif
    
    ; source module, determine pattern and default variable list.
    if n_elements(datsrc) eq 0 then datsrc = 'sdata'
    case datsrc of
        'cdaweb': begin
            dataptn = rootdir+ $
                '/data/polar/orbit/yyyy/po_or_???_yyyyMMdd_v??.cdf'
            var0s = ['Epoch','EDMLT_TIME','L_SHELL','MAG_LATITUDE','GSE_POS']
        end
        'sdata': begin
            dataptn = rootdir+ $
                '/sdata/polar/orbit/yyyy/po_or_def_yyyyMMdd_v0?.cdf'
            var0s = ['Epoch','mlt','ilat','dis','pos_gse']
        end
    endcase
    
    ; file and time range module.
    fns = (n_elements(fn0) eq 0)? sprepfn(dataptn, t = tr0): sprepfn(fn0)
    nfn = n_elements(fns)
    
    ; reading module.
    ; default varlist in cdf file.
    if n_elements(ivars) eq 0 then ivars = var0s
    idx0 = where(ivars eq 'Epoch') & idx0 = idx0[0]
    nivar = n_elements(ivars)
    ivarptrs = ptrarr(nivar)
    for i = 0, nfn-1 do begin
        tmp = scdfread(fns[i], ivars, drec = drec)
        for j = 0, nivar-1 do begin
            if ptr_valid(ivarptrs[j]) then begin
                *ivarptrs[j] = [*ivarptrs[j],*(tmp[j].value)]
            endif else ivarptrs[j] = ptr_new(*(tmp[j].value), /no_copy)
        endfor
    endfor
    for j = 0, nivar-1 do ptr_free, tmp[j].value
    
    ; trim to time range.
    if n_elements(tr0) eq 2 and idx0[0] ne -1 then begin
        ets = stoepoch(tr0)
        idx = where(*ivarptrs[idx0] ge ets[0] and *ivarptrs[idx0] le ets[1])
        for j = 0, nivar-1 do *ivarptrs[j] = (*ivarptrs[j])[idx,*]
    endif
    
    ; default varlist for output.
    ovars = ivars & data = {}
    for j = 0, nivar-1 do begin
        data = create_struct(data, ovars[j], *ivarptrs[j])
        ptr_free, ivarptrs[j]
    endfor
    return, data
end