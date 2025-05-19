;%W% %G%
;
; IC_GCI_TO_GEO - return a transformation matrix
;
; PURPOSE:  Calculate the transformation matrix from GCI
;           coordinates to GEO coordinates at a given date and time.
;
; UNIT TYPE:  SUBROUTINE
;
; INVOCATION METHOD:  CALL IC_GCI_TO_GEO (orb_pos_time,
;                                         transform_matrix)
;
; argUMENT LIST:
;
; NAME	                  TYPE   USE  DESCRIPTION
; ----                   ----   ---  -----------
; orb_pos_time(2)        I*4    I    time OF ORB. VECTOR, year-day-MILLI OF day
; transform_matrix(3,3)  R*8    O    TRANSFORMATION MATRIX
;
; FILE/RECORD REFERENCES:  NONE
;
; EXTERNAL VARIABLES:  NONE
;
; EXTERNAL REFERENCES:
;	IC_GRNWCH_SIDEREAL - Returns the Greenwich sidereal time in radians
;	F01CKF - Multiplies two matrices
;	IC_CONV_MATRIX - Returns the conversion matrix to rotate
;                       from mean of date to true of date
;
; ABNORMAL TERMINATION CONDITIONS, ERROR MESSAGES:  NONE
;
; ASSUMPTIONS, CONstrAINTS, REstrICTIONS:  NONE
;
; DEVELOPMENT HISTORY
;
; AUTHOR	CHANGE ID	RELEASE	  DATE	    DESCRIPTION OF CHANGE
; ------	---------	-------   ----	    ---------------------
; J. LUBELCZYK                 B1R1      11/21/90  INITIAL PDL
; J. Lubelczyk			B1R1      12/10/90  CODING
; J. Lubelczyk                           09/18/91  Updated to return true
;                                                  of date trans matrix
; J. LUBELCZYK ICCR #83, CCR #'S 130, 137 11/91    B3 update
;
; NOTES:
;

PRO ic_gci_to_geo, orb_pos_time, transform_matrix


    mean_matrix = DBLARR(3,3)
	transform_matrix = DBLARR(3,3) ;transformation matrix
	cmatrix = DBLARR(3,3)	      ;the conversion matrix to rotate from
                                      ;mean of date to true of date

	ic_grnwch_sidereal, orb_pos_time, grnwch_sidereal_time

;
;   calculate the sin and cos of the greenwich mean sidereal time
;
	sin_gst = sin(grnwch_sidereal_time)
	cos_gst = cos(grnwch_sidereal_time)

;
;   Fill the mean of date transformation matrix using the sin and cos
;    of the greenwich mean sidereal time
;
	mean_matrix(0,0) = cos_gst
	mean_matrix(0,1) = -sin_gst
	mean_matrix(0,2) = 0
	mean_matrix(1,0) = sin_gst
	mean_matrix(1,1) = cos_gst
	mean_matrix(1,2) = 0
	mean_matrix(2,0) = 0
	mean_matrix(2,1) = 0
	mean_matrix(2,2) = 1

	ic_conv_matrix,orb_pos_time, cmatrix

    transform_matrix = TRANSPOSE(TRANSPOSE(mean_matrix) # TRANSPOSE(cmatrix))

END

