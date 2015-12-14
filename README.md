dstructtotypescript is a program that created typescript interfaces out of D
structs.

The web framework vibe.d was very strong struct to json serializing
capabilities. Typescript allows the user to have a typed version of
javascript. Which means the user has to keep two version of the same structure
in sync. That is tedious and error prone work. dstructtotypescript alleviates
that problem as its automatically generates the typescript for the user.

Given a D two structs
```D
struct Bar {
	string bar;
}

struct Foo {
	int a;
	float b;
	string c;
	Bar bar;
}
```

dstructtotypescript will create the following typescript interfaces
```
interface Bar {
	bar: string;
}

interface Foo {
	a: number;
	b: number;
	c: string;
	bar: Bar;
}
```
