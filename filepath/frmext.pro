;+
; Remove the extension (including the dot ".").
;+

function frmext, files

    foreach file, files, ii do begin
        base = fgetbase(file)
        pos = stregex(base, '\.+([a-zA-Z0-9]+$)')
        if pos eq -1 then continue
        path = fgetpath(file)
        files[ii] = join_path([path,strmid(base,0,pos)])
    endforeach
    
    return, files
end

flist = list()
flist.add, ['cdf','.cdf','*.cdf','*..cdf']
flist.add, 'a.cdf'
flist.add, ['a.cdf','b.txt','c.dat']
flist.add, 'SW_OPER_MAGC_LR_1B_%Y%m%dT.*_%Y%m%dT.*_.*.cdf'
foreach files, flist do print, frmext(files)
end
