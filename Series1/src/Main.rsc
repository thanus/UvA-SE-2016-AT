module Main

import Set;
import List;
import DateTime;
import IO;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

// Our metrics modules
import MetricsUtil;
import Measure;
import metrics::Volume;
import metrics::UnitSize;
import metrics::UnitComplexity;
import metrics::Duplication;

/**
 * Alex Kok
 * alex.kok@student.uva.nl
 * 
 * Thanusijan Tharumarajah
 * thanus.tharumarajah@student.uva.nl
 */

// Made public so we can easily put those into the main() method in the console.
public list[loc] projectLocations = [
	|project://MetricsTests2/src|, // Our project with some defined tests
	|project://smallsql0.21_src/src|, // The SmallSQL project
	|project://hsqldb-2.3.1/hsqldb| // The hsqldb project
];

// Values to keep track of the analysis of the current project
private datetime analysisStartTime, analysisEndTime;
private loc analysysProjectLocation;
private bool analysysIsDebug;
private M3 projectM3Model;
private str bigFileOfProject;
private int metricTotalVolume;
private int metricVolumeResult;
private list[tuple[loc, int, int]] metricTotalUnitSize;
private int metricUnitSizeResult;
private list[tuple[loc, int, int]] metricTotalUnitComplexity;
private int metricUnitComplexityResult;
public list[tuple[int, list[int], str]] metricDuplications;
private int metricDuplicationsTotalLines;
private int metricDuplicationResult;

private int metricAnalysability;
private int metricChangeability;
private int metricTestability;
private int metricMaintainability;

/**
 * The main method.
 * Starting the analyzer and computing each metric on the given project.
 */
public void main(loc projectLocation = projectLocations[1]) {
	analysysIsDebug = true;
	
	initAnalyzer(projectLocation);
	println();
	
	doPhase1_Prepare();
	println();
	doPhase2_Volume();
	println();
	doPhase3_UnitSize();
	println();
	doPhase4_UnitComplexity();
	println();
	doPhase5_Duplication();
	println();
	
	showMetricResults();
	println();
	tearDownAnalyzer();
}

private void initAnalyzer(loc projectLocation) {
	analysysProjectLocation = projectLocation;
	analysisStartTime = now();
	println("*************** Metrics Analyzer ***************");
	println("* Alex Kok                                     *");
	println("* Thanusijan Tharumarajah                      *");
	println("*                                              *");
	println("* TODOS:                                       *");
	println("* - Document duplication                       *");
	println("************************************************");
	println("- Start time:\t\t <printDateTime(analysisStartTime)>");
	println("- Project location:\t <analysysProjectLocation>");
	println("- Debug modus:\t\t <analysysIsDebug>");
	println("- Metrics to calculate:\t Volume, Unit Size, Unity Complexity and Duplication");
	println("- Tables used to compute the metrics can be found in the source. Those tables will also be printed here in the meantime when the result is being computed for a specific metric.");
}

private void doPhase1_Prepare() {
	println("** Phase 1: Preparing project data");
	if (analysysIsDebug) print("- Progress: ");
	projectM3Model = createM3FromEclipseProject(analysysProjectLocation);
	bigFileOfProject = createBigFile(files(projectM3Model), analysysIsDebug);
	if (analysysIsDebug) println();
	println("- Files: <size(files(projectM3Model))>");
	println("- Methods: <size(methods(projectM3Model))>");
}

private void doPhase2_Volume() {
	println("** Phase 2: Calculating metric: Volume");
	println("- Will be computed based on the SIG Volume metric");
	println("  - A line consisting of only \"{\" or \"}\" will be considered as a LOC");
	println("  - Package statements will be considered as LOC");
	println("  - Import statements will be considered as LOC");
	println("  - Comments will NOT be considered as a LOC");
	println("  - Empty lines will NOT be considered as a LOC");
	if (analysysIsDebug) print("- Progress: ");
	metricTotalVolume = calculateVolume(projectM3Model, analysysIsDebug);
	metricVolumeResult = calculateVolumeResult(metricTotalVolume);
	println("\n- Volume:\t <metricTotalVolume>");
	println("\> Metric table (Source: SIG):");
	println("\> --------------------------------");
	println("\> Rank | Man years  | KLOC in Java");
	println("\> --------------------------------");
	println("\>  + + |   0 - 8    |    0 - 66");
	println("\>   +  |   8 - 30   |   66 - 246");
	println("\>   0  |  30 - 80   |  245 - 665");
	println("\>   -  |  80 - 160  |  655 - 1310");
	println("\>  - - |   \> 160    |    \> 1310");
	println("- Resulting in:\t <convertResult(metricVolumeResult)> (<convertResultStars(metricVolumeResult)>))");
}

