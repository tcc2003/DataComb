import os

##############################################################
'''

  Exporting Pipeline calibrated CASA MS to FITS files

  History.
    v0: 2023.Nov.04
    v1: 2023.Nov.21
        Remove the cvel and concat task 
    v2: 2024.Jan.24
        
'''
##### Define variables #######################################

# The CASA MS to export
ms_path_12m = '../calibrated_ms/12m/'
all_12m_ms = [ 
               os.path.join(ms_path_12m, 'uid___A002_Xaeeace_X785.ms.split.cal.split'),
               os.path.join(ms_path_12m, 'uid___A002_Xaef195_X79a.ms.split.cal.split'),
               os.path.join(ms_path_12m, 'uid___A002_Xaef195_Xe46.ms.split.cal.split'),
               os.path.join(ms_path_12m, 'uid___A002_Xaf4574_X316c.ms.split.cal.split')
             ]

ms_path_7m = '../calibrated_ms/7m/'
all_7m_ms = [               
               os.path.join(ms_path_7m, 'uid___A002_Xad93f4_X2f03.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xaee04e_X2599.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xaee04e_X2987.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xaee04e_X2dc3.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb52d1b_X2341.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb54d65_X2e35.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb54d65_X3230.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb58564_Xcf.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb5a3ad_X1f3.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb5a3ad_X659.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb5a3ad_Xa3d.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb5aa7c_X3b08.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb5aa7c_X431a.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb5ee5a_Xa20.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb66ea7_X9c01.ms.split.cal.split'),
               os.path.join(ms_path_7m, 'uid___A002_Xb7a3f8_X9d67.ms.split.cal.split')
            ]


# The fields and spectral windows to export
all_spwIDs   = range(0,4)

fields_12m = range(0,4)
fields_7m  = range(1,5)

# The head of the output FITS file name
head_7m  = 'ACA7m'
head_12m = 'ALMA12m'


# velocity gridding in the output
vel_start  = '-1230km/s'
vel_width  = '1.57km/s'
vel_nchan  = 1532

# the certain high-emission channels for test
mode = 'velocity'
outframe = 'LSRK'
datacolumn = 'data'
#vel_start = '102.501km/s'  
#vel_width = '1.57km/s'
#vel_nchan = 10


# rest frequencies
restfreq = {}
restfreq[0] = '217.238530GHz'
restfreq[1] = '215.700000GHz'
restfreq[2] = '230.900000GHz'
restfreq[3] = '232.694912GHz'

##############################################################


thesteps = []
step_title = {
              0: 'Output listobs files',
              1: 'Split individual target source fields in to MS files',
              2: 'Export the observations of each visibility on each field to FITS',
              3: 'move the files',
             }

try:
  print ('List of steps to be executed ...', mysteps)
  thesteps = mysteps
except:
  print ('global variable mysteps not set.')
if (thesteps==[]):
  thesteps = range(0,len(step_title))
  print ('Executing all steps: ', thesteps)


##### output listobs file #####################################

mystep = 0
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])


  for vis in all_7m_ms:

    listfile = vis + '.listobs'
    os.system('rm -rf ' + listfile)
    listobs(vis = vis, listfile = listfile)

  for vis in all_12m_ms:

    listfile = vis + '.listobs'
    os.system('rm -rf ' + listfile)
    listobs(vis = vis, listfile = listfile)


##############################################################



##### Split individual target source fields in to MS files ###

mystep = 1
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])

  ### 7m
  print('########################################\n')
  print('Exporting 7m mosaic fields: ', fields_7m)

  for visID in range(len(all_7m_ms)):
    vis = all_7m_ms[visID]

    for fieldID in fields_7m:
      for spwID in all_spwIDs:

          splitms = head_7m + '_vis' + str(visID)  + '_spw' + str(spwID) + '_' + str(fieldID) + '.ms'
          os.system('rm -rf ' + splitms )
          # split -> mstransform
          mstransform(
                        vis = vis, 
                        datacolumn = datacolumn,
                        outputvis = splitms,
                        field = str(fieldID), spw = str(spwID),
                        restfreq = restfreq[spwID],
                        regridms = True,
                        mode = mode, 
                        outframe = outframe,
                        nchan = vel_nchan, 
                        start =vel_start, 
                        width = vel_width
                        )

    ### 12m
    print('########################################\n')
    print('Exporting 12m mosaic fields: ', fields_12m)

    for visID in range(len(all_12m_ms)):
        vis = all_12m_ms[visID]

        for fieldID in fields_12m:
          for spwID in all_spwIDs:

              splitms = head_12m + '_vis' + str(visID)  + '_spw' + str(spwID) + '_' + str(fieldID) + '.ms'
              os.system('rm -rf ' + splitms )
              # split -> mstransform
              mstransform(
                            vis = vis, 
                            datacolumn = datacolumn,
                            outputvis = splitms,
                            field = str(fieldID), spw = str(spwID),
                            restfreq = restfreq[spwID],
                            regridms = True,
                            mode = mode,
                            outframe = outframe,
                            nchan = vel_nchan, 
                            start =vel_start,
                            width = vel_width
    
                          )

##############################################################


##### Export the observations of each visibility on each field to FITS ##########

mystep = 2
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])

  ### 7m
  for visID in range(len(all_7m_ms)):
    vis = all_7m_ms[visID]

    for fieldID in fields_7m:
            for spwID in all_spwIDs:

                filenamehead = head_7m + '_vis' + str(visID) + '_spw' + str(spwID) + '_' + str(fieldID)
                concatvis = filenamehead + '.ms'
                fitsfile  = filenamehead + '.fits'

                os.system('rm -rf ' + fitsfile )
                exportuvfits(
                              vis = concatvis, datacolumn = 'data',
                              fitsfile = fitsfile,
                              multisource = False, combinespw = False
                             )

  ### 12m
  for visID in range(len(all_12m_ms)):
    vis = all_12m_ms[visID]

    for fieldID in fields_12m:
            for spwID in all_spwIDs:

                filenamehead = head_12m + '_vis' + str(visID) + '_spw' + str(spwID) + '_' + str(fieldID)
                concatvis = filenamehead + '.ms'
                fitsfile  = filenamehead + '.fits'

                os.system('rm -rf ' + fitsfile )
                exportuvfits(
                              vis = concatvis, datacolumn = 'data',
                              fitsfile = fitsfile,
                              multisource = False, combinespw = False
                             )


###############################################################

##### Move the files ##########################################

#mystep  = 3
#if(mystep in thesteps):
#  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
#  print ('Step ', mystep, step_title[mystep])

#os.system( 'mv *.fits ../fits/')

################################################################




