
DIRS = mongodb

BUILD_DIR=../build

dist: clean
	mkdir -p $(BUILD_DIR)
	for i in $(DIRS); do make -C $$i $@; done
	
metadata.json:
	for i in $(DIRS); do make -C $$i $@; done
	
clean:
	-rm -r $(BUILD_DIR)
