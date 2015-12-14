dstructtotypescript is a program that created typescript interfaces out of D
structs.

The web framework vibe.d was very strong struct to json serializing
capabilities. Typescript allows the user to have a typed version of
javascript. Which means the user has to keep two version of the same structure
in sync. That is tedious and error prone work. dstructtotypescript alleviates
that problem as its automatically generates the typescript for the user.

Given a D two structs (test/struct.d):
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
```

```bash
dstructtotypescript -i test/teststruct.d -p test/testfileprefix.ts -s Obj -s Colors -s Other -d
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
```

test/testfileprefix.ts is a file whos containted is prefixed to the resulting
.ts file
