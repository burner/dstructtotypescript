all:
	dmd dstructtotypescript.d

test: all
	./dstructtotypescript -i test/teststruct.d -p test/testfileprefix.ts -s Obj \
		-s Colors -s Other -d -s Model
	tsc test/test.ts
