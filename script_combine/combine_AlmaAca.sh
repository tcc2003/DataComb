#!/bin/bash

##### README ####################################################
#
# History:
# v0 (2023.Dec.05): revised from the script "combine_single.csh" 
#                   obtained from
#                   https://github.com/baobabyoo/almica
# v1 (2023.Jan.11): complete the step 0,1
#		    revise the step 2 in progress
# 
#################################################################

#### Flow control ###############################################
#
#
# 1. Correct headers if necessary
#
# 2. Imaging ACA alone
#
# 4. Implement the 12m dish PB to ACA
#
# 5. Generate ACA visibility model
#
# 6. Jointly image ACA visibility model with 12m
#
# 7. Output FITS
#
#################################################################

# flow control #######################################
#
#   modify headers (important and hard when you're combining
#   data taken from different observatories).
if_setheaders='nyes'

#
if_imagingACA='nyes'

#
if_ip12aca='nyes'

if_acavis='nyes'

if_jointlyimag='yes'

if_fitsoutput='nyes'

##### Parameters ################################################

# name of your spectral line. I usually use this as part of my output filename.
# In this case, it is the CO J=2-1 line.
# You can set this to anything you like. It does not matter.
declare -A linename
linename[0]='DCN_3to2'
linename[1]='DC0+_3to2'
linename[2]='N2D+_3to2'
linename[3]='13CH3CN_13to12'

# The rest frequency of your line. The sets the velocity grid.
declare -A restfreq
restfreq[0]='217.238530' # in GHz unit
restfreq[1]='215.700000'
restfreq[2]='230.900000'
restfreq[3]='232.694912'

# The directory where your visibility data are located.
visdir_12m="../fits/12m/"  # ***************
visdir_7m='../fits/7m/'    # ***************

# spectral window
spw=$(seq 0 1 0)

# Mosaic fields of files
fields_12m=$(seq 0 1 3)
fields_7m=$(seq 1 1 4)

# The primary beam FWHM
pbfwhm_12m='26.2'
pbfwhm_7m='45.57'

# Filename of the ACA visibility
name_12m='ALMA12m'
name_7m='ACA7m'

# Filename of ACA visibilities
all7mvis='ACA7m_spw0_1.miriad','ACA7m_spw0_2.miriad','ACA7m_spw0_3.miriad','ACA7m_spw0_4.miriad'

# Filename of all of the ALMA 12-m visibility
all12mvis='ALMA12m_spw0_0.miriad','ALMA12m_spw0_1.miriad','ALMA12m_spw0_2.miriad','ALMA12m_spw0_3.miriad' # ***

# Filename of one of the ALMA 12-m visibility. It can be any one of those.
# This is for the script to extract header information.
#In implementing 12m array (step 3)
Mainvis='ALMA12m_spw0_1.miriad' # ***

# A relative Tsys for adjusting weighting.
tsys_single='60'


##### parameters for ACA cleaning ##################

aca_imsize='128,128'  # size of the initial ACA image in units of pixels
aca_cell='0.8'        # cell size for the initial ACA image in units of arcsecond.
aca_niters='2000'        # number of iterations for the initial ACA imaging (per channel)
aca_cutoff='0.06'       # cutoff level fo the initial ACA imaging      
aca_options='positive'  # options for the initial ACA imaging (in the clean task)
 
 # parameters for select certain high-emission spectral line in "invert" task
aca_vstart='35.0000'
aca_vchan='58'
aca_vwidth='1.57'
aca_vstep='1.57'
aca_linepara="velocity,$aca_vchan,$aca_vstart,$aca_vwidth,$aca_vstep"

# The region in the ACA image to clean.
# This is sometimes useful (e.g., when you actually neeed single-dish but doesn't have it)
aca_region='boxes(39,49,91,101)' # ***


##### paramaters for final imaging ###################

