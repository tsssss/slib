;+
; Get the extension (without the dot ".").
;+

function fgetext, files
    bases = fget_base(files)
    exts = stregex(bases, '\.+(.+$)', /extract, /subexp)
    exts = reform(exts[1,*])
    return, exts
end

flist = list()
flist.add, ['cdf','.cdf','*.cdf','*..cdf']
flist.add, 'a.cdf'
flist.add, ['a.cdf','b.txt','c.dat']
foreach files, flist do print, fgetext(files)
end
