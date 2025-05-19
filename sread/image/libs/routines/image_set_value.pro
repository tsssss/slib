

FUNCTION IMAGE_Set_Value, filename, record, instrument, spinphase

;check arguments
IF N_Elements(filename) EQ 0 THEN Return, -1
IF N_Elements(record) EQ 0 THEN	Return, -1

;check if filename is valid
result = FindFile(filename, Count = count)
IF count EQ 0 THEN BEGIN
	Message, "Cannot find " + filename
	Return, -1
ENDIF
cdfID = CDF_Open(filename)

;variables can be set

;set root_dir
root_dir = "E:\data_processing\IMAGE\IMAGE WIC viewer"

;set instrumentID
instrumentID = "SI"

;set emission_height
emission_height = 130.0

;set min_lat
min_lat = 50.0

;variables can be read from *.cdf files

;read epoch
CDF_VarGet, cdfID, "EPOCH", epoch, Rec_Start = record, /zVariable

;read image
CDF_VarGet, cdfID, instrument + "_PIXELS", image, Rec_Start = record, /zVariable
IF instrument EQ "WIC" THEN $
	image = Reverse(Rotate(image, 1), 2)
IF instrument EQ "SI" THEN BEGIN
	image = Rotate(image, 3)
	image = Shift( image, -5, -15 )
ENDIF
;image = Reverse( Rotate( image, 3 ), 2 )	;for SI
;image = Reverse(image, 1)

;read spin
CDF_VarGet, cdfID, "SPIN", spin, Rec_Start = record, /zVariable

;read radius
CDF_VarGet, cdfID, "RADIUS", radius, Rec_Start = record, /zVariable

;read FoV_scale
CDF_VarGet, cdfID, "FOVSCALE", FoV_scale, Rec_Start = record, /zVariable

;read spin_phase
IF N_Elements( spinphase ) THEN spin_phase = spinphase $
ELSE $
CDF_VarGet, cdfID, "SPINPHASE", spin_phase, Rec_Start = record, /zVariable
;print, spin_phase

;spin_phase = -144.8
;spin_phase = -147.7
;spin_phase = -152.3
;spin_phase = -152.8

;read attitude
CDF_VarGet, cdfID, "SV_X", x, Rec_Start = record, /zVariable
CDF_VarGet, cdfID, "SV_Y", y, Rec_Start = record, /zVariable
CDF_VarGet, cdfID, "SV_Z", z, Rec_Start = record, /zVariable
attitude = [x, y, z]

;read orbit
CDF_VarGet, cdfID, "ORB_X", x, Rec_Start = record, /zVariable
CDF_VarGet, cdfID, "ORB_Y", y, Rec_Start = record, /zVariable
CDF_VarGet, cdfID, "ORB_Z", z, Rec_Start = record, /zVariable
orbit = [x, y, z]

;read spacecraft_spin
CDF_VarGet, cdfID, "SCSV_X", x, Rec_Start = record, /zVariable
CDF_VarGet, cdfID, "SCSV_Y", y, Rec_Start = record, /zVariable
CDF_VarGet, cdfID, "SCSV_Z", z, Rec_Start = record, /zVariable
spacecraft_spin = [x, y, z]

;read horizontal_FoV
;CDF_VarGet, cdfID, "HFOV", horizontal_FoV, Rec_Start = record, /zVariable
horizontal_FoV = 17.1

;read vertical_FoV
;CDF_VarGet, cdfID, "VFOV", vertical_FoV, Rec_Start = record, /zVariable
vertical_FoV = 17.1

;variables can be calculated

;calculate time
CDF_Epoch, epoch, year, month, day, hour, minute, second, milli, /Breakdown_Epoch
second_of_day = hour * 3600L * 1000 + minute * 60L * 1000 + second + milli
day_of_year = DayofYear(year, month, day)
time = LonArr(2)
time[0] = year * 1000.0 + day_of_year
time[1] = second_of_day

;calculate col and row
image_size = Size(image, /Dimensions)
col = image_size[0]
row = image_size[1]

;calculate angular_resolution_R and angular_rasolution_C
angular_resolution_R = vertical_FoV / Double(row)
angular_resolution_C = vertical_FoV / Double(col)
;angular_resolution_C = horizontal_FoV * FoV_scale / Double(col)

;calculate instrument_azimuth, instrument_elevation, instrument_roll
IMAGE_Get_Inst_Angles_P, 0, year, day_of_year, instrument_angles, root_dir, new = 0
instrument_azimuth = instrument_angles[0]
instrument_elevation = instrument_angles[1]
instrument_roll = instrument_angles[2]