robust=2.0                # Briggs robust parameter for the final imaging.
imsize='6000,6000' # ***  # size of the final image in units of pixels
cell='0.01' # ***         # cell size for the final image in units of arcsecond.
niters=1000000 # ***      # number of iterations for the final imaging (per channel)
cutoff=0.005 # ***        # cutoff level fo the final imaging

# The region in the final image to clean.
# This is sometimes useful (e.g., when you actually neeed single-dish but doesn't have it)
#region='boxes(1200,1200,4800,4800)' # ***

# tapering FWHM in units of arcsecond.
# You can comment out the tapering part in the final cleaning command if it is not needed.
taper='0.1,0.1' # ***

#################################################################


##### Step 1. Set headers #######################################

if [ $if_setheaders == 'yes' ]
then
  
  for spw_id in $spw
    do

    # 12m data (set the primary beam)
    # this step is necessary for certain distributions of Miriad
    # (i.e., in case it does not recognize ALMA, ACA, or TP)
    for field_id in $fields_12m
    do
       pb="gaus($pbfwhm_12m)"
       puthd in=$name_12m'_spw'$spw_id'_'$field_id'.miriad'/telescop \
             value='single' \
             type=a

       puthd in=$name_12m'_spw'$spw_id'_'$field_id'.miriad'/pbtype \
             value=$pb \
             type=a

       puthd in=$name_12m'_spw'$spw_id'_'$field_id'.miriad'/restfreq \
             value=${restfreq[$spw_id]} \
             type=d
    done
  

    # 7m data (set the primary beam)
    # this step is necessary for certain distributions of Miriad
    # (i.e., in case it does not recognize ALMA, ACA, or TP)
    for field_id in $fields_7m
    do
       pb="gaus($pbfwhm_7m)"
       puthd in=$name_7m'_spw'$spw_id'_'$field_id'.miriad'/telescop \
             value='single' \
             type=a

       puthd in=$name_7m'_spw'$spw_id'_'$field_id'.miriad'/pbtype \
             value=$pb \
             type=a

       puthd in=$name_7m'_spw'$spw_id'_'$field_id'.miriad'/restfreq \
             value=${restfreq[$spw_id]} \
             type=d

    done

  done
fi

#################################################################


##### Step 2. Imaging ACA alone #################################
if [ $if_imagingACA == 'yes' ]
then

  for spw_id in $spw
  do
<<<<<<< HEAD
    
        if [ -e ${linename[$spw_id]}.acamap ]; then
           rm -rf ${linename[$spw_id]}.acamap
        fi

        if [ -e ${linename[$spw_id]}.acabeam ]; then
           rm -rf ${linename[$spw_id]}.acabeam
        fi

        if [ -e ${linename[$spw_id]}.acamodel ]; then
           rm -rf ${linename[$spw_id]}.acamodel
        fi

        if [ -e ${linename[$spw_id]}.acaresidual ]; then
           rm -rf ${linename[$spw_id]}.acaresidual
        fi

        if [ -e ${linename[$spw_id]}.acaclean ]; then
           rm -rf ${linename[$spw_id]}.acaclean
=======

    for field_id in $fields_7m
    do
#	if [ $field_id -eq 3 ]; then
#	  continue
#	fi
	
        if [ -e ${linename[$spw_id]}'_'$field_id.acamap.temp ]; then
           rm -rf ${linename[$spw_id]}'_'$field_id.acamap.temp
        fi

        if [ -e ${linename[$spw_id]}'_'$field_id.acabeam.temp ]; then
           rm -rf ${linename[$spw_id]}'_'$field_id.acabeam.temp
        fi

        if [ -e ${linename[$spw_id]}'_'$field_id.acamodel.temp ]; then
           rm -rf ${linename[$spw_id]}'_'$field_id.acamodel.temp
        fi

        if [ -e ${linename[$spw_id]}'_'$field_id.acaresidual.temp ]; then
           rm -rf ${linename[$spw_id]}'_'$field_id.acaresidual.temp
        fi

        if [ -e ${linename[$spw_id]}'_'$field_id.acaclean.temp ]; then
           rm -rf ${linename[$spw_id]}'_'$field_id.acaclean.temp
