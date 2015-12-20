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
