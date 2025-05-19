;This program is modified by TIAN Sheng, 06/05/2009

;============================================================================================================================
;Auxiliary routines
;============================================================================================================================

PRO vector_to_ra_decP,x,y,z,ra,dec

    fill_value = -1.D31
    ndx = WHERE(z NE 0,count)
    IF(count GT 0) THEN dec(ndx) = 90.*z(ndx)/ABS(z(ndx))

    tmp = SQRT(x*x + y*y)
    ndx = WHERE(tmp NE 0,count)
    IF (count GT 0) THEN BEGIN
      dec(ndx) = atan2d(z(ndx),tmp(ndx))
      ra(ndx)  = atan2d(y(ndx),x(ndx))
    ENDIF

    ndx = WHERE((ra LT 0) AND (ra NE fill_value),count)
    IF (count GT 0) THEN ra(ndx) = ra(ndx) + 360.

END