>>>>>>> 280f0fa40b140c68d50fb6e5acac1dd040d02a4a
        fi


        # produce dirty image (i.e., fourier transform)
<<<<<<< HEAD
	invert vis=$all7mvis\
	       map=${linename[$spw_id]}.acamap\
	       beam=${linename[$spw_id]}.acabeam \
               options=double,mosaic \
	       imsize='256,256' \
               cell='0.8'   

      # perform cleaning (i.e., produce the clean model image)
        clean map=${linename[$spw_id]}.acamap \
              beam=${linename[$spw_id]}.acabeam \
              out=${linename[$spw_id]}.acamodel \
              niters='20000' \
              cutoff='0.001' \
              options='positive' \
# 	      region='boxes(85,135,146,194)'

     # produce the clean image (for inspection)
        restor map=${linename[$spw_id]}.acamap \
               beam=${linename[$spw_id]}.acabeam \
               mode=clean \
               model=${linename[$spw_id]}.acamodel \
               out=${linename[$spw_id]}.acaclean

      # produce the residual image (for insepction)
        restor map=${linename[$spw_id]}.acamap \
    	       beam=${linename[$spw_id]}.acabeam \
               mode=residual \
               model=${linename[$spw_id]}.acamodel \
               out=${linename[$spw_id]}.acaresidual


     ### produce 12m to check
        invert vis=$all12mvis\
               map=${linename[$spw_id]}.12mmap\
               beam=${linename[$spw_id]}.12mbeam \
               options=double,mosaic \
               imsize='256,256' \
               cell='0.1'

	clean map=${linename[$spw_id]}.12mmap \
              beam=${linename[$spw_id]}.12mbeam \
              out=${linename[$spw_id]}.12mmodel \
              niters='20000' \
              cutoff='0.01' \
              options='positive' \
#             region='boxes(85,135,146,194)'

     # produce the clean image (for inspection)
        restor map=${linename[$spw_id]}.12mmap \
               beam=${linename[$spw_id]}.12mbeam \
               mode=clean \
               model=${linename[$spw_id]}.12mmodel \
               out=${linename[$spw_id]}.12mclean

      # produce the residual image (for insepction)
        restor map=${linename[$spw_id]}.12mmap \
               beam=${linename[$spw_id]}.12mbeam \
               mode=residual \
               model=${linename[$spw_id]}.12mmodel \
               out=${linename[$spw_id]}.12mresidual
=======
	invert vis=$name_7m'_spw'$spw_id'_'$field_id'.miriad' \
	       map=${linename[$spw_id]}'_'$field_id.acamap.temp   \
               beam=${linename[$spw_id]}'_'$field_id.acabeam.temp \
               options=double    \
               imsize='256,256' \
               cell='0.8arcsec'   

      # perform cleaning (i.e., produce the clean model image)
        clean map=${linename[$spw_id]}'_'$field_id.acamap.temp \
              beam=${linename[$spw_id]}'_'$field_id.acabeam.temp \
              out=${linename[$spw_id]}'_'$field_id.acamodel.temp \
              niters='50000' \
              cutoff='0.1' \
              options='positive'
#	    region='boxes(40,94,105,153)'

     # produce the clean image (for inspection)
        restor map=${linename[$spw_id]}'_'$field_id.acamap.temp \
               beam=${linename[$spw_id]}'_'$field_id.acabeam.temp \
               mode=clean \
               model=${linename[$spw_id]}'_'$field_id.acamodel.temp \
               out=${linename[$spw_id]}'_'$field_id.acaclean.temp

      # produce the residual image (for insepction)
        restor map=${linename[$spw_id]}'_'$field_id.acamap.temp \
    	       beam=${linename[$spw_id]}'_'$field_id.acabeam.temp \
               mode=residual \
               model=${linename[$spw_id]}'_'$field_id.acamodel.temp \
               out=${linename[$spw_id]}'_'$field_id.acaresidual.temp
    done
