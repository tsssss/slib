;+
; Get the extension (without the dot ".").
;+

function fgetext, files
    bases = fgetbase(files)
    exts = stregex(bases, '\.+([a-zA-Z0-9]+$)', /extract, /subexp)
    exts = reform(exts[1,*])
    return, exts
end

flist = list()
flist.add, ['cdf','.cdf','*.cdf','*..cdf']
flist.add, 'a.cdf'
flist.add, ['a.cdf','b.txt','c.dat']
flist.add, 'SW_OPER_MAGC_LR_1B_%Y%m%dT.*_%Y%m%dT.*_.*.cdf'
foreach files, flist do print, fgetext(files)
end
