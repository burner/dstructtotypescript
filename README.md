# dstructtotypescript

dstructtotypescript is a program that created typescript interfaces out of D
structs.

The web framework vibe.d was very good at serializing data into json. 
Typescript allows the user to have a typed version of
javascript. Which means the user has to keep two version of the same structure
in sync. That is tedious and error prone task. dstructtotypescript alleviates
this problem as its automatically generates the typescript interfaces for the
user.
It also creates typesafe functions interfaces to call the vibe.d rest
services.

## Example

Given a D two structs (test/teststruct.d):
```D
module test.teststruct;

struct Other {
	string id;
}

struct Obj {
	string name;
	int id;
	float value;
	int[] ids;
	int[5][] ids2;
	Other other;
	Other[] others;
	Other[][5][] others2;
	bool[][5] bools;
}

enum Colors {
	red = 0,
	blue = 1,
	green = 4
}

interface Model {
	Other postFuncBar(Obj obj, Colors color, int id);
	Colors getFunfunc(Colors a, Obj color, Other id);
}
```

```bash
dstructtotypescript -i test/teststruct.d -p test/testfileprefix.ts -s Obj -s Colors -s Other -s Model -d
```
will create the following typescript interfaces:
```
// THIS FILE WAS GENERATED DO NOT MODIFY
/// <reference path="teststructprefix.ts" />
interface Obj {
	name: string;
	id: number;
	value: number;
	ids: number[];
	ids2: number[][];
	other: Other;
	others: Other[];
	others2: Other[][][];
	bools: boolean[][];
}

enum Colors {
	red = 0,
	blue = 1,
	green = 4
}

interface Other {
	id: string;
}
Model = new function() {
	var toRestString = function(v:any) :any { return v; }
	this.postFuncBar = function(obj: Obj, color: number, id: number, on_result, on_error) {
		.... // The impl to call the vibe rest interface
	}
	this.getFunfunc = function(a: number, color: Obj, id: Other, on_result, on_error) {
		.... // The impl to call the vibe rest interface
	}
```

test/testfileprefix.ts is a file which contains is prefixed to the resulting
.ts file

## License

GPL3
