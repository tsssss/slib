
function sread_mms_hpca_l2, tr0, probes = probe0, filename = fn0, $
    vars = var0s, newnames = var1s, $
    burst = burst, $
    locroot = locroot, remroot = remroot, type = type0, version = version

    compile_opt idl2

;---local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = spreproot('mms')
    if n_elements(remroot) eq 0 then $
        remroot = 'https://lasp.colorado.edu/mms/sdc/public/data/'
    
;---prepare file names. type1 in path, type2 in basename.
    if n_elements(type0) eq 0 then type = 'ion' else type = strlowcase(type0)
    case type of 
        'ion': begin
            type1 = 'ion'
            type2 = 'ion'
            end
        'moments': begin
            type1 = 'moments'
            type2 = 'moments'
            end
        else: message, 'unkown type ...'
    endcase
    prb = (n_elements(probe0))? probe0: '1'
    vsn = (n_elements(version))? version: 'v[0-9.]{5}'
    ext = 'cdf'
    rate = keyword_set(burst)? 'brst': 'srvy'
    date1 = 'YYYY'+sep+'MM' & if keyword_set(burst) then date1 = date1+sep+'DD'
    
    baseptns = ['mms'+prb+'_hpca_'+rate+'_l2_'+type2,'_YYYYMMDD[0-9.]{6}_'+vsn+'.'+ext]
    nbaseptn = n_elements(baseptns)
    ptnflags = [0,1]
    rempaths = [remroot+sep+'mms'+prb+sep+'hpca',rate,'l2',type1,date1,baseptns]
    locpaths = [locroot+sep+'mms'+prb+sep+'hpca',rate,'l2',type1,date1,baseptns]
    ptnflags = [0,0,0,0,1,ptnflags]
    
    remfns = sprepfile(tr0, paths = rempaths, flags=ptnflags, nbase=nbaseptn)
    locfns = sprepfile(tr0, paths = locpaths, flags=ptnflags, nbase=nbaseptn)
    nfn = n_elements(locfns)
    for i = 0, nfn-1 do begin
        basefn = file_basename(locfns[i])
        locpath = file_dirname(locfns[i])
        rempath = file_dirname(remfns[i])
        locfns[i] = sgetfile(basefn, locpath, rempath)
    endfor
    idx = where(locfns ne '', nfn)
    if nfn ne 0 then locfns = locfns[idx] else return, -1

    
    


end

utr = ['2017-08-04/16:40','2017-08-04/17:30']
utr = ['2017-08-04/11:40','2017-08-04/17:30']
tprobe = '1'
type = 'ion'
hpca = sread_mms_hpca_l2(utr, probe=tprobe, type=type)
end