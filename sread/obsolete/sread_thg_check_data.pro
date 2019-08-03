;+
; Type: <+++>.
; Purpose: <+++>.
; Parameters: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Keywords: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Return: <+++>.
; Notes: <+++>.
; Dependence: <+++>.
; History:
;   <+yyyy-mm-dd+>, Sheng Tian, create.
;-

pro sread_thg_check_data, tr0, type = type, lun = lun, result = cmds


    ; local and remote directory.
    if n_elements(locroot) eq 0 then locroot = spreproot('themis')
    if n_elements(remroot) eq 0 then $
        remroot = 'http://themis.ssl.berkeley.edu/data/themis'

    minelev = 10
    if n_elements(lun) eq 0 then lun = -1

    ; choose thumbnail ast, or full res asf.
    if n_elements(type) eq 0 then type = 'asf'


; **** prepare site names.
    sites = ['atha','chbg','ekat','fsmi','fsim','fykn',$
        'gako','gbay','gill','inuv','kapu','kian',$
        'kuuj','mcgr','pgeo','pina','rank','snkq',$
        'tpas','whit','yknf','nrsq','snap','talo']
    nsite = n_elements(sites)


; **** prepare the ets, uts, nrec.
    dr = 3d     ; 3 sec for ast and asf.
    if size(tr0,/type) eq 7 then tformat = '' else tformat = 'unix'
    etr0 = stoepoch(tr0, tformat)
    
    tmp = (strlowcase(type) eq 'asf')? 'hr': 'dy'
    etr0 = sepochfloor(etr0, tmp)
    etr0 = etr0[uniq(etr0,sort(etr0))]
    
    if n_elements(etr0) eq 2 then begin
        tmp = (strlowcase(type) eq 'asf')? 3600000d: 86400000d
        etr0 = smkarthm(etr0[0],etr0[1],tmp, 'dx')
    endif
    
    ets = etr0
    uts = sfmepoch(ets, 'unix')
    nrec = n_elements(uts)
    cmds = []

    printf, lun, 'check '+type+' data availability ...'
    cmds = [cmds, 'check '+type+' data availability ...']

; **** prepare calibration vars. glats, glons.
    asc = sread_thg_asc(0, sites, vars = ['glat','glon'])

    ; check each file's existence.
    for i = 0, nrec-1 do begin

        printf, lun, sfmepoch(ets[i])+'...'
        cmds = [cmds, sfmepoch(ets[i])+'...']


        asifns = sptn2fn_thm_asi(ets[i], sites, locroot, type = type)
        for j = 0, nsite-1 do begin
            cmd = sites[j]+': '
            
            ; 1 for file exists.
            fileflag = 0
            
            basefn = file_basename(asifns[j])
            locpath = file_dirname(asifns[j])
            rempath = remroot+strmid(locpath,strlen(locroot))
            
            if file_test(locpath+'/'+basefn) eq 1 then fileflag = 1 else $
            if size(surlinfo(rempath+'/'+basefn),/type) eq 8 then fileflag = 1

            if fileflag eq 0 then begin
                cmd+= 'file does not exist ...'
            endif else begin
                cmd+= 'file exists, '
                ; test moon.
                moonflag = 0
                tmp = smoon(ets[i], asc.(j).glat, asc.(j).glon, /degree)
                cmd+= 'moon elev '+sgnum2str(tmp,nsgn=2)+' deg, '
                if tmp ge minelev then moonflag = 1
                if moonflag eq 0 then cmd+= 'no moon ...' else cmd+= 'have moon ...'
            endelse

            printf, lun, cmd
            cmds = [cmds, cmd]
        endfor
    endfor



end


sread_thg_check_data, ['2013-06-01','2013-06-02']
end
