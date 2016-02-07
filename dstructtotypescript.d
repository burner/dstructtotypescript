import std.getopt;
import std.array : empty;
import std.stdio;
import std.format;
import std.path;
import std.process;
import std.file;

string progHeader = q{
string prefixContent = `%s`;
};

string progImports = q{
import std.stdio;
import std.traits;
import std.range;
import std.experimental.logger;
};

string progMain = `
void main() {
	auto outfile = File("%s", "w");
	outfile.writeln("// THIS FILE WAS GENERATED DO NOT MODIFY");
	outfile.writeln(prefixContent);
	outfile.writeln("module %s {");
`;

string recursiveTypeBuild = q{
void recursiveTBuild(T,O)(ref O outfile) {
	static if(isNumeric!(T) && !isCallable!(T)) {
		outfile.write(": number");
	} else static if(isBoolean!(T) && !isCallable!(T)) {
		outfile.write(": boolean");
	} else static if(isSomeString!(T) && !isCallable!(T)) {
		outfile.write(": string");
	} else static if(isAggregateType!(T) && !isCallable!(T)) {
		outfile.write(": ");
		outfile.write(T.stringof);
	} else static if(isArray!(T) && !isCallable!(T)) {
		recursiveTBuild!(Unqual!(ElementType!T))(outfile);
		outfile.write("[]");
	} else {
		return;
	}
}

private size_t rank(E)(string name)
    if (is(E == enum))
{
    foreach (i, member; EnumMembers!E)
    {
        if(__traits(identifier, EnumMembers!E[i]) == name) {
            return member;
		}
    }
    assert(0, "Not an enum member");
}

enum bool isInterface(T) = is(T == interface);

void enumBuild(T,O)(ref O outfile) {
	outfile.writef("export enum %s {", T.stringof);
	bool first = true;
	foreach(i, name; EnumMembers!T) {
		if(!first) {
			outfile.write(",\n");
		} else {
			outfile.write("\n");
			first = false;
		}

		outfile.writef("\t%s = %s", name, 
			rank!(T)(__traits(identifier, EnumMembers!T[i]))
		);
	}
	outfile.writeln("\n}\n");
}

template TypeMapper(T, string back = "") {
	static if(isNumeric!T) {
		enum TypeMapper = "number" ~ back;
	} else static if(isBoolean!T) {
		enum TypeMapper = "boolean" ~ back;
	} else static if(isSomeString!T) {
		enum TypeMapper = "string" ~ back;
	} else static if(isAggregateType!T) {
		enum TypeMapper = T.stringof ~ back;
	} else static if(isArray!T) {
		enum TypeMapper = TypeMapper!(ElementType!T) ~ back;
	} else static assert(false, T.stringof);
}

string buildParams(T,string member)() {
	import std.meta : staticMap;
	import std.traits : Parameters, ParameterIdentifierTuple;
	import std.algorithm.iteration : map;
	import std.typecons : tuple, Tuple;
	import std.format : format;
	auto paraType = [staticMap!(
		TypeMapper,
		Parameters!(__traits(getMember, T, member))
	)];

	auto paraIds = [ParameterIdentifierTuple!(__traits(getMember, T, member))];

	auto app = appender!string();
	bool notFirst = false;
	foreach(a, b; lockstep(paraIds, paraType)) {
		if(notFirst) {
			app.put(", ");	
		} else {
			notFirst = true;
		}
		app.put(format("%s: %s", a, b));
	}

	return app.data;
}

string urlFromFuncName(string name) {
	import std.string : indexOf;
	import std.uni : isUpper, toLower;
	auto app = appender!string();
	auto gIdx = name.indexOf("get");
	auto pIdx = name.indexOf("post");
	if(gIdx != -1) {
		name = name[3 .. $];
	} else if(pIdx != -1) {
		name = name[4 .. $];
	}

	foreach(idx, it; name) {
		if(idx != 0 && isUpper(it)) {
			app.put("_");
			app.put(toLower(it));
		} else if(isUpper(it)) {
			app.put(toLower(it));
		} else {
			app.put(it);
		}
	}

	return app.data;
}

void interfaceBuild(T,O)(ref O outfile) {
	outfile.writefln("%s = new function() {", T.stringof);
	outfile.writeln("\tvar toRestString = function(v:any) :any { return v; }");
	foreach(it; __traits(allMembers, T)) {
		static if(isCallable!(__traits(getMember, T, it))) {
			outfile.writefln("\tthis.%s = function(%s, on_result, on_error) {",
				it, buildParams!(T,it)()
			);
			outfile.write("\t\tvar url = \"127.0.0.1:8080/");
			outfile.write(urlFromFuncName(it));
			outfile.writeln("\";");
			foreach(jt; [ParameterIdentifierTuple!(__traits(getMember, T, it))]) {
				outfile.write("\t\turl = url + \"?");
				outfile.write(jt);
				outfile.write("=\" + encodeURIComponent(toRestString(");
				outfile.write(jt);
				outfile.writeln("));");
			}
			outfile.writeln("\t\tvar xhr = new XMLHttpRequest();");
			outfile.writeln("\t\txhr.open('GET', url, true);");
			outfile.writeln("\t\txhr.onload = function () { ");
			outfile.writeln("\t\t\tif(this.status >= 400) { ");
			outfile.writeln("\t\t\t\tif(on_error) {");
			outfile.writeln("\t\t\t\t\ton_error(JSON.parse(this.responseText));");
			outfile.writeln("\t\t\t\t} else {");
			outfile.writeln("\t\t\t\t\tconsole.log(this.responseText); ");
			outfile.writeln("\t\t\t\t}");
			outfile.writeln("\t\t\t} else {");
			outfile.writeln("\t\t\t\ton_result(JSON.parse(this.responseText)); ");
			outfile.writeln("\t\t\t}");
			outfile.writeln("\t\t}");
		    outfile.writeln("\t\txhr.send();");
		    outfile.writeln("\t}");
		}
	}
	outfile.writeln("}");
}
};

