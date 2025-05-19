;%W% %G%
;
PRO Get_Local_Time, $
	epoch, geodetic_lat,geodetic_lon, $
	GLT,MLT, lat_mag, lon_mag

    ;Calculate local times in geodetic and magnetic coords.

    ;INPUT:
    ;UT      Universal Time in hours
    ;year    year
    ;month   month of year (1-12)
    ;day     day of month (1-31)
    ;geodetic_lat     geodetic latitude
    ;geodetic_lon     geodetic longitude
    ;apexfile - name of data file containing apex coordinates

    ;OUTPUT:
    ;GLT     geodetic local time, angle between current meridian
    ;         and meridian containing subsolar point with 12 hour
    ;         phase shift so GLT=0 corresponds with midnight
    ;MLT     magnetic local time, same as GLT but using magnetic
    ;         meridians

	CDF_Epoch, epoch, year, month, day, hour, minute, second, milli, /Breakdown_Epoch
	UT = hour + minute / 60D + second / 3600D + milli / 3600D / 1000D

    ;get Julian daynumber, needed for the call to ephem
    greg_to_jdaynum,year,month,day,jd       ; same as jd = julday(month,day,year)
    jd -= 0.5

    ;get equation of time and Greenwich hour angle
    ephem,jd,UT,gha,dec,eqtime

    ;calculate geodetic local time
    GLT = (geodetic_lon + gha)/15. - 12.

    ;check range of GLT 0-24
    ndx=WHERE(GLT LT 0,count)
    IF(count GT 0) THEN GLT(ndx)=GLT(ndx)+24.
    ndx=WHERE(GLT GT 24,count)
    IF(count GT 0) THEN GLT(ndx)=GLT(ndx)-24.

    ;get solar longitude degrees.  the equation of time is
    ;given in degrees and must be converted to hours.
    slon = (12. - UT - (eqtime/15.))*15.

    ;convert geodetic data into magnetic data
    geo2apex,geodetic_lat,geodetic_lon, lat_mag,lon_mag
    geo2apex,dec,slon, slat_mag,slon_mag

    ;calculate magnetic local time
    MLT = (lon_mag - slon_mag)/15. + 12.

    ;check range of MLT 0-24
    ndx=WHERE(MLT LT 0,count)
    IF(count GT 0) THEN MLT[ndx]=MLT[ndx]+24.
    ndx=WHERE(MLT GT 24,count)
    IF(count GT 0) THEN MLT[ndx]=MLT[ndx]-24.

END