;calculate look_direction, geographic_lat, geographic_lon,
;solar_zenith_angle, spacecraft_zenith_angle, footprint
image_ptg, $
;input variables
	emission_height, $
	attitude, orbit, spacecraft_spin, spin_phase, $
	time, col, row, angular_resolution_R, angular_resolution_C, $
	instrument_azimuth, instrument_elevation, instrument_roll, $
;ouput variables
	geographic_lat, geographic_lon, look_direction, footprint, $
	solar_zenith_angle, spacecraft_zenith_angle

;get magnetic latitudes and longitudes
apexfile = root_dir + "\support\mlatlon.1997a.xdr"
geo2apex, geographic_lat, geographic_lon, apexfile, $
	magnetic_lat, magnetic_lon

;get magnetic local time
Get_Local_Time, epoch, geographic_lat, geographic_lon, $
	GLT, MLT

;get MLT_image: magnetically mapped image
sphere = orbit[2] GT 0
;IF sphere EQ 0 THEN min_lat = -50
Get_MLT_Image, image, magnetic_lat, MLT, min_lat, sphere, MLT_image

;construct image_info
image_info = { $
	instrumentID : instrumentID, $						;instrument ID.
	root_dir : root_dir, $
	sphere : sphere, $
	epoch : epoch, $									;epoch of middle of exposure.
	time : time, $										;time of middle of exposure [YYYYDDD, Milliseconds of day].
	col : col, $										;row in raw image.
	row : row, $										;column in raw image.
	image : image, $									;original image either in raw counts, calibrated counts, Rayleigh.
	spin : spin, $										;spin number.
	radius : radius, $									;margin distance in R_e. R_e = 6372.0
;	HV_phosphor : HV_phosphor, $			;HV of phosphor. MEANING UNKNOWN.
;	HV_MCP : HV_MCP, $						;HV of MCP. MEANING UNKNOWN.
	FoV_scale : FoV_scale, $							;scaling factor of FoV. FoV: field of view.
	spin_phase : spin_phase, $							;spin phase angle in middle of exposure.			;
	attitude : attitude, $								;GCI unit vector of spin axis direction.
	orbit : orbit, $									;GCI vector of spacecraft position.
	spacecraft_spin : spacecraft_spin, $				;spin axis unit vector in spacecraft frame.
	horizontal_FoV : horizontal_FoV, $					;horizontal field of view in degrees.
	vertical_FoV : vertical_FoV, $						;vertical field of vew in degrees.
	angular_resolution_R : angular_resolution_R, $		;angular resolution vertically.
	angular_resolution_C : angular_resolution_C, $		;angular resolution horizontally.
	instrument_azimuth : instrument_azimuth, $			;instrument azimuth angle from spacecraft x-axis.
	instrument_elevation : instrument_elevation, $		;instrument elevation angle from spacecraft spin plane.
	instrument_roll : instrument_roll, $				;instrument roll angle from spacecraft spin axis.
;	height : height, $									;margin distance in R_e, equall to radius.
;	SRC : SRC, $							;instrument identifier. USAGE UNKNOWN.
	footprint : footprint, $				;geographic latitude of spacecraft footprint. CALC UNKNOWN.
	look_direction : look_direction, $					;GCI unit vector of look direction.
;	ra : ra, $											;RA of look direction. RA: right ascension.
;	dec : dec, $										:dec of look direction. dec: declination.
	emission_height : emission_height, $				;assumed emission height in km.
	min_lat : min_lat, $								;minimun latitude of the magnetically mapped image
	magnetic_lat : magnetic_lat, $						;magnetic latitude of every pixel in image.
	magnetic_lon : magnetic_lon, $						;magnetic longitude of every pixel in image.
	MLT : MLT, $										;MLT of every pixel in image. MLT: magnetic local time.
	MLT_image : MLT_image, $							;magnetically mapped image.
	geographic_lat : geographic_lat, $					;geographic latitude of every pixel in image.
	geographic_lon : geographic_lon, $					;geographic longitude of every pixel in image.
	solar_zenith_angle : solar_zenith_angle, $			;solar zenith angle of every pixel in image.
	spacecraft_zenith_angle : spacecraft_zenith_angle $	;spacecraft zenith angle of every pixel in image.
;	airglow_scale : FltArr(3), $			;parameters for airglow correction. ALL UNKNOWN.
;	calibration_flag : Fix(fill_value), $	;ALL UNKNOWN.
}

CDF_Close, cdfID
Return, image_info

END