

MICROPYTHON_GITHUB := https://github.com/micropython/micropython/archive/refs/heads/master.zip


.PHONY: get-micropython
get-micropython:
	@echo "Getting Micropython..."

	@echo "Removing any previous repos or binary files..."
	@-rm micropython.zip
	@-rm -rf micropython

	@echo "Downloading micropython..."
	@wget \
		--no-verbose \
		--output-document micropython.zip \
		--show-progress \
		$(MICROPYTHON_GITHUB)

	@echo "Unzipping micropython..."
	@unzip -q -o micropython.zip
	@mv micropython-master micropython

	@echo "Removing zip file..."
	@-rm micropython.zip

.PHONY: build-mpy-cross
build-mpy-cross: get-micropython
	
	@echo "Building mpy-cross..."
	@cd micropython/mpy-cross && make -j4 >> /dev/null
	
	@echo "Moving mpy-cross to tools directory..."
	@mv micropython/mpy-cross/build/mpy-cross tools/mpy-cross
	
.PHONY: build-binary-python-pacakges
build-binary-python-pacakges
	@echo "Building binary python packages..."
	@cd tools && mpy-cross 