>>>>>>> 280f0fa40b140c68d50fb6e5acac1dd040d02a4a

  done

fi
#################################################################


##### Step 3. Implement the 12m dish PB to ACA ##################
if [ $if_ip12aca == 'yes' ]
then
  
  for spw_id in $spw
  do
<<<<<<< HEAD
		
    for field_id in $fields_12m
    do 

      if [ -e ${linename[$spw_id]}'_re-'$field_id.acamodel.demos ]; then
        rm -rf ${linename[$spw_id]}'_re-'$field_id.acamodel.demos
      fi

      # implement (i.e., multiply) the 12m array primary beam
      demos map=${linename[$spw_id]}.acamodel \
            vis=$name_12m'_spw'$spw_id'_'$field_id'.miriad' \
            out=${linename[$spw_id]}'_re-'$field_id.acamodel.demos
	
      if [ -e ${linename[$spw_id]}'_re-'$field_id.acamodel.demos ]; then
      	rm -rf ${linename[$spw_id]}'_re-'$field_id.acamodel.demos
      fi

      mv ${linename[$spw_id]}'_re-'$field_id.acamodel.demos1 ${linename[$spw_id]}'_re-'$field_id.acamodel.demos


      # primary beam correction
      if [ -e ${linename[$spw_id]}'_re-'$field_id.acamodel.demos.pbcor ]; then
        rm -rf ${linename[$spw_id]}'_re-'$field_id.acamodel.demos.pbcor
      fi
	
      linmos in=${linename[$spw_id]}'_re-'$field_id.acamodel.demos \
	     out=${linename[$spw_id]}'_re-'$field_id.acamodel.demos.pbcor


=======
    for field_id in $fields_7m
    do 
		
      if [ -e ${linename[$spw_id]}'_'$field_id.acamodel.regrid.temp ]; then
          rm -rf ${linename[$spw_id]}'_'$field_id.acamodel.regrid.temp
      fi

      # regridding the model image to the original imagesize
      regrid in=${linename[$spw_id]}'_'$field_id.acamodel.temp \
             tin='DCN_3to2.acamap.temp' \
	     out=${linename[$spw_id]}'_'$field_id.acamodel.regrid.temp

#	     tin=${linename[$spw_id]}'_'$field_id.acamap.temp \

    done

    acavis="${linename[$spw_id]}_1.acamodel.regrid.temp","${linename[$spw_id]}_2.acamodel.regrid.temp","${linename[$spw_id]}_3.acamodel.regrid.temp","${linename[$spw_id]}_4.acamodel.regrid.temp"

    if [ -e ${linename[$spw_id]}.acamodel.regrid.pbcor.temp ]; then
       rm -rf ${linename[$spw_id]}.acamodel.regrid.pbcor.temp
    fi


    # correct the aca primary beam to the model
    linmos in=$acavis \
           out=${linename[$spw_id]}.acamodel.regrid.pbcor.temp


    if [ -e ${linename[$spw_id]}.acamodel.regrid.pbcor.demos.temp1 ]; then
    	rm -rf ${linename[$spw_id]}.acamodel.regrid.pbcor.demos.temp1
    fi
	
    # implement (i.e., multiply) the 12m array primary beam
    for field_id in $fields_12m
    do 
	
      demos map=${linename[$spw_id]}.acamodel.regrid.pbcor.temp \
            vis=$name_12m'_spw'$spw_id'_'$field_id'.miriad' \
            out=${linename[$spw_id]}'_'$field_id.acamodel.regrid.pbcor.demos.temp
	
      if [ -e ${linename[$spw_id]}'_'$field_id.acamodel.regrid.pbcor.demos.temp ]; then
      	rm -rf ${linename[$spw_id]}'_'$field_id.acamodel.regrid.pbcor.demos.temp
      fi

      mv ${linename[$spw_id]}'_'$field_id.acamodel.regrid.pbcor.demos.temp1 ${linename[$spw_id]}'_'$field_id.acamodel.regrid.pbcor.demos.temp
