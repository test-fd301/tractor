#include "vector.h"
#include "waypoint.h"

#include <R.h>
#include <Rdefines.h>

SEXP find_waypoint_hits (SEXP points, SEXP n_points, SEXP start_indices, SEXP lengths, SEXP n_starts, SEXP mask_points, SEXP n_masks, SEXP n_mask_points, SEXP exclusion)
{
    int i, j, n_matches, current_match;
    int ns = *INTEGER(n_starts);
    int *int_ptr;
    int *match = (int *) R_alloc(ns, sizeof(int));

    SEXP current_mask_points, matching_indices;
    
    // Allocate memory for a version of start_indices using the C indexing convention
    int *zero_based_start_indices = (int *) R_alloc(ns, sizeof(int));
    
    // All lines are initially marked as matching
    for (j=0; j<ns; j++)
    {
        match[j] = 1;
        zero_based_start_indices[j] = INTEGER(start_indices)[j] - 1;
    }
    
    for (i=0; i<(*INTEGER(n_masks)); i++)
    {
        // Find streamlines that pass through the current mask
        current_mask_points = VECTOR_ELT(mask_points, i);
        match_points(INTEGER(points), *INTEGER(n_points), zero_based_start_indices, INTEGER(lengths), *INTEGER(n_starts), INTEGER(current_mask_points), INTEGER(n_mask_points)[i], INTEGER(exclusion)[i], 3, match);
    }
    
    // Count matching streamlines
    n_matches = 0;
    for (j=0; j<ns; j++)
        n_matches += match[j];
    
    // Allocate a vector for matching indices
    PROTECT(matching_indices = NEW_INTEGER((R_len_t) n_matches));
    
    // Copy matching indices into place
    int_ptr = INTEGER(matching_indices);
    current_match = 0;
    for (j=0; j<ns; j++)
    {
        if (match[j])
        {
            int_ptr[current_match] = j + 1;
            current_match++;
        }
    }
    
    UNPROTECT(1);
    
    return matching_indices;
}

void match_points (const int *points, const int n_points, const int *start_indices, const int *lengths, const int n_starts, const int *target_points, const int n_target_points, const int exclusion, const int n_dims, int *match)
{
    // Iterate over streamlines, updating match status
    for (int i=0; i<n_starts; i++)
    {
        // Don't bother running points_intersect() for streamlines which have already failed to match
        if (match[i])
            match[i] = (!exclusion == points_intersect(points, n_points, start_indices[i], lengths[i], target_points, n_target_points, n_dims));
    }
}

int points_intersect (const int *points, const int n_points, const int start_index, const int length, const int *target_points, const int n_target_points, const int n_dims)
{
    int i, j, k, match;
    
    // Look for matching points in each group
    for (i=start_index; i<(start_index+length); i++)
    {
        for (j=0; j<n_target_points; j++)
        {
            match = 1;
            for (k=0; k<n_dims; k++)
            {
                // If any element of the vector does not match, the whole does not match
                if (points[i + k*n_points] != target_points[j + k*n_target_points])
                {
                    match = 0;
                    break;
                }
            }
            
            // If there is any match, the point sets intersect
            if (match)
                return 1;
        }
    }
    
    return 0;
}
