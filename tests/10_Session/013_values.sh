#@desc Checking that we can extract the values of an image within a region
${TRACTOR} mkroi data/session-12dir 49 58 14 PointType:R Width:3 ROIName:tmp/region
${TRACTOR} values data/session-12dir/tractor/diffusion/dti_FA tmp/region
rm -f tmp/region.*