>>>>>>> 280f0fa40b140c68d50fb6e5acac1dd040d02a4a

    done

  done
fi

#################################################################

##### Step 4. Generate ACA visibility model #####################
if [ $if_acavis == 'yes' ]
then
  for spw_id in $spw
  do


      if [ -e 'uv_random.miriad' ]; then
         rm -rf 'uv_random.miriad'
      fi

      # make random uv distribution for the following replacement
      uvrandom npts='1500' \
	       freq=${restfreq[$spw_id]} \
      	       inttime=10 \
	       uvmax=3.5 \
	       nchan='30' \
	       gauss=true \
	       out='uv_random.miriad'

     
      for field_id in $fields_12m
      do

	if [ -e $name_7m'_spw'$spw_id'_'$field_id'.uvmodel' ]; then
	  rm -rf $name_7m'_spw'$spw_id'_'$field_id'.uvmodel'
     	fi

	
        # replacing the visibility amplitude and phase based on the input image model
        uvmodel vis='uv_random.miriad' \
<<<<<<< HEAD
                model=${linename[$spw_id]}'_re-'$field_id.acamodel.demos.pbcor \
=======
                model=${linename[$spw_id]}'_'$field_id.acamodel.regrid.pbcor.demos.temp \
>>>>>>> 280f0fa40b140c68d50fb6e5acac1dd040d02a4a
                options='replace,imhead' \
                out=$name_7m'_spw'$spw_id'_'$field_id'.uvmodel'

        # change the system temperature of the re-generated, primary beam tapered, ACA visibility.
        # this is to adjust the relative weight to the ALMA 12m visibility.
        uvputhd vis=$name_7m'_spw'$spw_id'_'$field_id'.uvmodel' \
                hdvar=systemp \
                type=r \
<<<<<<< HEAD
                varval='5' \
=======
                varval='999' \
>>>>>>> 280f0fa40b140c68d50fb6e5acac1dd040d02a4a
                length=1 \
                out=$name_7m'_spw'$spw_id'_'$field_id'.uvmodel.temp'

        puthd in=$name_7m'_spw'$spw_id'_'$field_id'.uvmodel.temp'/pbtype \
              value="gaus($pbfwhm_12m)" \
              type=a   

        if [ -e $name_7m'_spw'$spw_id'_'$field_id'.uvmodel' ]; then
           rm -rf $name_7m'_spw'$spw_id'_'$field_id'.uvmodel'
        fi

        mv $name_7m'_spw'$spw_id'_'$field_id'.uvmodel.temp' $name_7m'_spw'$spw_id'_'$field_id'.uvmodel'
      done

  done
fi
#################################################################

##### Step 5. Jointly image ACA visibility model with 12m #######
if [ $if_jointlyimag == 'yes' ]
then

  for spw_id in $spw
  do


      ## INVERTING :
      if [ -e ${linename[$spw_id]}.map ]; then
         rm -rf ${linename[$spw_id]}.map
      fi

      if [ -e ${linename[$spw_id]}.beam ]; then
         rm -rf ${linename[$spw_id]}.beam
      fi

      # produce the dirty image
      invert vis=$all12mvis,'ACA7m_spw0_0.uvmodel','ACA7m_spw0_1.uvmodel','ACA7m_spw0_2.uvmodel','ACA7m_spw0_3.uvmodel' \
             map=${linename[$spw_id]}.map \
             beam=${linename[$spw_id]}.beam \
             options='systemp,double,mosaic' \
             robust='2.0' \
             imsize='600,600' \
  	     cell='0.2' 
