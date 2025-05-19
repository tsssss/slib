

;-------------------------------------------------------------------------
;  ROUTINE:	fuv_ptg
;-------------------------------------------------------------------------
;  	this routine is based on the POLAR UVI ptg.pro but was modified for the
;	IMAGE FUV instrument
;	Harald Frey, 01/05/2000
;	Thomas Immel 03/2001  load_stars now called
;	TIAN Sheng 06/05/2009	ptg now called


PRO image_ptg, $
;input variables
	emission_height, $

	attitude, $
	orbit, $
	spacecraft_spin, $
	spin_phase, $

	time, $
	col, $
	row, $
	angular_resolution_R, $
	angular_resolution_C, $
	instrument_azimuth, $
	instrument_elevation, $
	instrument_roll, $

;ouput variables
	geocentric_lat, $
	geocentric_lon, $
	look_direction, $
	footprint, $
	solar_zenith_angle, $
	spacecraft_zenith_angle

;check arguments
IF N_Elements(emission_height) EQ 0 THEN Return
IF N_Elements(attitude) EQ 0 THEN Return
IF N_Elements(orbit) EQ 0 THEN Return
IF N_Elements(spacecraft_spin) EQ 0 THEN Return
IF N_Elements(spin_phase) EQ 0 THEN Return
IF N_Elements(time) EQ 0 THEN Return
IF N_Elements(col) EQ 0 THEN Return
IF N_Elements(row) EQ 0 THEN Return
IF N_Elements(angular_resolution_R) EQ 0 THEN Return
IF N_Elements(angular_resolution_C) EQ 0 THEN Return
IF N_Elements(instrument_azimuth) EQ 0 THEN Return
IF N_Elements(instrument_elevation) EQ 0 THEN Return
IF N_Elements(instrument_roll) EQ 0 THEN Return

;initialize variables
fill_value = -1.D31
degree_to_radian = !DPI / 180D

geocentric_lat = DblArr(col, row)
geocentric_lon = DblArr(col, row)
ra = DblArr(col, row)
dec = DblArr(col, row)

geocentric_lat = fill_value
geocentric_lon = fill_value
ra = fill_value
dec = fill_value

xrot = DblArr(col, row)
yrot = DblArr(col, row)

a = (FIndGen(col) - (col - 1) / 2) * angular_resolution_C
b = Replicate(1, row)
xrot = a # b
c = (FIndGen(row) - (row - 1) / 2) * angular_resolution_R
d = Replicate(1, col)
yrot = d # c

;calculate Lpix
tanx = Tan(xrot * degree_to_radian)
tany = Tan(yrot * degree_to_radian)

lpz = - 1D / Sqrt(1D + tanx * tanx + tany * tany)
lpx = - lpz * tanx
lpy = - lpz * tany

;calculate rotation matrix
rot_matrix = Rotation_Matrix(instrument_roll, $
	instrument_elevation, instrument_azimuth, spacecraft_spin, $
	attitude, spin_phase)

;apply rotation
result = rot_matrix ## [[lpx[*]], [lpy[*]], [lpz[*]]]

;determine Lpix
LpixX = Reverse(Reform(result[*,0], col, row), 1)
LpixY = Reverse(Reform(result[*,1], col, row), 1)
LpixZ = Reverse(Reform(result[*,2], col, row), 1)

;find scalar (s) such that s * L0 points to the imaged emission source.
;If the line of sight does not intersect the earth s = 0.0.
;F is the flattening factor of the Earth at the emission height.
get_scalar, orbit[0], orbit[1], orbit[2], $
	LpixX, LpixY, LpixZ, emission_height, $
	col, row, s, f, margin, nmargin

;these are the GCI coords of each observed location on Earth
posX = orbit[0] + s * LpixX
posY = orbit[1] + s * LpixY
posZ = orbit[2] + s * LpixZ

;convert from GCI to GEO coordinates. rot_matrix is the rotation matrix.
ic_gci_to_geo, time, rot_matrix
p_geoX = rot_matrix(0,0) * posX + rot_matrix(1,0) * posY + rot_matrix(2,0) * posZ
p_geoY = rot_matrix(0,1) * posX + rot_matrix(1,1) * posY + rot_matrix(2,1) * posZ
p_geoZ = rot_matrix(0,2) * posX + rot_matrix(1,2) * posY + rot_matrix(2,2) * posZ

;get geocentric_lat and geocentric_lon.
drtoll, p_geoX, p_geoY, p_geoZ, geocentric_lat, geocentric_lon, radius
geocentric_lat = geocentric_lat < 90.

