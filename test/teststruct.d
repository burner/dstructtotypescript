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
	bool[][5][] bools;
}
