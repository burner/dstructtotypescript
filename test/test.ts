/// <reference path="teststruct.ts" />

var o: Other = {id:"hello"};
o.id = "must accept string";

var ob: Obj;
ob.name ="must be a string";
ob.id = 1337;
ob.value = 13.37;
ob.ids = [1,2,3,4];
ob.ids2 = [[1,2,3,4]];
ob.other = o;
ob.others = [o];
ob.others2 = [[[o]]];
ob.bools = [[true, false, true]];

if(Colors.red != 0) {
	console.log("red not 0");
}
if(Colors.blue != 1) {
	console.log("blue not 1");
}
if(Colors.green != 4) {
	console.log("green not 4");
}
