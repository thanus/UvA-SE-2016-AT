module metrics::UnitSize

import lang::java::m3::Core;
import lang::java::\syntax::Java15;
import IO;

import MetricsUtil;

/**
 * Calculate Unit Size: For each method calculate the LOC.
 */
public list[tuple[loc, int, int]] calculateUnitSize(M3 projectModel, bool isDebug) {
	return [<l,calculateLOC(#ClassBodyDec, l, isDebug),0> | l <- methods(projectModel)]; // Adding the third argument here so we can reuse this for the complexity 
}

/** 
 * Divide the methods with their LOC in the categories that we need
 * 
 * These categories were not found in the paper. 
 * This table is based on the values a SIG plugin uses for Sonarcube.
 * Source: http://docs.sonarqube.org/display/SONARQUBE45/SIG+Maintainability+Model+Plugin
 * The table:
 * ----------------
 * Category |  LOC
 * ----------------
 * Very high| > 100 
 * High     | > 50
 * Medium   | > 10
 * Low      | > 0
 */
public map[int, int] calculateUnitSizeCategories(list[tuple[loc, int, int]] methodsLOC) {
	map[int, int] amountPerCategory = (1: 0, 2: 0, 3: 0, 4: 0);
	for (<_,n,_> <- methodsLOC) { // We are not interested in the method location here, only interested in the amount LOC.
		if (n > 0) {
			if (n <= 10) {
				amountPerCategory[1] += n;
			} else if (n <= 50) {
				amountPerCategory[2] += n;
			} else if (n <= 100) {
				amountPerCategory[3] += n;
			} else {
				// It's above 100!
				amountPerCategory[4] += n;
			}
		} 
		// Else: We had a parse error for this file, ignoring this
	}
	return amountPerCategory;
}

/**
 * Calculate Unit Size result: From the result, return the actual score.
 */
public int calculateUnitSizeResult(map[int, int] categories, int totalVolume) {
	return calculateResultFromCategories(categories, totalVolume);
}

/**
 * Calculate the actual result given the categories
 * This table is equal to the one that SIG uses in their paper (and equal to the one used for Cyclomatic Complexity)
 * The table:        
 * --------- Maximum relative LOC ---
 * Rank | Moderate | High | Very high 
 * ----------------------------------
 *  + + |   25%    |  0%  |   0%
 *   +  |   30%    |  5%  |   0%
 *   0  |   40%    | 10%  |   0%
 *   -  |   50%    | 15%  |   5%
 *  - - |    -     |  -   |    -
 */
private int calculateResultFromCategories(map[int, int] categories, int totalVolume) {
	map[int, int] percentsPerCategory = (
		1: categories[1] * 100 / totalVolume, 
		2: categories[2] * 100 / totalVolume, 
		3: categories[3] * 100 / totalVolume, 
		4: categories[4] * 100 / totalVolume 
		);
	
	// Now we know the LOC per category, we can define the result.
	if (percentsPerCategory[2] <= 25 && percentsPerCategory[3] == 0 && percentsPerCategory[4] == 0)
	 	return 5;
	else if (percentsPerCategory[2] <= 30 && percentsPerCategory[3] <= 5 && percentsPerCategory[4] == 0)
	 	return 4;
	else if (percentsPerCategory[2] <= 40 && percentsPerCategory[3] <= 10 && percentsPerCategory[4] == 0)
	 	return 3;
	else if (percentsPerCategory[2] <= 50 && percentsPerCategory[3] <= 15 && percentsPerCategory[4] <= 5)
	 	return 2;
	else
	 	return 1;
}