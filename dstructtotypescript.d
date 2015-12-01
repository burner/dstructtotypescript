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
	outfile.writeln(prefixContent);
`;

string progBody = q{
	alias AliasObj = %s;
	outfile.writeln("interface %s {");
	foreach(it; __traits(allMembers, AliasObj)) {
		static if(isNumeric!(typeof(__traits(getMember, AliasObj, it)))) {
			outfile.writeln("\t" ~ it ~ ": number;");
		} else static if(isArray!(typeof(__traits(getMember, AliasObj, it)))
				&& isNumeric!(ElementType!(typeof(__traits(getMember, AliasObj, it))))) 
		{
			outfile.writeln("\t" ~ it ~ ": number[];");
		} else static if(isSomeString!(typeof(__traits(getMember, AliasObj, it)))) {
			outfile.writeln("\t" ~ it ~ ": string;");
		} else static if(isArray!(typeof(__traits(getMember, AliasObj, it)))
				&& isSomeString!(ElementType!(typeof(__traits(getMember, AliasObj, it))))) 
		{
			outfile.writeln("\t" ~ it ~ ": string[];");
		} else static if(isAggregateType!(typeof(__traits(getMember, AliasObj, it)))) {
			outfile.writeln("\t" ~ it ~ ": " ~ typeof(__traits(getMember, AliasObj, it)).stringof
				~ ";");
		} else static if(isArray!(typeof(__traits(getMember, AliasObj, it)))
				&& isAggregateType!(ElementType!(typeof(__traits(getMember, AliasObj, it))))) 
		{
			outfile.writeln("\t" ~ it ~ ": " ~ typeof(__traits(getMember, AliasObj, it)).stringof
				~ ";");
		}
	}
	outfile.writeln("}\n");
};

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
			file.write("\t{");
			file.write(progBody.format(it, it));
			file.writeln("\t}");
		}
		file.writeln("}\n");
	}

	string shellCmd = "rdmd %s".format(runnerFile);
	auto pid = spawnShell(shellCmd);
	auto rsltRdmd = wait(pid);
	if(!keepRdmdFile && exists(runnerFile) && isFile(runnerFile)) {
		remove(runnerFile);
	}
	return rsltRdmd;
}
