

PRO solar_angular, $
;input variable
time, $
;output variable
GST, ra, dec

;program to calculate Greenwich mean Sidereal Time(GST) and position of sun
;in geocentric inertial coordinates from given year, day_of_year and UT:
; 10-5-97  --- added polar filename support
; 6-29-2000 v3 --- now specifically for IMAGE imageinfo structure
; notes: GST is in degrees
;TIAN Sheng 07/05/09

;degree_to_radian
degree_to_radian = 180D / !DPI

;get year, day_of_year and UT_second
year = Long(time[0]) / 1000
day_of_year = Long(time[0]) MOD 1000
UT_second = time[1] / 1000D

;get GST
day = UT_second / 864D2
dj = 365D * (year - 1900) + (year - 1901) / 4 + day_of_year + day - 0.5
t = dj / 36525.0
vl = (279.696678D + 0.9856473354D * dj) MOD 360
GST = (279.690983D + 0.9856473354D * dj + 360 * day + 180) MOD 360

;get solar_lon
g = (358.475845D + 0.985600267D * dj) MOD 360.
solar_lon = vl + (1.91946 - 0.004789 * t) * Sin(g * degree_to_radian) + $
	0.020094 * Sin(2.0 * g * degree_to_radian)

;get dec and ra
oblique = (23.45229 - 0.0130125 * t)
slp = (solar_lon - 0.005686)
sin_alpha= Sin(oblique * degree_to_radian) * Sin(slp * degree_to_radian)
cos_alpha= Sqrt(1.0 - sin_alpha * sin_alpha)
dec = Atan(sin_alpha / cos_alpha) / degree_to_radian
cot_oblique = Cos(oblique * degree_to_radian) / Sin(oblique * degree_to_radian)
ra = 180. - (Atan(cot_oblique * sin_alpha / cos_alpha, $
	- Cos(slp * degree_to_radian) / cos_alpha ) / degree_to_radian)
END



