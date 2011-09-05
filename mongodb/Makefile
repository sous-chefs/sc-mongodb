
COOKBOOK=mongodb
BRANCH=master

BUILD_DIR=../build
DIST=$(BUILD_DIR)/$(COOKBOOK).tar.gz

all: metadata.json

clean:
	-rm metadata.json
	-rm $(DIST)

metadata.json:
	-rm $@
	knife cookbook metadata -o .. $(COOKBOOK)
	
dist: clean metadata.json
	mkdir -p $(BUILD_DIR)
	tar --exclude-vcs --exclude=Makefile -cvzf $(DIST) *
