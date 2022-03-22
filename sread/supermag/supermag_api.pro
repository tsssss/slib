; supermag-api.pro
; ================
; Author R.J.Barnes
; Sheng: I changed the interface slightly.


; (c) 2021  The Johns Hopkins University Applied Physics Laboratory
;LLC.  All Rights Reserved.

;This material may be only be used, modified, or reproduced by or for
;the U.S. Government pursuant to the license rights granted under the
;clauses at DFARS 252.227-7013/7014 or FAR 52.227-14. For any other
;permission,
;please contact the Office of Technology Transfer at JHU/APL.

; NO WARRANTY, NO LIABILITY. THIS MATERIAL IS PROVIDED "AS IS."
; JHU/APL MAKES NO REPRESENTATION OR WARRANTY WITH RESPECT TO THE
; PERFORMANCE OF THE MATERIALS, INCLUDING THEIR SAFETY, EFFECTIVENESS,
; OR COMMERCIAL VIABILITY, AND DISCLAIMS ALL WARRANTIES IN THE
; MATERIAL, WHETHER EXPRESS OR IMPLIED, INCLUDING (BUT NOT LIMITED TO)
; ANY AND ALL IMPLIED WARRANTIES OF PERFORMANCE, MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF
; INTELLECTUAL PROPERTY OR OTHER THIRD PARTY RIGHTS. ANY USER OF THE
; MATERIAL ASSUMES THE ENTIRERISK AND LIABILITY FOR USING THE
; MATERIAL. IN NO EVENT SHALL JHU/APL BE LIABLE TO ANY USER OF THE
; MATERIAL FOR ANY ACTUAL, INDIRECT, CONSEQUENTIAL, SPECIAL OR OTHER
; DAMAGES ARISING FROM THE USE OF, OR INABILITY TO USE, THE MATERIAL,
; INCLUDING, BUT NOT LIMITED TO, ANY DAMAGES FOR LOST PROFITS.


function supermag_logon
    return, 'shengtian'
end

PRO SuperMAGTimeToYMDHMS, tval,yr,mo,dy,hr,mt,sc
  julday=(tval/86400.0)+2440587.5
  caldat,julday,mo,dy,yr,hr,mt,sc
END

FUNCTION SuperMAGUrlCallback, status, progress, data

   ; print the info msgs from the url object
   PRINT, status

   ; return 1 to continue, return 0 to cancel
   RETURN, 1
END

FUNCTION SuperMAGGetUrl,urlstr,strings

   ; If the url object throws an error it will be caught here
   CATCH, errorStatus
   IF (errorStatus NE 0) THEN BEGIN
      CATCH, /CANCEL

      PRINT, !ERROR_STATE.msg

      ; Get the properties that will tell us more about the error.
      oUrl->GetProperty, RESPONSE_CODE=rspCode, $
         RESPONSE_HEADER=rspHdr, RESPONSE_FILENAME=rspFn
      PRINT, 'rspCode = ', rspCode
      PRINT, 'rspHdr= ', rspHdr
      PRINT, 'rspFn= ', rspFn
      strings=strarr(1)
      strings[0]='ERROR:HTTP error'
      ; Destroy the url object
      OBJ_DESTROY, oUrl
      RETURN, strings
   ENDIF

   ; create a new IDLnetURL object
   oUrl = OBJ_NEW('IDLnetUrl')

   ; Specify the callback function
   ;oUrl->SetProperty, CALLBACK_FUNCTION ='SuperMAGUrlCallback'

   ; Set verbose to 1 to see more info on the transacton
   oUrl->SetProperty, VERBOSE = 0

   ; Set the transfer protocol as https
   oUrl->SetProperty, URL_SCHEME = 'https'

   oUrl->SetProperty, SSL_VERIFY_HOST=0

   oUrl->SetProperty, SSL_VERIFY_PEER=0

   oUrl->SetProperty, SSL_VERSION=0

   oUrl->SetProperty, URL_HOST = 'supermag.jhuapl.edu'

   oUrl->SetProperty, URL_PATH = urlstr

   strings = oUrl->Get( /STRING_ARRAY )


   ; Destroy the url object
   OBJ_DESTROY, oUrl

   return, strings
END

FUNCTION SuperMAGGetInventory,input_time_range, $
    iarr,error=errstr

    compile_opt idl2

    iarr=!NULL
    logon = supermag_logon()
    time_range = time_double(input_time_range)
    time_str = time_string(time_range[0],tformat='YYYY-MM-DDThh:mm')
    extent = total(time_range*[-1,1])

    ; construct URL
    urlstr='services/inventory.php?logon='+logon
    urlstr+='&start='+time_str
    urlstr+='&extent='+string(extent,FORMAT='(I12.12)')
    urlstr+='&idl'


  ; get the string array of stations

  strings=SuperMAGGetUrl(urlstr)


  ; if the inventory is valid extract the stations to an array
  ; if an error occurs set the the ERROR keyword to be the error string

  if n_elements(strings) gt 1 then iarr=strings[2:*] else errstr=strings

  ; return true (1) if the call was successful otherwise false (0)

  return, (n_elements(strings) gt 1)
