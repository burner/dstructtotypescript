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
};

string progMain = `
void main() {
	auto outfile = File("%s", "w");
	outfile.writeln("// THIS FILE WAS GENERATED DO NOT MODIFY");
	outfile.writeln(prefixContent);
`;

string recursiveTypeBuild = q{
void recursiveTBuild(T,O)(ref O outfile) {
	static if(isNumeric!(T)) {
		outfile.write(": number");
	} else static if(isBoolean!(T)) {
		outfile.write(": boolean");
	} else static if(isSomeString!(T)) {
		outfile.write(": string");
	} else static if(isAggregateType!(T)) {
		outfile.write(": ");
		outfile.write(T.stringof);
	} else static if(isArray!(T)) {
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

void enumBuild(T,O)(ref O outfile) {
	outfile.writef("enum %s {", T.stringof);
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
};

string progBody = q{void writeStructOrClass(T,O)(ref O outfile) {
	alias AliasObj = T;
	outfile.writefln("interface %s {", T.stringof);
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
   
		file.write(progImports ~ progMain.format(outputFile));
		foreach(string it; structNames) {
			file.writefln("\tstatic if(isAggregateType!(%s)) {", it);
			file.writefln("\t\twriteStructOrClass!(%s)(outfile);", it);
			file.writefln("\t} else static if(is(%s == enum)) {", it);
			file.writefln("\t\tenumBuild!(%s)(outfile);", it);
			file.write("\t} else ");
			file.writeln(
				"{\n\t\tstatic assert(false, " ~
				"\"Must be struct, class or enum\");\n\t}"
			);
		}
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
