#@desc Checking DICOM file sorting and reconstruction
${TRACTOR} -v1 dicomsort data/dicom DeleteOriginals:false && mv data/dicom/8* data/dicom/9* tmp/
${TRACTOR} -v1 -w tmp dicomread 9_fl3D_t1_sag t1 | grep -v t1
${TRACTOR} value tmp/t1 1 145 139
rm -rf tmp/8* tmp/9* tmp/t1.*
