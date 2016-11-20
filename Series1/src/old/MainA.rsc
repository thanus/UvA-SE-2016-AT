module MainA

/**
 * Alex Kok
 * alex.kok@student.uva.nl
 * 
 * Thanusijan Tharumarajah
 * thanus.tharumarajah@student.uva.nl
 */

import IO;
//import List;
import String;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::m3::AST;
import ParseTree;
import vis::ParseTree;
import util::LOC;
import lang::java::\syntax::Java15;
import Set;

//public loc prLoc = |project://MetricsTests2/src|;
public loc prLoc = |project://smallsql0.21_src/src|;
//public M3 m = createM3FromEclipseProject(prLoc);
//public M3 m = createM3FromEclipseProject(|project://MetricsTests2|);
//public Declaration d = getMethodASTEclipse(|java+method:///main/Main/main(java.lang.String%5B%5D)|, model=m);

public void main2() {
	println("Starting metrics analysis");
	
	//m = createM3FromEclipseProject(|project://MetricsTests2|);
	//m = createM3FromEclipseProject(|project://smallsql0.21_src|);
	names = m@names;
	//iprint(methods(m));
	//iprint(m@containment);
	//iprint(m@containment[|java+class:///main/Main|]);
	//[ e | e <- m@containment[|java+class:///main/Main|], e.scheme == "java+method"];
	
	cl = |java+class:///main/Main|;
	x = size([ st | st <- m@containment[cl], isMethod(st)]);
	println(x);
	
	//map[loc class, int methodCount] numberOfMethodsPerClass = (cl:numberOfMethods(cl, m) | <cl,_> <- m@containment, isClass(cl));
	//> map[loc class, int methodCount]: (
	//   |java+class:///Fruit|:1,
	//   |java+class:///Apple|:1,
	//   |java+class:///HelloWorld|:1
	// )
	//theLocation = getOneFrom(files(m));
	theLocation = prLoc + "main/Main.java";
	//theLocation = |project://MetricsTests2/src/main/Main.java|;
	println("The location: <theLocation>");
	try {
		t = parse(#CompilationUnit, theLocation);
		println(countSLOC(t));
	} catch ParseError(loc l): {
		println("I found a parse error at line <l.begin.line>, column <l.begin.column>");
	}
}

public int calculateLOC(theType, loc location) { // Not sure what the type is of the first argument
	try {
		//t = parse(#start[CompilationUnit], location);
		//t = parse(#MethodDec, location);
		t = parse(theType, location);
		countSLOC(t);
		return countSLOC(t);
	} catch ParseError(loc l): {
		println("<l>");
		println("Found a parse error at line <l.begin.line>, column <l.begin.column>");
		return -1;
	}
}

public list[tuple[loc, int]] filesLOC(loc root) {
	list[tuple[loc, int]] result = [<ls, calculateLOC(#start[CompilationUnit], ls)> | ls <- root.ls, !isDirectory(ls)];
	for (nl <- [rst | rst <- root.ls, isDirectory(rst)]) { // The dirs
		result += filesLOC(nl);
	}
	return result;
}

public int calculateVolume(loc project) {
	iprintln(filesLOC(project));
	return (0 | it + e | <_, e> <- filesLOC(project), e != -1); // -1 means it was an error.
}

public void calculateUnitSize(loc project) {
	println("Creating M3 model from project");
	M3 m = createM3FromEclipseProject(project);
	
	println("Calculating LOC per method");
	list[tuple[loc, int]] methodsLOC = [<l,calculateLOC(#MethodDec, l)> | l <- methods(m)];
	iprintln(methodsLOC);
	
	map[int, int] amountPerCategory = (1: 0, 2: 0, 3: 0, 4: 0);
	for (<ml,n> <- methodsLOC) { // ml unused atm
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
		} else {
			// We had a parse error here
			;
		}
	}
	iprintln(amountPerCategory);
	int volume = calculateVolume(project);
	map[int, int] percentsPerCategory = (
		1: amountPerCategory[1] * 100 / volume, 
		2: amountPerCategory[2] * 100 / volume, 
		3: amountPerCategory[3] * 100 / volume, 
		4: amountPerCategory[4] * 100 / volume 
		);
	
	// Now we know the LOC per category, we can define the percentages.
	iprintln(percentsPerCategory);
	print("Result: ");
	if (percentsPerCategory[2] <= 25 && percentsPerCategory[3] == 0 && percentsPerCategory[4] == 0) {
	 	println("++");
	} else if (percentsPerCategory[2] <= 30 && percentsPerCategory[3] <= 5 && percentsPerCategory[4] == 0) {
	 	println("+");
	} else if (percentsPerCategory[2] <= 40 && percentsPerCategory[3] <= 10 && percentsPerCategory[4] == 0) {
	 	println("0");
	} else if (percentsPerCategory[2] <= 50 && percentsPerCategory[3] <= 15 && percentsPerCategory[4] <= 5) {
	 	println("-");
	} else {
	 	println("--");
	}
}

public void calculateUnitComplexity(loc project) {
	// Duplicate!
	println("Creating M3 model from project");
	M3 m = createM3FromEclipseProject(project);
	
	println("Calculating LOC per method");
	list[tuple[loc, int, int]] methodsLOC = [<l,calculateLOC(#MethodDec, l), 0> | l <- methods(m)];
	iprintln(methodsLOC);
	// EndDuplicate!
	
	for (<ml,n,d> <- methodsLOC) { 
		// calcluate complexity for this method
		int complexity = 1;
		Declaration d = getMethodASTEclipse(ml, model=m);
		
		int ifStatements = 0, 
			forStatements = 0, 
			whileStatements = 0, 
			caseStatements = 0, 
			catchStatements = 0,
			andStatements = 0,
			orStatements = 0,
			ternaryStatements = 0,
			assertStatements = 0
			;
		
		visit (d) {
			case \if(_,_) : 		ifStatements    += 1; // if-then 
			case \if(_,_,_) : 		ifStatements    += 1; // if-then-else
			case \foreach(_,_,_) : 	forStatements   += 1; // foreach
			case \for(_,_,_,_): 	forStatements   += 1; // for | with 4 params
			case \for(_,_): 		forStatements   += 1; // for | with 2 params
			case \while(_,_): 		whileStatements += 1; // while
			case \case(_): 			caseStatements  += 1; // case
			case \catch(_): 		catchStatments  += 1; // catch
			case infix(_,"&&",_): 	andStatements  	+= 1; // &&
			case infix(_,"||",_): 	orStatements  	+= 1; // &&
			case conditional(_,_,_): ternaryStatements  	+= 1; // ? | ternary operator
			case \assert(_): 		assertStatements +=1; // Assert
			case \assert(_,_): 		assertStatements +=1; // Assert
		}
		
		complexity += ifStatements 
				   += forStatements
				   += whileStatements
				   += caseStatements
				   += catchStatements
				   += andStatements
				   += orStatements
				   += ternaryStatements
				   += assertStatements
				   ;
		println("Complexity is <complexity>\tfor method: <ml.path>");
		;
	}
	
}

public void calculateDuplication(loc project) {
	println("Creating model from project");
	M3 m = createM3FromEclipseProject(project);
	//println("Rendering parse tree");
	//iprintln(m);
	//renderParsetree(parse(#CompilationUnit, m));
	classesToCheck = toList(classes(m));
	allClasses = toList(files(m));
	
	println("Finding duplicates");
	int totalDuplications = 0;
	for (i <- [0..size(classesToCheck)]) {
		f = classesToCheck[i];
		//afi = |java+class:///main/Main|;
		println("[<i+1>/<size(classesToCheck)>] Checking: <substring(f.path, findLast(f.path, "/")+1)>");
		//theSrc = readFile(|java+class:///main/Main|);
		//println("<theSrc>");
		
		for (j <- [0..size(allClasses)]) {
			f2 = allClasses[j];
			//println(" : <substring(f2.path, findLast(f2.path, "/")+1)>");
			duplications = findDuplications(f, f2);
			totalDuplications += size(duplications);
			if (size(duplications) > 0) {
				println("-   Duplications: <size(duplications)>\n");
			} else {
				print(".");
				//;
			}
		}
		println();
	}
	println("\> Total duplications: <totalDuplications>");
}

public list[tuple[str, str]] findDuplications(loc src1, loc src2) {
	// TODO: Implement for readfileLines instead of ReadFile
	list[tuple[str, str]] dups = [];
	src1lines = split("\r\n", readFile(src1));
	src2lines = split("\r\n", readFile(src2));
	
	str chStLine; // Checking start line
	int lStart, lEnd;
	int i = 0;
	//for (i <- [0..size(src1lines)]) { // While i < size...
	while (i < size(src1lines)) {
		chStLine = src1lines[i];
		
		//for (j <- [0..size(src2lines)], src2lines[j] == chStLine) { //dupL <- src2lines, chStLine == dupL) {
		int j = i;
		int maxI2 = 0;
		int totalLines = 1;
		while (j < size(src2lines)) {
			int i2 = 0;
			int j2 = 0;
			if (trim(chStLine) == trim(src2lines[j]), isValidDupLine(chStLine), containsWords(chStLine)  ) { 
				lStart1 = i;
				lStart2 = j;
				theDuplicate = chStLine;
				// Using while to construct it
				i2 = i+1;
				j2 = j+1;
				totalLines = 1;
				while (i2 < size(src1lines), j2 < size(src2lines), trim(src1lines[i2]) == trim(src2lines[j2])) {
					theDuplicate += "\r\n" + src1lines[i2];
					if (shouldIncreaseDupLineCount(trim(src1lines[i2]))) {
						totalLines += 1;
					}
					i2 += 1;
					j2 += 1;
				}
				if (src1 == src2 && (lStart1 == lStart2 || lStart2 in [lStart1..i2+1])) { 
					// Check if lstart2-i2 does not consist in lstart1-i2
					// 16 - 25  |  17 - 26
					;
				} else { 
					if (maxI2 < totalLines) { maxI2 = totalLines; }
					//println("Full duplicate:\n <theDuplicate>");
					int minDupLength = 6;
					str dupTag    = "Duplicate | <i> <i2> <lStart1> <j> <j2> <lStart2>  <totalLines> | F1_L<lStart1> : F2_L<lStart2>";
					str dupTagRev = "Duplicate | <j> <j2> <lStart2> <i> <i2> <lStart1>  <totalLines> | F1_L<lStart2> : F2_L<lStart1> ";
					if (<dupTag, theDuplicate> notin dups && totalLines != 1 && totalLines >= minDupLength) { // Ignore one line duplicates... (Don't need those anyway)
						if (isEmpty([t | <t,_> <- dups, t != dupTagRev])) {
							file1name = substring(src1.path, findLast(src1.path, "/")+1);
							file2name = substring(src2.path, findLast(src2.path, "/")+1);
							
							println("-    Found duplicate F1:<file1name> F2:<file2name>");
							//println("<dupTag>");
							//println("<dupTagRev>");
							println("-    Duplicate | <i> <i2> <lStart1> <j> <j2> <lStart2>  <totalLines> | F1_L<lStart1> : F2_L<lStart2> : \n <theDuplicate>");
							dups += <dupTag, theDuplicate>;
						} else {
							println("-   Found duplicate that is already found");
						}
					}
					j+=i2 - i;
				}
			}
			j+=1;
		}
		i += maxI2; // Increase starting line with the I2 so we ignore the block now... (ofcourse this causes us to ignore dup. 5-11 if a dup 1-12 has been found... But this will be fixed when checking it the other way around later on, probably)
		i += 1;
	}
	return dups;
}

private bool isValidDupLine(str line) {
	tmpLine = visit(line) {
   		case /^\t+<line:.*>/ => line
   	};
	return !isEmpty(tmpLine);
}
private bool containsWords(str line) {
	return /\w+/ := line;
}

private bool shouldIncreaseDupLineCount(str trimmedLine) {
	if (isEmpty(trimmedLine)) {
		return false;
	}
	if (isEmpty(replaceAll(trimmedLine, "}", ""))) {
		return false;
	}
	if (isEmpty(replaceAll(trimmedLine, "{", ""))) {
		return false;
	}
	return true;
}