module Cache

import Prelude;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

private loc cacheLoc = |project://CloneDetection/src/cache/|;

public set[Declaration] createAstsFromProject(loc project, bool useCache, bool debug = false) {
	set[Declaration] ast;
	
	if (!exists(astCacheFile(project)) || !useCache) {
		writeCacheFile(project, debug);
	}
	
	return loadCacheFile(astCacheFile(project), debug);
}

public void writeCacheFile(loc project, bool debug) {
	set[Declaration] ast = createAstsFromEclipseProject(project, true);
	
	if (debug) println("writing cache file to: <astCacheFile(project)>");
	writeBinaryValueFile(astCacheFile(project), ast);
}

public set[Declaration] loadCacheFile(loc file, bool debug) {
	if (debug) println("load cache file: <file>");
	return readBinaryValueFile(#set[Declaration], file);
}

public loc astCacheFile(loc project) {
	return cacheLoc + "<project.authority + project.path>.ast";
}
