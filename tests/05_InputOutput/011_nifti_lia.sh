#@desc Checking that NIfTI reader can handle nondiagonal xform matrices
${TRACTOR} imageinfo data/nifti/maskedb0_lia | grep -v source
${TRACTOR} value data/nifti/maskedb0_lia 49 58 14