private void doPhase3_UnitSize() {
	println("** Phase 3: Calculating metric: Unit Size");
	println("- Will be computed based on the SIG Unit Size metric");
	if (analysysIsDebug) print("- Progress: ");
	metricTotalUnitSize = calculateUnitSize(projectM3Model, analysysIsDebug);
	metricUnitSizeResult = calculateUnitSizeResult(metricTotalUnitSize, metricTotalVolume);
	if (analysysIsDebug) println();
	println("- The LOC of each method will be categorized in the following categories:");
	println("\> Metric table (Source: <|http://docs.sonarqube.org/display/SONARQUBE45/SIG+Maintainability+Model+Plugin|>):");
	println("\> ----------------");
	println("\> Category |  LOC");
	println("\> ----------------");
	println("\> Very high| \> 100 ");
	println("\> High     | \> 50");
	println("\> Medium   | \> 10");
	println("\> Low      | \> 0");
	println("- Each category will be compared to the following table to compute the result:");
	println("\> Metric table (Source: SIG):");
	println("\> --------- Maximum relative LOC ---");
	println("\> Rank | Moderate | High | Very high ");
	println("\> ----------------------------------");
	println("\>  + + |   25%    |  0%  |   0%");
	println("\>   +  |   30%    |  5%  |   0%");
	println("\>   0  |   40%    | 10%  |   0%");
	println("\>   -  |   50%    | 15%  |   5%");
	println("\>  - - |    -     |  -   |    -");
	println("- The total LOC that is used here is the Volume calculated earlier.");
	println("- Resulting in:\t <convertResult(metricUnitSizeResult)> (<convertResultStars(metricUnitSizeResult)>))");
}
private void doPhase4_UnitComplexity() {
	println("** Phase 4: Calculating metric: Unit Complexity");
	println("- Will be computed based on the SIG Unit Complexity metric");
	metricTotalUnitComplexity = calculateUnitComplexity(metricTotalUnitSize, projectM3Model);
	metricUnitComplexityResult = calculateUnitComplexityResult(metricTotalUnitComplexity, metricTotalVolume);
	println("- The LOC of each method will be categorized in the following categories:");
	println("\> Metric table (Source: SIG):");
	println("\> ----------------");
	println("\> Category |  LOC");
	println("\> ----------------");
	println("\> Very high| \> 50 ");
	println("\> High     | 21-50");
	println("\> Medium   | 11-20");
	println("\> Low      |  1-10");
	println("- Each category will be compared to the following table to compute the result:");
	println("\> Metric table (Source: SIG):");
	println("\> --------- Maximum relative LOC ---");
	println("\> Rank | Moderate | High | Very high ");
	println("\> ----------------------------------");
	println("\>  + + |   25%    |  0%  |   0%");
	println("\>   +  |   30%    |  5%  |   0%");
	println("\>   0  |   40%    | 10%  |   0%");
	println("\>   -  |   50%    | 15%  |   5%");
	println("\>  - - |    -     |  -   |    -");
	println("- The total LOC that is used here is the Volume calculated earlier.");
	println("- Resulting in:\t <convertResult(metricUnitComplexityResult)> (<convertResultStars(metricUnitComplexityResult)>))");
}

private void doPhase5_Duplication() {
	println("** Phase 5: Calculating metric: Duplication");
	if (analysysIsDebug) print("- Progress: ");
	metricDuplications = findDuplications(bigFileOfProject, analysysIsDebug);
	if (analysysIsDebug) println();
	println("- Duplicated lines found. Calculating blocks...");
	if (analysysIsDebug) print("- Progress: ");
	metricDuplicationBlocks = calculateDuplicationBlocks(metricDuplications, analysysIsDebug);
	metricDuplicationsTotalLines = (0 | it + n | <_,n> <- metricDuplicationBlocks);
	metricDuplicationResult = calculateDuplicationResult(metricDuplicationsTotalLines, metricTotalVolume);
	if (analysysIsDebug) println();
	println("- Resulting in:\t <convertResult(metricDuplicationResult)> (<convertResultStars(metricDuplicationResult)>))");
}

private void showMetricResults() {
	println("** Result (SIG Metrics)");
	println("|--------------------------------|");
	println("| Metric \t\tResult\t | Extra comment");
	println("|--------------------------------|");
	println("\> Volume: \t\t <convertResult(metricVolumeResult)> \t | LOC: <metricTotalVolume>");
	println("\> Unit Size: \t\t <convertResult(metricUnitSizeResult)> \t |");
	println("\> Unit Complexity: \t <convertResult(metricUnitComplexityResult)> \t |");
	println("\> Duplication: \t\t <convertResult(metricDuplicationResult)> \t | DLOC: <metricDuplicationsTotalLines>");
	println();
	
	metricAnalysability = sum([metricVolumeResult, metricDuplicationResult, metricUnitSizeResult]) / 3; // 3 is the size of this list
	metricChangeability = sum([metricUnitComplexityResult, metricDuplicationResult]) / 2;
	metricTestability = sum([metricUnitComplexityResult, metricUnitSizeResult]) / 2;
	
	println("** Result (ISO Metrics)");
	println("|--------------------------------|");
	println("| Metric \t\tResult\t | Used metrics to compute");
	println("|--------------------------------|");
	println("\> Analysability: \t <convertResultStars(metricAnalysability)> \t | Volume, Duplication, Unit Size");
	println("\> Changeability: \t <convertResultStars(metricChangeability)> \t | Unit Complexity, Duplication");
	println("\> Testability: \t\t <convertResultStars(metricTestability)> \t | Unit Complexity, Unit Size");
	
	metricMaintainability = sum([metricAnalysability, metricChangeability, metricTestability])/3;
	println("|--------------------------------|");
	println("\> Maintainability: \t <convertResultStars(metricMaintainability)> \t | Analysability, Changeability, Testability");
	
	//loc local = |http://localhost:8080|;
	//server(local, metricAnalysability, metricChangeability, metricTestability, metricMaintainability);
	//println("Server started at <local>");
}

private void tearDownAnalyzer() {
	analysisEndTime = now();
	println("- End time: <printDateTime(analysisEndTime)>");
	println("- Analysis duration (y,m,d,h,m,s,ms): <createDuration(analysisStartTime, analysisEndTime)>");
}