#             fwhm='0.1,0.1'          \


      ## CLEANING: 
      if [ -e ${linename[$spw_id]}.model ]; then
         rm -rf ${linename[$spw_id]}.model
      fi

      # produce the clean model
      clean map=${linename[$spw_id]}.map \
            beam=${linename[$spw_id]}.beam \
            out=${linename[$spw_id]}.model \
<<<<<<< HEAD
            niters='300000' \
            cutoff='0.009'
#	    region='boxes(227,241,367,349)'
=======
            niters='1000' \
#	    region='boxes(227,241,367,349)'  \
            cutoff='0.03'
>>>>>>> 280f0fa40b140c68d50fb6e5acac1dd040d02a4a


      # RESTORING:
  
      if [ -e ${linename[$spw_id]}.clean ]; then
         rm -rf ${linename[$spw_id]}.clean
      fi

      if [ -e ${linename[$spw_id]}.residual ]; then
         rm -rf ${linename[$spw_id]}.residual
      fi

      # produce the final clean image
      restor map=${linename[$spw_id]}.map \
             beam=${linename[$spw_id]}.beam \
             mode=clean \
             model=${linename[$spw_id]}.model \
             out=${linename[$spw_id]}.clean

      # produce the final residual image
      restor map=${linename[$spw_id]}.map \
             beam=${linename[$spw_id]}.beam \
             mode=residual \
             model=${linename[$spw_id]}.model \
             out=${linename[$spw_id]}.residual

<<<<<<< HEAD
=======


      # FINAL PBCOR:
  
      if [ -e ${linename[$spw_id]}.clean.pbcor ]; then
         rm -rf ${linename[$spw_id]}.clean.pbcor
      fi

      # the Miriad task to perform primary beam correction
      linmos in=${linename[$spw_id]}.clean out=${linename[$spw_id]}.clean.pbcor
 
>>>>>>> 280f0fa40b140c68d50fb6e5acac1dd040d02a4a
  done
fi
#################################################################



##### Step 6. FITS output #######################################
if [ $if_fitsoutput == 'yes' ]
then
  for spw_id in $spw
  do 

    fits in=${linename[$spw_id]}.clean \
         op=xyout \
         out=${linename[$spw_id]}.clean.fits

    fits in=${linename[$spw_id]}.residual \
         op=xyout \
         out=${linename[$spw_id]}.residual.fits

    fits in=${linename[$spw_id]}.map \
         op=xyout \
         out=${linename[$spw_id]}.dirty.fits

    fits in=${linename[$spw_id]}.beam \
         op=xyout \
         out=${linename[$spw_id]}.beam.fits

    if [ -e fits_images ]; then
       mv ${linename[$spw_id]}.clean.fits ./fits_images/
       mv ${linename[$spw_id]}.residual.fits ./fits_images/
       mv ${linename[$spw_id]}.dirty.fits ./fits_images/
       mv ${linename[$spw_id]}.beam.fits ./fits_images/
    else
       mkdir fits_images
       mv ${linename[$spw_id]}.clean.fits ./fits_images/
       mv ${linename[$spw_id]}.residual.fits ./fits_images/
       mv ${linename[$spw_id]}.dirty.fits ./fits_images/
       mv ${linename[$spw_id]}.beam.fits ./fits_images/
    fi

    if [ -e ${linename[$spw_id]} ]; then
       rm -rf ${linename[$spw_id]}
       mkdir ${linename[$spw_id]}
    else
       mkdir ${linename[$spw_id]}
    fi

    mv ./${linename[$spw_id]}.* ./${linename[$spw_id]}

  done
fi
#################################################################


##### Cleaning up ###############################################
# rm -rf $linename*.uv.miriad*
#################################################################



##### Ending ####################################################

#################################################################
