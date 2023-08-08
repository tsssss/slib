; Simple example of all methods in the remote IDL interface to Madrigal (madidl)
;
; $Id: example_madidl.pro 6810 2019-03-28 19:01:24Z brideout $

PRO example_madidl

     ; these are the instrument codes for the Millstone ISR.  Run the function madGetAllInstruments
     ; to see a list of all instruments available in Madrigal
     instList = [30,31,32]
     
     ; run this test for two different sites (Haystack and SRI), using the test files in each site
     siteList = ['http://millstonehill.haystack.mit.edu', $
                      'http://isr.sri.com/madrigal/' ]
     for i=0,  n_elements(siteList)-1  do begin
         site = siteList[i]
         print, 'Testing Madrigal url ', site

         ; the highest level of Madrigal data is the instrument - here we get a list of all available instruments
         ; See madgetallinstruments.pro for a definition of the instrument structure returned in an array
         result = madGetAllInstruments(site)
         print, 'madGetAllInstruments returned', result
         print, ""
         
         ; the next level of Madrigal is the experiment.  An experiment has only one instrument associated with
         ; it.  In this case, we ask for all experiments in Jan 1998 for any Millstone ISR radar.  sonce this
         ; is a standard test file, its found at both Millstone and SRI
         ; See madgetexperiments.pro for a definition of the experiment structure returned in an array
         result = madGetExperiments(site, instList, 1998,1,19,0,0,0, 1998,1,20,23,59,59,1)
         print, 'madGetExperiments returned ', result
         print, ""
         
         ; next we get an array of files in that experiment.  See madgetexperimentfiles.pro for a definition 
         ; of the experimentfile structure returned in an array
         expId = long64(result[0].strid)
         result = madGetExperimentFiles(site, expid, 1)
         print, 'madGetExperimentFiles returned ', result
         print, ""
         
         ; next we want to get a list of all parameters.  Note Madrigal allows access to both parameters in the file
         ; (called measured parameters) and parameters derivable form the measured ones (called derived parameters).
         ; See madgetexperimentfileparameters.pro for a definition of the parmeter structure returned in an array
         fullFilename = result[0].name
         result = madGetExperimentFileParameters(site, fullFilename)
         print, 'madGetExperimentFileParameters returned ', result
         print, ""
         
         ; the next method effectively downloads the file into an IDL 2-D array.  It only downloads measured parameters
         ; in the file.  See more advanced method madPrint to choose measured or derived parameters and/or to filter data.
         ; See madsimpleprint.pro for details of how the data is returned
         result = madSimplePrint(site, fullFilename,  'Bill Rideout', 'brideout@haystack.mit.edu', 'MIT')
         print, 'size of data returned by madSimplePrint is ', size(result.data)
         print, 'madSimplePrint parameters are ', result.parameters
         print, ""
         
         ; the next method is similar to madsimpleprint, except the user chooses which measured or derived parameters 
         ; to download, and can filter data using the filter string as discussed in 
         ;    http://millstonehill.haystack.mit.edu/docs/name/ad_isprint.html
         ; See madprint.pro for details of how the data is returned
         result = madPrint(site, fullFilename,  'year,month,day,hour,min,sec,gdalt,ti', 'filter=recno,5,6 filter=ti,1000,', $
                                         'Bill Rideout', 'brideout@haystack.mit.edu', 'MIT')
         print, 'size of data returned by madPrint is ', size(result)
         print, ""
         
         ; the next method is similar to madSimplePrint, except that it downloads the data from
         ; a file into a simple column delimited formated file on your local computer
         exampleDir = '/tmp'
         exampleFile = FILEPATH('junk5', /TMP)
         print, exampleFile
         maddownloadfile, site, fullFilename, exampleFile, 'Bill Rideout',  'brideout@haystack.mit.edu',  'MIT', 'hdf5'
         print, 'file has been downloaded to ', exampleFile
         
         ; The next method is used to run the Madrigal derivation engine for any random time and array of geodetic points in space
         ; In other words, things such as Magnetic field and geophysicals indices can be calculated without a Madrigal file.
         ; See madCalculator.pro for details of how the data is returned
         result = madCalculator(site, 1999,2,15,12,30,0,45,55,5,-170,-150,10,200,200,0,'bmag,bn')
         print, 'madCalculator returned ', result
         print, ""
         
         ; The next procedure madglobalPrint allows you to get data from multiple files in a particular Madrigal datbase
         ; at once.  Since it can return very large data sets, it writes to a file rather than an IDL array
         exampleFile = FILEPATH('isprint.txt', /TMP)
         madglobalPrint, site,  'year,month,day,hour,min,sec,gdalt,dte,te', $
                               exampleFile, 'Bill Rideout',  'brideout@haystack.mit.edu',  'MIT', $
                               julday(1,19,1998,0,0,0),  julday(1,21,1998,23,59,59), 30, $
                               '', [3408, 3409, 3410], '*world*'

         ; The next procedure madglobaldownload allows you to download multiple files in a particular Madrigal datbase
         ; at once
         print, 'Using madglobaldownload to get files in ascii format'
         madglobaldownload, 'http://millstonehill.haystack.mit.edu/',  $
                            exampleDir, $
                            'Bill Rideout',  'brideout@haystack.mit.edu', 'MIT', $
                            julday(1,19,1998,0,0,0),  julday(1,21,1998,23,59,59), 30, $
                            [3408, 3409, 3410], 'ascii'
                            
         ; Next madglobaldownload is called to download Hdf5 files
         print, 'Using madglobaldownload to get files in hdf5 format'
         madglobaldownload, 'http://millstonehill.haystack.mit.edu/',  $
                            exampleDir, $
                            'Bill Rideout',  'brideout@haystack.mit.edu', 'MIT', $
                            julday(1,19,1998,0,0,0),  julday(1,21,1998,23,59,59), 30, $
                            [3408, 3409, 3410], 'hdf5'
                              
           
                               
      endfor ; next Madrigal site


      ; an example of getting data from a site from a different Madrigal site - search for Poker Flat data from Millstone site
      site = 'http://millstonehill.haystack.mit.edu'
      instList = [61] ; Poker Flat ISR
      result = madGetExperiments(site, instList, 2008,4,1,0,0,0, 2008,4,30,23,59,59,0)
      print, 'madGetExperiments returned ', result
      ; handle a non-local experiment
      if (result[0].isLocal eq 0) then begin
          site = result[0].madrigalUrl
          ; call madGetExperiments again with local url
          result = madGetExperiments(site, instList, 2008,4,1,0,0,0, 2008,4,30,23,59,59,0)
      endif
      expId = long64(result[0].strid)
      result = madGetExperimentFiles(site, expid, 1)
      print, 'madGetExperimentFiles returned ', result
      print, ""
      
END
