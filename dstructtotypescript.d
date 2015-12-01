import std.getopt;
import std.array : empty;
import std.stdio;
import std.format;
import std.path;
import std.process;

string progHeader = q{
};

string progImports = q{
import std.stdio;
import std.traits;
import std.range;
};

string progMain = `
void main() {
	auto outfile = File("%s", "w");
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

	auto rslt = getopt(args, 
		"i|input",
		"The path to the file to search the struct in.", &inputFile,

		"s|struct",
		"The name of the struct to create the typestrict interface of.",
		&structNames,

		"p|prefix",
		"Paths to files which content should be placed at the front of the"
		~ " outputfile", &prefixFiles,

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
		outputFile = inputFile.stripExtension() ~ "_runner_.d";
	}

	{
		auto file = File(outputFile, "w");

		file.write(progHeader);
		auto inputFileHandle = File(inputFile, "r");
		foreach(line; inputFileHandle.byLine) {
			file.writeln(line);
		}
   
		string resultFile = inputFile.stripExtension() ~ ".ts";
		file.write(progImports ~ progMain.format(resultFile));
		foreach(string it; structNames) {
			file.write("\t{");
			file.write(progBody.format(it, it));
			file.writeln("\t}");
		}
		file.writeln("}\n");
	}

	string shellCmd = "rdmd %s".format(outputFile);
	auto pid = spawnShell(shellCmd);
	return wait(pid);
}
