;This program is modified by TIAN Sheng, 06/05/2009

;============================================================================================================================
;Auxiliary routines
;============================================================================================================================
PRO drtoll, x, y, z, latitude, longitude, radius

latitude = Atan2d(z, Sqrt(x * x + y * y))
longitude = Atan2d(y, x)
radius = Sqrt(x * x + y * y + z * z)

temp = Where(x EQ 0) AND Where(y EQ 0)
dim = Size(temp, /N_Dimensions)
IF (dim NE 0) THEN BEGIN
	latitude[tmp] = Double(90D * z[tmp] / Abs(z[tmp]))
	longitude[tmp] = 0D
	radius = 6378D
ENDIF

temp = Where(longitude LT 0)
ndim = Size(temp, /N_Dimensions)
IF (ndim NE 0) THEN BEGIN
	longitude[temp] = longitude[temp] + 360D
ENDIF

END