;convert geocentric lat and geocentric lon to geodetic lat and geodetic lon.
;Ref: Spacecraft Attitude Determination and Control,
;J.R. Wertz, ed., 1991, p.821.
geodetic_lat = 90D + 0D * geocentric_lat
ndx = Where(geocentric_lat LT 90., count)
IF(count GT 0) THEN BEGIN
	geodetic_lat[ndx] = Datand(Dtand(geocentric_lat[ndx]) / ((1D - f) * (1D - f)))
ENDIF
geocentric_lat = geodetic_lat

;fill the margin with fill_value
IF (nmargin GT 0) THEN BEGIN
	geocentric_lat[margin] = fill_value
	geocentric_lon[margin] = fill_value
ENDIF

;get look direction
look_direction = [ LpixX[col / 2 - 1, row / 2 - 1], $
				   LpixY[col / 2 - 1, row / 2 - 1], $
				   LpixZ[col / 2 - 1, row / 2 - 1] ]

;calculate solar zenith angle

dummy = LpixX
dummy[*] = 0
IF margin[0] NE -1 THEN dummy[margin] = 1

;get solar angular coordinates, this procedure is in ~immel/idl
solar_angular, time, greenwich_time, ra, dec

;convert to GCI vector of sun [sunX,sunY,sunZ]
sunZ = Sind(dec)
sunX = Cosd(dec) * Cosd(ra)
sunY = Cosd(dec) * Sind(ra)

;calculate magnitude of each array of vectors, and dot product thereof
mag_a = Magnitude(sunX, sunY, sunZ)
mag_b = Magnitude(posX, posX, posX)
dot = sunX * posx + sunY * posy + sunZ * posz
solar_zenith_angle = Acos(dot / (mag_a * mag_b)) / degree_to_radian
IF margin[0] NE -1 THEN solar_zenith_angle[margin] = -1
solar_zenith_angle = Reverse(solar_zenith_angle, 1)

;quickly calculate clock angle, the angle about the subsolar point
ic_gci_to_geo, time, rot_matrix
rot_matrix = FltArr(3, 3)
rot_matrix[*, 0] = [Cosd(ra) * Cosd(dec), Sind(ra) * Sind(dec), Sind(dec)]
rot_matrix[*, 1] = [-Sind(ra), Cosd(ra), 0]
rot_matrix[*, 2] = [Sind(dec) * Cosd(ra), Sind(dec) * Sind(ra), Cosd(dec)]

result = rot_matrix ## [[posX[*]],[posY[*]],[posZ[*]]]

clocky = posX
clockz = posX
clocky[*] = result[*, 1]
clockz[*] = result[*, 2]
clock = Atan(clocky / clockz) / degree_to_radian
clock = Reverse(clock, 1)

;now do spacecraft zenith angles...
to_x = (orbit[0] - posX)
to_y = (orbit[1] - posY)
to_z = (orbit[2] - posZ)

;calculate magnitude of each array of vectors, and dot product thereof
mag_a = Magnitude(to_x, to_y, to_z)
mag_b = Magnitude(posX, posY, posZ)
dot = to_x * posX + to_y * posY + to_z * posZ

;spacecraft_zenith_angle
spacecraft_zenith_angle = Acos(dot / (mag_a * mag_b)) / degree_to_radian
IF margin[0] NE -1 THEN spacecraft_zenith_angle[margin] = -1
spacecraft_zenith_angle = Reverse(spacecraft_zenith_angle,1)

;calculate the geographic coordinate of center of projection,
;this is not the center of the image, as we apply sometimes an offset to limb.
;The output earth_lat and earth_lon are used in auroral_image.

earth_position = - orbit / Magnitude(orbit[0], orbit[1], orbit[2])
get_scalar,orbit[0], orbit[1], orbit[2], $
	earth_position[0], earth_position[1], earth_position[2], $
	emission_height, 1, 1, s, f, margin, nmargin

earth_position[0] = orbit[0] + s * earth_position[0]
earth_position[1] = orbit[1] + s * earth_position[1]
earth_position[2] = orbit[2] + s * earth_position[2]

earth_position_x = rot_matrix(0,0) * earth_position[0] + rot_matrix(1,0) * earth_position[1] + rot_matrix(2,0) * earth_position[2]
earth_position_y = rot_matrix(0,1) * earth_position[0] + rot_matrix(1,1) * earth_position[1] + rot_matrix(2,1) * earth_position[2]
earth_position_z = rot_matrix(0,2) * earth_position[0] + rot_matrix(1,2) * earth_position[1] + rot_matrix(2,2) * earth_position[2]

drtoll, earth_position_x, earth_position_y, earth_position_z, earth_lat, earth_lon, radius
earth_lat = earth_lat < 90.
footprint = [earth_lat, earth_lon]

END