#@desc Checking streamline pruning
${TRACTOR} pnt-eval DatasetName:data/pnt/pnt_test_data ModelName:data/pnt/pnt_model ResultsName:tmp/pnt_results
${TRACTOR} pnt-prune TractName:genu DatasetName:data/pnt/pnt_test_data ModelName:data/pnt/pnt_model ResultsName:tmp/pnt_results Tracker:fsl SessionList:data/session-12dir NumberOfSamples:50 RandomSeed:1 | grep -v outside | grep -v rejected
rm -f tmp/pnt_results.Rdata
rm -f genu_session1.*