END


FUNCTION SuperMAGGetDataStruct,input_time_range, $
    station,magdata,error=errstr, $
    ALL=all,MLT=mlt,MAG=mag,GEO=geo,DECL=decl,SZA=sza, $
    DELTA=delta,BASELINE=baseline

    compile_opt idl2
    magdata=!NULL
    logon = supermag_logon()
    time_range = time_double(input_time_range)
    time_str = time_string(time_range[0],tformat='YYYY-MM-DDThh:mm')
    extent = total(time_range*[-1,1])

    ; construct URL
    urlstr='services/data-api.php?fmt=json&logon='+logon
    urlstr+='&start='+time_str
    urlstr+='&extent='+string(extent,FORMAT='(I12.12)')
    urlstr+='&station='+station

  if keyword_set(ALL) then urlstr+='&mlt&mag&geo&decl&sza' $
  else begin
     if keyword_set(MLT) then urlstr+='&mlt'
     if keyword_set(MAG) then urlstr+='&mag'
     if keyword_set(GEO) then urlstr+='&geo'
     if keyword_set(DECL) then urlstr+='&decl'
     if keyword_set(SZA) then urlstr+='&sza'
  endelse

  if keyword_set(DELTA) then urlstr+='&delta=start'

  if keyword_set(BASELINE) then begin
    if strcmp(BASELINE,'none',/FOLD_CASE) eq 1 then urlstr+='&baseline=none'
    if strcmp(BASELINE,'year',/FOLD_CASE) eq 1 then urlstr+='&baseline=yearly'
  endif

  urlstr+='&idl'

  ; print out URL for debugging

  ; print, urlstr


  ; get the string array of JSON data

  strings=SuperMAGGetUrl(urlstr)

  ; if no data is found this is not an error
  ; the routine will just return a null pointer
  ; if an error does occur, set the ERROR keyward to the error string

  if n_elements(strings) gt 1 then begin ; valid JSON data, so SuperMAG data found
    jstring=strjoin(strings[1:*])
    magdata=json_parse(jstring,/TOARRAY,/TOSTRUCT)
    return, 1
  endif else if (strmid(strings[0],0,2) ne 'OK') then begin ; Error condition
    errstr=strings
    return, 0
  endif else return,1 ; No JSON data but service still responded with OK, not an error

END


FUNCTION SuperMAGGetDataArray, input_time_range, $
    station,tval,n,e,z,error=errstr, $
    MLT=mlt,MAG=mag,GEO=geo,DECL=decl,SZA=sza, $
    DELTA=delta,BASELINE=baseline

    compile_opt idl2
    magdata=!NULL
    tval=!NULL
    n=!NULL
    e=!NULL
    z=!NULL
    logon = supermag_logon()
    time_range = time_double(input_time_range)
    time_str = time_string(time_range[0],tformat='YYYY-MM-DDThh:mm')
    extent = total(time_range*[-1,1])

    ; construct URL
    urlstr='services/data-api.php?fmt=json&logon='+logon
    urlstr+='&start='+time_str
    urlstr+='&extent='+string(extent,FORMAT='(I12.12)')
    urlstr+='&station='+station

    if arg_present(MLT) then urlstr+='&mlt'
    if arg_present(MAG) then urlstr+='&mag'
    if arg_present(GEO) then urlstr+='&geo'
    if arg_present(DECL) then urlstr+='&decl'
    if arg_present(SZA) then urlstr+='&sza'

    if keyword_set(DELTA) then urlstr+='&delta=start'

    if keyword_set(BASELINE) then begin
        if strcmp(BASELINE,'none',/FOLD_CASE) eq 1 then urlstr+='&baseline=none'
        if strcmp(BASELINE,'year',/FOLD_CASE) eq 1 then urlstr+='&baseline=yearly'
    endif

    urlstr+='&idl'

  ; print out URL for debugging

  ; print, urlstr

  ; get the string array of JSON data

  strings=SuperMAGGetUrl(urlstr)

  ; if no data is found this is not an error
  ; the routine will just return a null pointer
  ; if an error does occur, set the
  ; ERROR keyward to the error string

  if n_elements(strings) gt 1 then begin ; valid JSON data, so SuperMAG data found
    jstring=strjoin(strings[1:*])
    magdata=json_parse(jstring,/TOARRAY,/TOSTRUCT)
    nvec=n_elements(magdata)

    if nvec eq 0 then return, s

    tval=dblarr(nvec)
    n=dblarr(nvec,2)
    e=dblarr(nvec,2)
    z=dblarr(nvec,2)

    tval=magdata[*].tval
    n[*,0]=magdata[*].N.geo
    n[*,1]=magdata[*].N.nez
    e[*,0]=magdata[*].E.geo
    e[*,1]=magdata[*].E.nez
    z[*,0]=magdata[*].Z.geo
    z[*,1]=magdata[*].Z.nez

    if arg_present(MLT) then begin
      mlt=dblarr(nvec,2)
      mlt[*,0]=magdata[*].mlt
      mlt[*,1]=magdata[*].mcolat
    endif

    if arg_present(GEO) then begin
      geo=dblarr(nvec,2)
      geo[*,0]=magdata[*].glon
      geo[*,1]=magdata[*].glat
    endif

    if arg_present(MAG) then begin
      mag=dblarr(nvec,2)
      mag[*,0]=magdata[*].mlon
      mag[*,1]=magdata[*].mlat
    endif

    if arg_present(DECL) then begin
      decl=dblarr(nvec)
      decl=magdata[*].decl
    endif

    if arg_present(SZA) then begin
      sza=dblarr(nvec)
      sza=magdata[*].sza
    endif

    return, 1
  endif else if (strmid(strings[0],0,2) ne 'OK') then begin ; Error condition
    errstr=strings
    return, 0
  endif else return,1 ; No JSON data but service still responded with OK, not an error