string progBody = q{void writeStructOrClass(T,O)(ref O outfile) {
	alias AliasObj = T;
	outfile.writefln("export interface %s {", T.stringof);
	foreach(it; __traits(allMembers, AliasObj)) {
		outfile.write("\t");
		outfile.write(it);

		recursiveTBuild!(
			Unqual!(typeof(__traits(getMember, AliasObj, it)))
		)(outfile);
		
		outfile.writeln(";");
	}
	outfile.writeln("}\n");
}};

int main(string[] args) {
	string inputFile;
	string[] structNames;
	string outputFile;
	string[] prefixFiles;
	bool keepRdmdFile;
	string moduleName;

	auto rslt = getopt(args, 
		"i|input",
		"The path to the file to search the struct in.", &inputFile,

		"s|struct",
		"The name of the struct to create the typestrict interface of.",
		&structNames,

		"p|prefix",
		"Paths to files which content should be placed at the front of the"
		~ " outputfile", &prefixFiles,

		"d|debug", "Do not delete the rdmd generator file", &keepRdmdFile,

		"m|module", "The name of the module.", &moduleName,

		"o|output",
		"The path to the file to write the typescript interface to.",
		&outputFile
	);

	if(inputFile.empty || structNames.empty || rslt.helpWanted) {
		defaultGetoptPrinter("dstructtotypescript\n\nUsage example:\n"~
			"dstructtotypescript -i INPUTFILE -s NAMEOFSTRUCT\n", rslt.options);
		return 1;
	}

	if(outputFile.empty) {
		outputFile = inputFile.stripExtension() ~ ".ts";
	}

	string runnerFile = format("%s%d%s", inputFile.stripExtension(),
		thisProcessID(), "_runner_.d"
	);

	string prefixContent;
	foreach(file; prefixFiles) {
		prefixContent ~= readText(file);
	}

	{
		auto file = File(runnerFile, "w");

		auto inputFileHandle = File(inputFile, "r");
		foreach(line; inputFileHandle.byLine) {
			file.writeln(line);
		}

		file.writefln(progHeader, prefixContent);
   
		file.write(progImports ~ progMain.format(outputFile, moduleName));
		foreach(string it; structNames) {
			file.writefln("\tstatic if(isInterface!(%s)) {", it);
			file.writefln("\t\tinterfaceBuild!(%s)(outfile);", it);
			file.writefln("\t} else static if(isAggregateType!(%s)) {", it);
			file.writefln("\t\twriteStructOrClass!(%s)(outfile);", it);
			file.writefln("\t} else static if(is(%s == enum)) {", it);
			file.writefln("\t\tenumBuild!(%s)(outfile);", it);
			file.write("\t} else ");
			file.writeln(
				"{\n\t\tstatic assert(false, " ~
				"\"Must be struct, class or enum\");\n\t}"
			);
		}
		file.writeln("\toutfile.writeln(\"}\n\");\n");
		file.writeln("}\n\n");
		file.writeln(recursiveTypeBuild);
		file.writeln(progBody);
	}

	string shellCmd = "rdmd %s".format(runnerFile);
	auto pid = spawnShell(shellCmd);
	auto rsltRdmd = wait(pid);
	if(!keepRdmdFile && exists(runnerFile) && isFile(runnerFile)) {
		remove(runnerFile);
	}
	return rsltRdmd;
}
