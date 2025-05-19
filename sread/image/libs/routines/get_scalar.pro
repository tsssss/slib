;This program is modified by TIAN Sheng, 06/05/2009

;============================================================================================================================
;Auxiliary routines
;============================================================================================================================

PRO get_scalar, $
;input variables
	Ox, Oy, Oz, $
	Lx, Ly, Lz, $
	emission_height, $
	col,row, $
;output variables
	s, f, margin, nmargin

;Equatoral radius (km) and polar flatening of the earth
;Ref: Table 15.4, 'Explanatory Supplement to the
;Astronomical Almanac,' K. Seidelmann, ed. (1992).


;initialize output
 s  = DblArr(col, row)
 s1 = DblArr(col, row)
 s2 = DblArr(col, row)

;polar radius and eqator radius
f = 298.257D
R_equator = 6378.136D
R_polar = R_equator * (1D - 1D / f)

;get radii to assumed emission height
R_equator = R_equator + emission_height
R_polar = R_polar + emission_height

;get flattening factor based on new radii
f = (R_equator - R_polar) / R_equator

;get elements of quadratic formula
a = fgeodeP(R_equator, R_polar, Lx, Ly, Lz, Lx, Ly, Lz)
b = fgeodeP(R_equator, R_polar, Lx, Ly, Lz, Ox, Oy, Oz) * 2D
c = fgeodeP(R_equator, R_polar, Ox, Oy, Oz, Ox, Oy, Oz) - R_equator * R_equator

;check solutions to quadratic formula
determinant = b * b - 4D * a * c

;remove points off the earth
determinant = determinant > 0.0
margin = Where(determinant EQ 0.0, nmargin)
IF nmargin GT 0 THEN b(margin) = 0D

;solve quadratic formula (choose smallest solution)
s1 = (-b + Sqrt(determinant)) / (2D * a)
s2 = (-b - Sqrt(determinant)) / (2D * a)
s = s1 < s2

END
