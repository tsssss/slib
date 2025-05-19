;%W% %G%
;
; IC_GRNWCH_SIDEREAL - return the greenwich true sidereal time in radians
;
; PURPOSE:  Calculate the true of date greenwich sidereal time in radians.
;
; NAME	                  TYPE   USE  DESCRIPTION
; ----                   ----   ---  -----------
; orb_pos_time(2)        I*4    I    time OF ORB. VECTOR, year-day-MILLI OF day
; gst		          R*8    O    GREENWICH MEAN SIDEREAL time
; EXTERNAL REFERENCES:
;	IC_GET_NUT_ANGLES - Returns angles necessary to adjust the Greenwich
;                          hour angle to true of date
; NOTES:
; 1)  THE ORIGINAL ALGORITHM USED WAS COPIED FROM A SHORT PROGRAM BY 
;     G. D. MEAD, INCLUDED IN 'GEOPHYSICAL COORDINATE 
;                      TRANSFORMATIONS' BY CHRISTOPHER T. RUSSELL
; 2)  THIS VERSION INCORPORATES SEVERAL CHANGES TO CALCULATE THE GREENWICH
;     MEAN SIDEREAL time CORRECTLY ON THE J2000 COORDINATE SYSTEM.  THE
;     PREVIOUS VERSION WAS ONLY CORRECT IN THE B1950 COORDINATE SYSTEM.
; 3)  NOW RETURNS THE TRUE OF DATE GREENWICH SIDEREAL time ON THE J2000 SYS

PRO ic_grnwch_sidereal,orb_pos_time, gst

	half  = DOUBLE(0.50)
        C0    = DOUBLE(1.7533685592332653)     ;Polynomial Coef.
        C1    = DOUBLE(628.33197068884084)     ;Polynomial Coef.
        C2    = DOUBLE(0.67707139449033354E-05)  ;Polynomial Coef.
        C3    = DOUBLE(6.3003880989848915)     ;Polynomial Coef.
        C4    = DOUBLE(-0.45087672343186841E-09) ;Polynomial Coef.
        TWOPI = DOUBLE(6.283185307179586)      ;Two PI


        year = orb_pos_time(0)/1000
        day  = orb_pos_time(0) MOD 1000

;
;   Convert the given millisecond of day [orb_pos_time(1)] to second of day.
;
	secs = (DOUBLE(orb_pos_time(1)))/DOUBLE(1000.0)

;
;    Begin calculating the greenwich mean sidereal time **
;
	fday = secs/86400.00
	dj = DOUBLE(365*(year-1900)+(year-1901)/4+day-half)


;
;	      THE NEXT STATEMENT CAUSES THE REFERENCE EPOCH TO BE SHIFTED	
;	   TO THE J2000 REFERENCE EPOCH.
;

	T = (dj-DOUBLE(36525.0))/DOUBLE(36525.0)
        gst = DOUBLE(C0 + T*(C1 + T*(C2 + C4*T)) + C3*fday)
        gst = DOUBLE(gst MOD TWOPI)
        IF (gst LT DOUBLE(0.0)) THEN gst = gst + TWOPI

;
;   Convert gst to true of date by adjusting for nutation
;
	ic_get_nut_angles, T, deleps, delpsi, eps
	gst = gst + delpsi*cos(eps+deleps)

        END