end

FUNCTION SuperMAGGetIndicesStruct, input_time_range, $
    inxdata,error=errstr, $
    INDICESALL=indicesall,IMFALL=imfall,SWIALL=swiall,$
    SME=sme,SML=sml,SMU=smu, $
    MLAT=mlat,MLT=mlt,GLAT=glat,GLON=glon,STID=stid,NUM=num, $
    SUNSME=sunsme,SUNSML=sunsml,SUNSMU=sunsmu, $
    SUNMLAT=sunmlat,SUNMLT=sunmlt,SUNGLAT=sunglat,SUNGLON=sunglon, $
    SUNSTID=sunstid,SUNNUM=sunnum, $
    DARKSME=darksme,DARKSML=darksml,DARKSMU=darksmu, $
    DARKMLAT=darkmlat,DARKMLT=darkmlt,DARKGLAT=darkglat, $
    DARKGLON=darkglon, DARKSTID=darkstid,DARKNUM=darknum, $
    REGIONALSME=regionalsme,REGIONALSML=regionalsml, $
    REGIONALSMU=regionalsmu, $
    REGIONALMLAT=regionalmlat,REGIONALMLT=regionalmlt, $
    REGIONALGLAT=regionalglat, $
    REGIONALGLON=regionalglon, REGIONALSTID=regionalstid, $
    REGIONALNUM=regionalnum, $
    SMR=smr,LTSMR=ltsmr,LTNUM=ltnum,NSMR=nsmr, $
    BGSE=bgse,BGSM=bgsm,VGSE=vgse,VGSM=vgsm, $
    PDYN=pdyn,EPSILON=epsilon,NEWELL=newell, CLOCKGSE=clockgse, $
    CLOCKGSM=clockgsm,DENSITY=density



    compile_opt idl2
    inxdata=!NULL
    logon = supermag_logon()
    time_range = time_double(input_time_range)
    time_str = time_string(time_range[0],tformat='YYYY-MM-DDThh:mm')
    extent = total(time_range*[-1,1])

    ; construct URL
    urlstr='services/indices.php?fmt=json&logon='+logon
    urlstr+='&start='+time_str
    urlstr+='&extent='+string(extent,FORMAT='(I12.12)')

    if keyword_set(INDICESALL) then urlstr+='&indices=all' $
    else begin
        istr=''
        if keyword_set(SME) then istr+=',sme'
        if keyword_set(SML) then istr+=',sml'
        if keyword_set(SMU) then istr+=',smu'
        if keyword_set(MLAT) then istr+=',mlat'
        if keyword_set(MLT)  then istr+=',mlt'
        if keyword_set(GLAT) then istr+=',glat'
        if keyword_set(GLON) then istr+=',glon'
        if keyword_set(STID) then istr+=',stid'
        if keyword_set(NUM) then istr+=',num'

        if keyword_set(SUNSME) then istr+=',smes'
        if keyword_set(SUNSML) then istr+=',smls'
        if keyword_set(SUNSMU) then istr+=',smus'
        if keyword_set(SUNMLAT) then istr+=',mlats'
        if keyword_set(SUNMLT) then istr+=',mlts'
        if keyword_set(SUNGLAT) then istr+=',glats'
        if keyword_set(SUNGLON) then istr+=',glons'
        if keyword_set(SUNSTID) then istr+=',stids'
        if keyword_set(SUNNUM) then istr+=',nums'

        if keyword_set(DARKSME) then istr+=',smed'
        if keyword_set(DARKSML) then istr+=',smld'
        if keyword_set(DARKSMU) then istr+=',smud'
        if keyword_set(DARKMLAT) then istr+=',mlatd'
        if keyword_set(DARKMLT) then istr+=',mltd'
        if keyword_set(DARKGLAT) then istr+=',glatd'
        if keyword_set(DARKGLON) then istr+=',glond'
        if keyword_set(DARKSTID) then istr+=',stidd'
        if keyword_set(DARKNUM) then istr+=',numd'

        if keyword_set(REGIONALSME) then istr+=',smer'
        if keyword_set(REGIONALSML) then istr+=',smlr'
        if keyword_set(REGIONALSMU) then istr+=',smur'
        if keyword_set(REGIONALMLAT) then istr+=',mlatr'
        if keyword_set(REGIONALMLT) then istr+=',mltr'
        if keyword_set(REGIONALGLAT) then istr+=',glatr'
        if keyword_set(REGIONALGLON) then istr+=',glonr'
        if keyword_set(REGIONALSTID) then istr+=',stidr'
        if keyword_set(REGIONALNUM) then istr+=',numr'

        if keyword_set(SMR) then istr+=',smr'
        if keyword_set(LTSMR) then istr+=',smrlt'
        if keyword_set(LTNUM) then istr+=',ltnum'
        if keyword_set(NSMR) then istr+=',smrnum'
        if strlen(istr) ne 0 then urlstr+='&indices=' + strmid(istr,1)
    endelse

    if keyword_set(IMFALL) then urlstr+='&imf=all' $
    else begin
        istr=''
        if keyword_set(BGSE) then istr+=',bgse'
        if keyword_set(BGSM) then istr+=',bgsm'
        if keyword_set(VGSE) then istr+=',vgse'
        if keyword_set(VGSM) then istr+=',vgsm'
        if strlen(istr) ne 0 then urlstr+='&imf=' + strmid(istr,1)

    endelse

    if keyword_set(SWIALL) then urlstr+='&swi=all' $
    else begin
        istr=''
        if keyword_set(PDYN) then istr+=',pdyn'
        if keyword_set(EPSILON) then istr+=',epsilon'
        if keyword_set(NEWELL) then istr+=',newell'
        if keyword_set(CLOCKGSE) then istr+=',clockgse'
        if keyword_set(CLOCKGSM) then istr+=',clockgsm'
        if keyword_set(DENSITY) then istr+=',density'
        if strlen(istr) ne 0 then urlstr+='&swi=' + strmid(istr,1)
    endelse

    urlstr+='&idl'

  ; print out URL for debugging

  ;  print, urlstr

  ; get the string array of JSON data

  strings=SuperMAGGetUrl(urlstr)

  ; if no indices are found this is not an error
  ; the routine will just return a null pointer
  ; if an error does occur, set the
  ; ERROR keyward to the error string

  if (n_elements(strings) gt 1) then begin ; valid JSON data, so indices found
    jstring=strjoin(strings[1:*])
    inxdata=json_parse(jstring,/TOARRAY,/TOSTRUCT)
    return, 1
  endif else if (strmid(strings[0],0,2) ne 'OK') then begin ; Error condition
    errstr=strings
    return, 0
  endif else return,1 ; No JSON data but service still responded with OK, not an error

