;+
; Type: function.
; Purpose: Delete Themis/asi CDF files for given site(s) for a time range.
;   These files are big, so it's useful to delete the un-needed files.
; Parameter:
;   tr0, in, double/string, req. Set the time.
;       For double, it's the unix time or UTC. For string, it's the 
;       formatted string accepted by stoepoch, e.g., 'YYYY-MM-DD/hh:mm'.
;   site0, in, strarr[n], optional. The sites to be included. Include all sites
;       by default.
; Keywords:
;   filename, in, string or strarr[n], optional. The full file name(s) includes
;       explicit paths.
;   locroot, in, string, optional. The local data root directory.
;   remroot, in, string, optional. the remote data root directory.
;   type, in, string, dummy. Force type = uvi_level1.
;   version, in, string, optional. Data version. In case to load an old
;       version data. By default, the highest version is loaded.
;   exclude, in, strarr[m], optional. The sites to be excluded. No site is
;       excluded by default.
; Return: struct. {epoch: epoch, mltimg: mltimg}.
; Notes: none.
; Dependence: slib.
; History:
;   2016-05-03, Sheng Tian, create.
;-
function sread_thg_rmdat, tr0, site0, exclude = exclude, $
    locroot = locroot, remroot = remroot, type = type0, version = version

    compile_opt idl2

    ; local directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('themis')

    ; choose thumbnail ast, or full res asf.
    type = n_elements(type0)? strlowcase(type0): 'asf'  ; can be 'ast','asf'.

; **** prepare site names.
    site0s = ['atha','chbg','ekat','fsmi','fsim','fykn',$
        'gako','gbay','gill','inuv','kapu','kian',$
        'kuuj','mcgr','pgeo','pina','rank','snkq',$
        'tpas','whit','yknf','nrsq','snap','talo']
    nsite = n_elements(site0)
    if nsite eq 0 then site0 = '*'
    if site0[0] eq '*' then begin
        site0 = site0s
        nsite = n_elements(site0)
    endif
    sites = site0
    
    ; exclude sites.
    for i = 0, n_elements(exclude)-1 do begin
        idx = where(sites eq exclude[i], tmp)
        if tmp gt 0 then sites[idx] = ''
    endfor
    idx = where(sites ne '', tmp)
    if tmp eq 0 then begin
        message, 'no site ...', /continue
        return, -1
    endif
    sites = sites[idx]
    nsite = n_elements(sites)
    
    print, 'deleting sites: '+strjoin(sites,',')+' ...'


; **** type related vars.
    tfmt = (type eq 'asf')? 'yyyyMMddhh': 'yyyyMMdd'
    vsn = (n_elements(version))? version: 'v[0-9]{2}'
    ext = 'cdf'


; **** prepare locfns, '' for not found.
    dr = 3d     ; 3 sec for ast and asf.
    dut = (type eq 'asf')? 3600: 86400
    det = dut*1e3
    if size(tr0,/type) eq 7 then tformat = '' else tformat = 'unix'
    etr0 = stoepoch(tr0, tformat)
    utr0 = sfmepoch(etr0,'unix') & tmp = utr0
    utr0 = utr0-(utr0 mod dr)
    
    fnets = (n_elements(etr0) eq 1)? (etr0-(etr0 mod det)): $
        reform((sbreaktr(etr0, det))[0,*])
    nfnet = n_elements(fnets)

    locfns = strarr(nsite,nfnet)
    for j = 0, nsite-1 do begin
        baseptn = 'thg_l1_'+type+'_'+sites[j]+'_'+tfmt+'_'+vsn+'.'+ext
        locpaths = [locroot,'thg/l1/asi',sites[j],'YYYY/MM',baseptn]
        locfns[j,*] = sprepfile(utr0, paths = locpaths, dt = det)
        
        for k = 0, nfnet-1 do begin
            basefn = file_basename(locfns[j,k])
            locpath = file_dirname(locfns[j,k])
            tasifn = sgetfile(basefn, locpath)
            if tasifn eq '' then begin
                print, sites[j]+' no data ...'
            endif else begin
                file_delete, tasifn
                print, sites[j]+' deleted ...'
            endelse
        endfor
    endfor
    
    return, 1

end

sites = ['']
;excludes = ['whit','fsim','fsmi']
tr = ['2008-01-05/21:00','2008-01-05/23:00']

tmp = sread_thg_rmdat(tr, exclude = sites)
end
