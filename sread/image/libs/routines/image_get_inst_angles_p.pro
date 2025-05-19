;--- single additional procedure necessary


pro set_inst_angles_p, inst, year_, day_, ang_, root_dir, new=new


;	author : T. Immel UCB
;
;
;  program to ingest entire ascii database list for a given
;  FUV channel into IDL variables
;
;  input : inst  0:WIC, 1:S13, 2:S12
;
;  2-23-01 : correction! 0:wic 1:s12 2:s13
;  3-22-01 : sick of EOF errors!!! but a far-future date > 2020 in each file
;  8-09-02 : zipped read_inst_angles_p, corrected this version for path

dir_sep=path_sep()

if inst gt 2 or inst lt 0 then print,'Your instrument must be between 0,2'

angle_arr=fltarr(3)

;cd, CURRENT = _file_path
;path_2_dbase=_file_path + '/attitude/'

;path_2_dbase = '$FUVIEW_HOME/attitude/'
path_2_dbase = root_dir+dir_sep+'attitude'+dir_sep
if keyword_set(new) then dbase_files=['wic_angles_new.txt','s12_angles_new.txt','s13_angles_new.txt'] else $
    dbase_files=['wic_angles.txt','s12_angles.txt','s13_angles.txt']
dbase_files=path_2_dbase + dbase_files

to_open=dbase_files(fix(inst))

get_lun,unit
openr,unit,to_open

counter=0
get_out = 0

while not(eof(unit)) and get_out eq 0 do begin

  readf,unit,format='(2i8,3f10.5)',a,b,c,d,e

  if a lt 2020 then begin

    if counter eq 0 then begin
      year_=a
      day_=b
      ang_=[c,d,e]
      counter=counter + 1
    endif else begin
      year_=[year_,a]
      day_=[day_,b]
      ang_=[[ang_],[c,d,e]]
    endelse
  endif else get_out = 1

endwhile

free_lun,unit

return
end

;---- main procedure

pro image_get_inst_angles_p,inst_,year_,day_,angles_,root_dir,no_print=no_print,new=new

;
;  Author : T Immel UCB
;  Date   : 2-11-2001
;  Purpose: Provides a single routine to demand pointing information for
;   	  : getudf_var
;
;  Notes : 5-6-2001  - now never uses defaults, rather always closest
;		     - day to the day/year pair you provide.
;          11/02/2006 keyword new added for new way of pointing calculation

if (inst_ gt 2 or inst_ lt 0) then $
	print,'Your instrument must be between 0,2'

year=fix(year_)
day=fix(day_)
inst=fix(inst_)

set_inst_angles_p,inst,year_arr,day_arr,ang_arr,root_dir,new=new
finder=where(year_arr eq year and day_arr eq day,found)

if found eq 0 then begin

;---- do not switch to defaults, but rather use values from a day
;---- which is closest in time to year_ and day_

  dayfuv=((year_arr - 2000) * 365) + day_arr
  current_day=((year - 2000) * 365) + day
  difference=abs(current_day - dayfuv)
  get_min=where(difference eq min(difference),count_min)
  angles=ang_arr(*,get_min[0])

;  if year eq 2000 and day lt 277 then begin
;
;    case inst_ of
;	0: angles=[43.26  , 0.94 , -0.05]
;	2: angles=[42.62  ,-0.845,   0.0]
;	1: angles=[43.45  ,-0.561,   0.0]
;    endcase;
;
;  endif else begin
;    case inst_ of
;	0: angles=[43.26,0.3,-1.85]
;	2: angles=[42.62,-1.65,-1.85]
;	1: angles=[43.45,-1.47,-1.85]
;    endcase
;  endelse


endif else angles=ang_arr(*,finder)

angles_=angles

if not keyword_set(no_print) then print,'---angles--- ' ,angles


end