END

FUNCTION SuperMAGGetIndicesArray,input_time_range, $
    tval,error=errstr, $
    SME=sme,SML=sml,SMU=smu, $
    MLAT=mlat,MLT=mlt,GLAT=glat,GLON=glon,STID=stid,NUM=num, $
    SUNSME=sunsme,SUNSML=sunsml,SUNSMU=sunsmu, $
    SUNMLAT=sunmlat,SUNMLT=sunmlt,SUNGLAT=sunglat,SUNGLON=sunglon, $
    SUNSTID=sunstid,SUNNUM=sunnum, $
    DARKSME=darksme,DARKSML=darksml,DARKSMU=darksmu, $
    DARKMLAT=darkmlat,DARKMLT=darkmlt,DARKGLAT=darkglat, $
    DARKGLON=darkglon, DARKSTID=darkstid,DARKNUM=darknum, $
    REGIONALSME=regionalsme,REGIONALSML=regionalsml, $
    REGIONALSMU=regionalsmu, $
    REGIONALMLAT=regionalmlat,REGIONALMLT=regionalmlt, $
    REGIONALGLAT=regionalglat, $
    REGIONALGLON=regionalglon, REGIONALSTID=regionalstid, $
    REGIONALNUM=regionalnum, $
    SMR=smr,LTSMR=ltsmr,LTNUM=ltnum,NSMR=nsmr, $
    BGSE=bgse,BGSM=bgsm,VGSE=vgse,VGSM=vgsm, $
    PDYN=pdyn,EPSILON=epsilon,NEWELL=newell, CLOCKGSE=clockgse, $
    CLOCKGSM=clockgsm,DENSITY=density


    compile_opt idl2
    inxdata=!NULL
    tval=!NULL
    logon = supermag_logon()
    time_range = time_double(input_time_range)
    time_str = time_string(time_range[0],tformat='YYYY-MM-DDThh:mm')
    extent = total(time_range*[-1,1])

    urlstr='services/indices.php?fmt=json&logon='+logon
    urlstr+='&start='+time_str
    urlstr+='&extent='+string(extent,FORMAT='(I12.12)')


    istr=''
    if arg_present(SME) then istr+=',sme'
    if arg_present(SML) then istr+=',sml'
    if arg_present(SMU) then istr+=',smu'
    if arg_present(MLAT) then istr+=',mlat'
    if arg_present(MLT)  then istr+=',mlt'
    if arg_present(GLAT) then istr+=',glat'
    if arg_present(GLON) then istr+=',glon'
    if arg_present(STID) then istr+=',stid'
    if arg_present(NUM) then istr+=',num'

    if arg_present(SUNSME) then istr+=',smes'
    if arg_present(SUNSML) then istr+=',smls'
    if arg_present(SUNSMU) then istr+=',smus'
    if arg_present(SUNMLAT) then istr+=',mlats'
    if arg_present(SUNMLT) then istr+=',mlts'
    if arg_present(SUNGLAT) then istr+=',glats'
    if arg_present(SUNGLON) then istr+=',glons'
    if arg_present(SUNSTID) then istr+=',stids'
    if arg_present(SUNNUM) then istr+=',nums'
    if arg_present(DARKSME) then istr+=',smed'
    if arg_present(DARKSML) then istr+=',smld'
    if arg_present(DARKSMU) then istr+=',smud'
    if arg_present(DARKMLAT) then istr+=',mlatd'
    if arg_present(DARKMLT) then istr+=',mltd'
    if arg_present(DARKGLAT) then istr+=',glatd'
    if arg_present(DARKGLON) then istr+=',glond'
    if arg_present(DARKSTID) then istr+=',stidd'
    if arg_present(DARKNUM) then istr+=',numd'

    if arg_present(REGIONALSME) then istr+=',smer'
    if arg_present(REGIONALSML) then istr+=',smlr'
    if arg_present(REGIONALSMU) then istr+=',smur'
    if arg_present(REGIONALMLAT) then istr+=',mlatr'
    if arg_present(REGIONALMLT) then istr+=',mltr'
    if arg_present(REGIONALGLAT) then istr+=',glatr'
    if arg_present(REGIONALGLON) then istr+=',glonr'
    if arg_present(REGIONALSTID) then istr+=',stidr'
    if arg_present(REGIONALNUM) then istr+=',numr'

    if arg_present(SMR) then istr+=',smr'
    if arg_present(LTSMR) then istr+=',smrlt'
    if arg_present(LTNUM) then istr+=',ltnum'
    if arg_present(NSMR) then istr+=',smrnum'
    if strlen(istr) ne 0 then urlstr+='&indices=' + strmid(istr,1)

    istr=''
    if arg_present(BGSE) then istr+=',bgse'
    if arg_present(BGSM) then istr+=',bgsm'
    if arg_present(VGSE) then istr+=',vgse'
    if arg_present(VGSM) then istr+=',vgsm'
    if strlen(istr) ne 0 then urlstr+='&imf=' + strmid(istr,1)


    istr=''
    if arg_present(PDYN) then istr+=',pdyn'
    if arg_present(EPSILON) then istr+=',epsilon'
    if arg_present(NEWELL) then istr+=',newell'
    if arg_present(CLOCKGSE) then istr+=',clockgse'
    if arg_present(CLOCKGSM) then istr+=',clockgsm'
    if arg_present(DENSITY) then istr+=',density'
    if strlen(istr) ne 0 then urlstr+='&swi=' + strmid(istr,1)

    urlstr+='&idl'


  ; print out URL for debugging

  ; print, urlstr

  ; get the string array of JSON data

  strings=SuperMAGGetUrl(urlstr)

  ; if no indices are found this is not an error
  ; the routine will just return a null pointer
  ; if an error does occur, set the
  ; ERROR keyward to the error string

  if (n_elements(strings) gt 1) then begin ; valid JSON data, so indices found
    jstring=strjoin(strings[1:*])
    inxdata=json_parse(jstring,/TOARRAY,/TOSTRUCT)
    nvec=n_elements(inxdata)

    if nvec eq 0 then return, s
    tval=dblarr(nvec)
    tval=inxdata[*].tval

    if arg_present(SME) then sme=inxdata[*].sme
    if arg_present(SML) then sml=inxdata[*].sml
    if arg_present(SMU) then smu=inxdata[*].smu


    if arg_present(MLAT) then begin
      if arg_present(SME) or $
         (arg_present(SML) and arg_present(SMU)) then begin
        mlat=dblarr(nvec,2)
        mlat[*,0]=inxdata[*].smlmlat
        mlat[*,1]=inxdata[*].smumlat
      endif else if arg_present(SML) then begin
        mlat=dblarr(nvec)
        mlat[*]=inxdata[*].smlmlat
      endif else if arg_present(SMU) then begin
        mlat=dblarr(nvec)
        mlat[*]=inxdata[*].smumlat
      endif
    endif

    if arg_present(MLT) then begin
      if arg_present(SME) or $
         (arg_present(SML) and arg_present(SMU)) then begin
        mlt=dblarr(nvec,2)
        mlt[*,0]=inxdata[*].smlmlt
        mlt[*,1]=inxdata[*].smumlt
      endif else if arg_present(SML) then begin
        mlt=dblarr(nvec)
        mlt[*]=inxdata[*].smlmlt
      endif else if arg_present(SMU) then begin
        mlt=dblarr(nvec)
        mlt[*]=inxdata[*].smumlt
      endif
    endif

    if arg_present(GLAT) then begin
      if arg_present(SME) or $
         (arg_present(SML) and arg_present(SMU)) then begin
        glat=dblarr(nvec,2)
        glat[*,0]=inxdata[*].smlglat
        glat[*,1]=inxdata[*].smuglat
      endif else if arg_present(SML) then begin
        glat=dblarr(nvec)
        glat[*]=inxdata[*].smlglat
      endif else if arg_present(SMU) then begin
        glat=dblarr(nvec)
        glat[*]=inxdata[*].smuglat
      endif
    endif

    if arg_present(GLON) then begin
      if arg_present(SME) or $
         (arg_present(SML) and arg_present(SMU)) then begin
        glon=dblarr(nvec,2)
        glon[*,0]=inxdata[*].smlglon
        glon[*,1]=inxdata[*].smuglon
      endif else if arg_present(SML) then begin
        glon=dblarr(nvec)
        glon[*]=inxdata[*].smlglon
      endif else if arg_present(SMU) then begin
        glon=dblarr(nvec)
        glon[*]=inxdata[*].smuglon
      endif
    endif

    if arg_present(STID) then begin
      if arg_present(SME) or $
         (arg_present(SML) and arg_present(SMU)) then begin
        stid=strarr(nvec,2)
        stid[*,0]=inxdata[*].smlstid
        stid[*,1]=inxdata[*].smustid
      endif else if arg_present(SML) then begin
        stid=strarr(nvec)
        stid[*]=inxdata[*].smlstid
      endif else if arg_present(SMU) then begin
        stid=strarr(nvec)
        stid[*]=inxdata[*].smustid
      endif
    endif

    if arg_present(NUM) then num=long(inxdata[*].smenum)


    if arg_present(SUNSME) then sunsme=inxdata[*].smes
    if arg_present(SUNSML) then sunsml=inxdata[*].smls
    if arg_present(SUNSMU) then sunsmu=inxdata[*].smus

    if arg_present(SUNMLAT) then begin
      if arg_present(SUNSME) or $
         (arg_present(SUNSML) and arg_present(SUNSMU)) then begin
        sunmlat=dblarr(nvec,2)
        sunmlat[*,0]=inxdata[*].smlsmlat
        sunmlat[*,1]=inxdata[*].smusmlat
      endif else if arg_present(SML) then begin
        sunmlat=dblarr(nvec)
        sunmlat[*]=inxdata[*].smlsmlat
      endif else if arg_present(SMU) then begin
        sunmlat=dblarr(nvec)
        sunmlat[*]=inxdata[*].smusmlat
      endif
    endif

    if arg_present(SUNMLT) then begin
      if arg_present(SUNSME) or $
         (arg_present(SUNSML) and arg_present(SUNSMU)) then begin
        sunmlt=dblarr(nvec,2)
        sunmlt[*,0]=inxdata[*].smlsmlt
        sunmlt[*,1]=inxdata[*].smusmlt
      endif else if arg_present(SML) then begin
        sunmlt=dblarr(nvec)
        sunmlt[*]=inxdata[*].smlsmlt
      endif else if arg_present(SMU) then begin
        sunmlt=dblarr(nvec)
        sunmlt[*]=inxdata[*].smusmlt
      endif
    endif

   if arg_present(SUNGLAT) then begin
      if arg_present(SUNSME) or $
         (arg_present(SUNSML) and arg_present(SUNSMU)) then begin
        sunglat=dblarr(nvec,2)
        sunglat[*,0]=inxdata[*].smlsglat
        sunglat[*,1]=inxdata[*].smusglat
      endif else if arg_present(SUNSML) then begin
        sunglat=dblarr(nvec)
        sunglat[*]=inxdata[*].smlsglat
      endif else if arg_present(SUNSMU) then begin
        sunglat=dblarr(nvec)
        sunglat[*]=inxdata[*].smusglat
      endif
    endif

    if arg_present(SUNGLON) then begin
      if arg_present(SUNSME) or $
         (arg_present(SUNSML) and arg_present(SUNSMU)) then begin
        sunglon=dblarr(nvec,2)
        sunglon[*,0]=inxdata[*].smlsglon
        sunglon[*,1]=inxdata[*].smusglon
      endif else if arg_present(SUNSML) then begin
        sunglon=dblarr(nvec)
        sunglon[*]=inxdata[*].smlsglon
      endif else if arg_present(SUNSMU) then begin
        sunglon=dblarr(nvec)
        sunglon[*]=inxdata[*].smusglon
      endif
    endif

    if arg_present(SUNSTID) then begin
      if arg_present(SUNSME) or $
         (arg_present(SUNSML) and arg_present(SUNSMU)) then begin
        sunstid=strarr(nvec,2)
        sunstid[*,0]=inxdata[*].smlsstid
        sunstid[*,1]=inxdata[*].smusstid
      endif else if arg_present(SUNSML) then begin
        sunstid=strarr(nvec)
        sunstid[*]=inxdata[*].smlsstid
      endif else if arg_present(SUNSMU) then begin
        sunstid=strarr(nvec)
        sunstid[*]=inxdata[*].smusstid
      endif
    endif

    if arg_present(SUNNUM) then sunnum=long(inxdata[*].smesnum)


    if arg_present(DARKSME) then darksme=inxdata[*].smed
    if arg_present(DARKSML) then darksml=inxdata[*].smld
    if arg_present(DARKSMU) then darksmu=inxdata[*].smud

    if arg_present(DARKMLAT) then begin
      if arg_present(DARKSME) or $
         (arg_present(DARKSML) and arg_present(DARKSMU)) then begin
        darkmlat=dblarr(nvec,2)
        darkmlat[*,0]=inxdata[*].smldmlat
        darkmlat[*,1]=inxdata[*].smudmlat
      endif else if arg_present(SML) then begin
        darkmlat=dblarr(nvec)
        darkmlat[*]=inxdata[*].smldmlat
      endif else if arg_present(SMU) then begin
        darkmlat=dblarr(nvec)
        darkmlat[*]=inxdata[*].smudmlat
      endif
    endif

    if arg_present(DARKMLT) then begin
      if arg_present(DARKSME) or $
         (arg_present(DARKSML) and arg_present(DARKSMU)) then begin
        darkmlt=dblarr(nvec,2)
        darkmlt[*,0]=inxdata[*].smldmlt
        darkmlt[*,1]=inxdata[*].smudmlt
      endif else if arg_present(SML) then begin
        darkmlt=dblarr(nvec)
        darkmlt[*]=inxdata[*].smldmlt
      endif else if arg_present(SMU) then begin
        darkmlt=dblarr(nvec)
        darkmlt[*]=inxdata[*].smudmlt
      endif
    endif

    if arg_present(DARKGLAT) then begin
      if arg_present(DARKSME) or $
         (arg_present(DARKSML) and arg_present(DARKSMU)) then begin
        darkglat=dblarr(nvec,2)
        darkglat[*,0]=inxdata[*].smldglat
        darkglat[*,1]=inxdata[*].smudglat
      endif else if arg_present(DARKSML) then begin
        darkglat=dblarr(nvec)
        darkglat[*]=inxdata[*].smldglat
      endif else if arg_present(DARKSMU) then begin
        darkglat=dblarr(nvec)
        darkglat[*]=inxdata[*].smudglat
      endif
    endif

    if arg_present(DARKGLON) then begin
      if arg_present(DARKSME) or $
         (arg_present(DARKSML) and arg_present(DARKSMU)) then begin
        darkglon=dblarr(nvec,2)
        darkglon[*,0]=inxdata[*].smldglon
        darkglon[*,1]=inxdata[*].smudglon
      endif else if arg_present(DARKSML) then begin
        darkglon=dblarr(nvec)
        darkglon[*]=inxdata[*].smldglon
      endif else if arg_present(DARKSMU) then begin
        darkglon=dblarr(nvec)
        darkglon[*]=inxdata[*].smudglon
      endif
    endif

    if arg_present(DARKSTID) then begin
      if arg_present(DARKSME) or $
         (arg_present(DARKSML) and arg_present(DARKSMU)) then begin
        darkstid=strarr(nvec,2)
        darkstid[*,0]=inxdata[*].smldstid
        darkstid[*,1]=inxdata[*].smudstid
      endif else if arg_present(DARKSML) then begin
        darkstid=strarr(nvec)
        darkstid[*]=inxdata[*].smldstid
      endif else if arg_present(DARKSMU) then begin
        darkstid=strarr(nvec)
        darkstid[*]=inxdata[*].smudstid
      endif
    endif
    if arg_present(DARKNUM) then darknum=long(inxdata[*].smednum)



    if arg_present(REGIONALSME) then regionalsme=transpose(inxdata[*].smer)
    if arg_present(REGIONALSML) then regionalsml=transpose(inxdata[*].smlr)
    if arg_present(REGIONALSMU) then regionalsmu=transpose(inxdata[*].smur)

    if arg_present(REGIONALMLAT) then begin
      if arg_present(REGIONALSME) or $
         (arg_present(REGIONALSML) and arg_present(REGIONALSMU)) then begin
        regionalmlat=dblarr(24,2,nvec)
        regionalmlat[*,0,*]=inxdata[*].smlrmlat
        regionalmlat[*,1,*]=inxdata[*].smurmlat
        regionalmlat=transpose(regionalmlat)
      endif else if arg_present(SML) then begin
        regionalmlat=dblarr(nvec,24)
        regionalmlat[*,*]=inxdata[*].smlrmlat[*]
      endif else if arg_present(SMU) then begin
        regionalmlat=dblarr(nvec,24)
        regionalmlat[*,*]=inxdata[*].smurmlat[*]
      endif
    endif

    if arg_present(REGIONALMLT) then begin
      if arg_present(REGIONALSME) or $
         (arg_present(REGIONALSML) and arg_present(REGIONALSMU)) then begin
        regionalmlt=dblarr(24,2,nvec)
        regionalmlt[*,0,*]=inxdata[*].smlrmlt
        regionalmlt[*,1,*]=inxdata[*].smurmlt
        regionalmlt=transpose(regionalmlt)
      endif else if arg_present(SML) then begin
        regionalmlt=dblarr(nvec,24)
        regionalmlt[*,*]=inxdata[*].smlrmlt[*]
      endif else if arg_present(SMU) then begin
        regionalmlt=dblarr(nvec,24)
        regionalmlt[*,*]=inxdata[*].smurmlt[*]
      endif
    endif

    if arg_present(REGIONALGLAT) then begin
      if arg_present(REGIONALSME) or $
         (arg_present(REGIONALSML) and arg_present(REGIONALSMU)) then begin
        regionalglat=dblarr(24,2,nvec)
        regionalglat[*,0,*]=inxdata[*].smlrglat
        regionalglat[*,1,*]=inxdata[*].smurglat
        regionalglat=transpose(regionalglat)
      endif else if arg_present(SML) then begin
        regionalglat=dblarr(nvec,24)
        regionalglat[*,*]=inxdata[*].smlrglat[*]
      endif else if arg_present(SMU) then begin
        regionalglat=dblarr(nvec,24)
        regionalglat[*,*]=inxdata[*].smurglat[*]
      endif
    endif

    if arg_present(REGIONALGLON) then begin
      if arg_present(REGIONALSME) or $
         (arg_present(REGIONALSML) and arg_present(REGIONALSMU)) then begin
        regionalglon=dblarr(24,2,nvec)
        regionalglon[*,0,*]=inxdata[*].smlrglon
        regionalglon[*,1,*]=inxdata[*].smurglon
        regionalglon=transpose(regionalglon)
      endif else if arg_present(SML) then begin
        regionalglon=dblarr(nvec,24)
        regionalglon[*,*]=inxdata[*].smlrglon[*]
      endif else if arg_present(SMU) then begin
        regionalglon=dblarr(nvec,24)
        regionalglon[*,*]=inxdata[*].smurglon[*]
      endif
    endif

    if arg_present(REGIONALSTID) then begin
      if arg_present(REGIONALSME) or $
         (arg_present(REGIONALSML) and arg_present(REGIONALSMU)) then begin
        regionalstid=strarr(24,2,nvec)
        regionalstid[*,0,*]=inxdata[*].smlrstid
        regionalstid[*,1,*]=inxdata[*].smurstid
        regionalstid=transpose(regionalstid)
      endif else if arg_present(SML) then begin
        regionalstid=strarr(nvec,24)
        regionalstid[*,*]=inxdata[*].smlrstid[*]
      endif else if arg_present(SMU) then begin
        regionalstid=strarr(nvec,24)
        regionalstid[*,*]=inxdata[*].smurstid[*]
      endif
    endif
    if arg_present(REGIONALNUM) then regionalnum=transpose(inxdata[*].smernum)

    if arg_present(SMR) then smr=inxdata[*].smr
    if arg_present(LTSMR) then begin
       ltsmr=dblarr(nvec,4)
       ltsmr[*,0]=inxdata[*].smr00
       ltsmr[*,1]=inxdata[*].smr06
       ltsmr[*,2]=inxdata[*].smr12
       ltsmr[*,3]=inxdata[*].smr18
    endif

    if arg_present(LTNUM) then begin
      ltnum=intarr(nvec,4)
      ltnum[*,0]=inxdata[*].smrnum00
      ltnum[*,1]=inxdata[*].smrnum06
      ltnum[*,2]=inxdata[*].smrnum12
      ltnum[*,3]=inxdata[*].smrnum18
    endif

    if arg_present(NSMR) then nsmr=inxdata[*].smrnum

    if arg_present(BGSE) then begin
       bgse=dblarr(nvec,3)
       bgse[*,0]=inxdata[*].bgse.x
       bgse[*,1]=inxdata[*].bgse.y
       bgse[*,2]=inxdata[*].bgse.z
    endif

    if arg_present(BGSM) then begin
       bgsm=dblarr(nvec,3)
       bgsm[*,0]=inxdata[*].bgsm.x
       bgsm[*,1]=inxdata[*].bgsm.y
       bgsm[*,2]=inxdata[*].bgsm.z
    endif

    if arg_present(VGSE) then begin
       bgse=dblarr(nvec,3)
       bgse[*,0]=inxdata[*].vgse.x
       bgse[*,1]=inxdata[*].vgse.y
       bgse[*,2]=inxdata[*].vgse.z
    endif

    if arg_present(VGSM) then begin
       vgsm=dblarr(nvec,3)
       vgsm[*,0]=inxdata[*].vgsm.x
       vgsm[*,1]=inxdata[*].vgsm.y
       vgsm[*,2]=inxdata[*].vgsm.z
    endif

    if arg_present(PDYN) then pdyn=inxdata[*].dynpres
    if arg_present(EPSILON) then epsilon=inxdata[*].epsilon
    if arg_present(NEWELL) then newell=inxdata[*].newell
    if arg_present(CLOCKGSE) then clockgse=inxdata[*].clockgse
    if arg_present(CLOCKGSM) then clockgsm=inxdata[*].clockgsm
    if arg_present(DENSITY) then density=inxdata[*].density

    return, 1
  endif else if (strmid(strings[0],0,2) ne 'OK') then begin ; Error condition
     errstr=strings
     return, 0
  endif else return,1 ; No JSON data but service still responded with OK, not an error



END


pro supermag_api
    compile_opt idl2
    ; Do nothing, but needed to let IDL compile the above routines.
end
