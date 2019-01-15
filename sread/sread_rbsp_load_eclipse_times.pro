;+
; load rbsp eclipse times. download files online, then read the files and
; save the final results to disk.
; run this before sread_rbsp_eclipse_time
; the files are named as rbspx_eclipse_time_yyyy.sav,
; the variables are uts, flags
;-

pro sread_rbsp_load_eclipse_times, probes

    if n_elements(probes) eq 0 then probes = ['a','b']
    nprobe = n_elements(probes)


    ; local and remote directory.
    sep = path_sep()
    if n_elements(locroot) eq 0 then locroot = spreproot('rbsp')
    if n_elements(remroot) eq 0 then $
        remroot = 'http://rbsp.space.umn.edu/data/rbsp'


    ; **** prepare file names.
    type = 'MOC_data_products'
    minline = 6     ; files contains eclipse time are at least 7 lines.
    cns = -1

    foreach tprobe, probes do begin
        rbspx = 'rbsp'+tprobe
        rempath = remroot+'/'+type+'/'+strupcase(rbspx)+'/eclipse_predict'
        locpath = locroot+'/'+type+'/'+strupcase(rbspx)+'/eclipse_predict/files'
        datpath = locroot+'/'+type+'/'+strupcase(rbspx)+'/eclipse_predict/data'
        
        if file_test(datpath,/directory) eq 0 then file_mkdir, datpath

        remidx = rempath+'/'
        locidx = locpath+'/.remote-index.html'

        ; download the latest index file, if certain data file is missing,
        ; download and write the new eclipse times into the info structure.
        scurl, remidx, locidx
        nline = file_lines(locidx)
        lines = strarr(nline)
        openr, lun, locidx, /get_lun
        readf, lun, lines
        free_lun, lun

        fnptn = '"'+rbspx+'_[0-9]{4}_[0-9]{3}_[0-9]{2}.pecl"'
        pos = stregex(lines, fnptn)
        len = 22
        idx = where(pos ne -1, nfile)
        pos = pos[idx]+1    ; to exclude the leading '"'.
        files = strarr(nfile)
        for i = 0, nfile-1 do files[i] = strmid(lines[idx[i]],pos[i], len)
        foreach tfile, files do begin
            locfn = locpath+'/'+tfile
            if file_test(locfn) ne 0 then continue
            remfn = rempath+'/'+tfile
            scurl, remfn, locfn
            
            ; read all the lines.
            printf, cns, 'reading '+locfn+' ...'
            nline = file_lines(locfn)
            if nline le minline then continue   ; no eclipse time in this file.
            lines = strarr(nline)
            openr, lun, locfn, /get_lun
            readf, lun, lines
            free_lun, lun
            lines = lines[6:*]
            nline = n_elements(lines)
            foreach tline, lines do begin
                tmp = strsplit(tline, ' ', /extract)
                t1 = strjoin(tmp[1:4], ' ') & if strlen(tmp[1]) eq 1 then t1 = ' '+t1
                t2 = strjoin(tmp[5:8], ' ') & if strlen(tmp[5]) eq 1 then t2 = ' '+t2
                utr = time_double([t1,t2],tformat='DD MTH YYYY hh:mm:ss.fff')
                utr = utr-(utr mod 60)  ; accuracy of 1 min.
                printf, cns, '    eclipse: '+strjoin(time_string(utr),' - ')
                yrs = time_string(utr,tformat='YYYY')
                if strcmp(yrs[0],yrs[1]) eq 1 then begin
                    yrs = yrs[0]
                endif else begin
                    tut = time_double(yrs[1]+'0101',tformat='YYYYMMDD')
                    utr = [utr[0],tut-60,tut,utr[1]]
                endelse
                nyr = n_elements(yrs)
                for i = 0, nyr-1 do begin
                    datfn = datpath+'/'+rbspx+'_eclipse_time_'+yrs[i]+'.sav'
                    if file_test(datfn) eq 0 then begin
                        ut0 = time_double(yrs[i]+'01010000',tformat='YYYYMMDDhhmm')
                        ut1 = time_double(yrs[i]+'12312359',tformat='YYYYMMDDhhmm')
                        uts = smkarthm(ut0,ut1,60,'dx')
                        nrec = n_elements(uts)
                        flags = bytarr(nrec)
                    endif else restore, filename = datfn
                    tutr = utr[i*2:i*2+1]
                    idx = where(uts ge tutr[0] and uts le tutr[1], cnt)
                    if cnt ne 0 then flags[idx] = 1
                    save, uts, flags, filename = datfn
                endfor
            endforeach
        endforeach
    endforeach
end
