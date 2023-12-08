.SILENT:

shared: bin/realsense_ffi.so install

bin/realsense_ffi.so: obj/realsense_ffi.o obj/realsense_internal.o
	mkdir -p bin
	g++ -Wall -Werror -shared obj/realsense_ffi.o obj/realsense_internal.o -o bin/realsense_ffi.so

obj/realsense_internal.o: realsense_internal.hpp realsense_internal.cpp
	mkdir -p obj
	g++ -Wall -Werror -c realsense_internal.cpp -o obj/realsense_internal.o

obj/realsense_ffi.o: realsense_ffi.h realsense_ffi.cpp
	mkdir -p obj
	g++ -Wall -Werror -c realsense_ffi.cpp -o obj/realsense_ffi.o

install: 
	sudo cp bin/realsense_ffi.so /usr/lib

clean: 
	rm -rf bin obj
	sudo rm -f /usr/lib/realsense_ffi.so 
