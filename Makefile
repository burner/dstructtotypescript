all:
	dmd dstructtotypescript.d

test: all test/teststruct.ts
	./dstructtotypescript -i test/teststruct.d -p test/testfileprefix.ts -s Obj -s Colors -s Other -d
	tsc test/test.ts
