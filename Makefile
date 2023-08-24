 ifeq (, $(shell which jq))
 $(error "No jq in $(PATH), consider doing apt-get install jq")
 endif

 ifeq (, $(shell which poetry))
 $(error "No poetry in $(PATH), consider doing curl -sSL https://install.python-poetry.org | python3 -")
 endif

PICO_FIRMWARE_DOWNLOAD_PATH := https://datasheets.raspberrypi.com/soft/micropython-firmware-pico-w-130623.uf2
PICO_NUKE_DOWNLOAD_PATH := https://datasheets.raspberrypi.com/soft/flash_nuke.uf2
PICO_FIRMWARE_FILE_NAME := firmware.uf2 
PICO_NUKE_FILE_NAME := nuke.uf2

PROJECT_DIR := raspberry-pi-pico
DEPENDENCIES_DIR := dependencies
BUILD_DIR := build
CONFIG_DIR := config
TOOLS_DIR := tools
FIRMWARE_DIR := firmware
BIN_DIR := bin


MICROPYTHON_GITHUB := https://github.com/micropython/micropython/archive/refs/heads/master.zip
PACKAGES:= $(shell jq '.PACKAGES | to_entries[] | .value' ${CONFIG_DIR}/setup.json)



.PHONY: clean
clean:
	@echo "Cleaning..."
	@-rm micropython.zip
	@-rm -rf ${BUILD_DIR} ${TOOLS_DIR} ${DEPENDENCIES_DIR} ${BIN_DIR} ${FIRMWARE_DIR}
	@echo

tools:
	@echo "Creating ${TOOLS_DIR} directory..."
	@mkdir ${TOOLS_DIR}
	

dependencies:
	@echo "Creating ${DEPENDENCIES_DIR} directory..."
	@mkdir ${DEPENDENCIES_DIR}
	@curl -s $(PICO_NUKE_DOWNLOAD_PATH) -o $(DEPENDENCIES_DIR)/$(PICO_NUKE_FILE_NAME)
	@curl -s $(PICO_FIRMWARE_DOWNLOAD_PATH) -o $(DEPENDENCIES_DIR)/$(PICO_FIRMWARE_FILE_NAME)
	@$(foreach package,$(PACKAGES), \
		curl -s $(package) -o $(DEPENDENCIES_DIR)/$(shell basename $(package)); \
	)

firmware:
	@echo "Creating ${FIRMWARE_DIR} directory..."
	@mkdir ${FIRMWARE_DIR}

bin:
	@echo "Creating ${BIN_DIR} directory..."
	@mkdir ${BIN_DIR}

tools/mpy-cross: tools
	@echo "Getting Micropython..."

	@wget \
		--quiet \
		--output-document micropython.zip \
		$(MICROPYTHON_GITHUB)

	@echo "Unzipping micropython..."

	@unzip -q -o micropython.zip -d tools
	@mv ${TOOLS_DIR}/micropython-master ${TOOLS_DIR}/micropython

	@echo "Removing zip file..."
	@-rm micropython.zip

	@echo "Compiling mpy-cross..."
	@(cd ${TOOLS_DIR}/micropython/mpy-cross && make -j4 )>> /dev/null

	@echo "Moving mpy-cross..."
	@mv ${TOOLS_DIR}/micropython/mpy-cross/build/mpy-cross tools
	
	@echo "Removing micropython source..."
	@-rm -rf ${TOOLS_DIR}/micropython

.PHONY: build
build: tools/mpy-cross dependencies firmware bin
	@mkdir -p $(BIN_DIR)
	@$(foreach package,$(PACKAGES), \
		echo "Downloading $(package) and storing to $(DEPENDENCIES_DIR)/$(shell basename $(package))"; \
		curl -s $(package) -o $(DEPENDENCIES_DIR)/$(shell basename $(package)); \
		echo "Compiling $(shell basename -s .py $(package)).mpy from $(DEPENDENCIES_DIR)/$(shell basename $(package))";  \
		./${TOOLS_DIR}/mpy-cross $(DEPENDENCIES_DIR)/$(shell basename $(package)) -o ${FIRMWARE_DIR}/$(shell basename -s .py $(package)).mpy; \
		echo ; \
	)

#	@cp ${BIN_DIR}/*.mpy ${FIRMWARE_DIR}/
	@cp -r ${PROJECT_DIR}/* ${FIRMWARE_DIR}/



.PHONY: setup
setup:
	poetry install

.PHONY: list-pico-devices
list-pico-devices: setup
	poetry run python -m mpremote connect list

.PHONY: pico-prep-flash
pico-prep-flash: 
	@echo "Putting Pico into bootloader mode..."
	-@poetry run python -m mpremote bootloader
	@sleep 5
	@echo "Mounting Pico file system..."
	-@lsblk -o "PATH,LABEL" | grep RPI-RP2 | grep -Po "/dev/\w*" | xargs -I{} udisksctl mount -b {} 

.PHONY: pico-clean
pico-clean: setup pico-prep-flash dependencies
	@echo "Nuking Pico file system"
	@find /media/$(USER) -type d -name "RPI-RP2" -exec cp $(DEPENDENCIES_DIR)/$(PICO_NUKE_FILE_NAME) {} \;

.PHONY: pico-flash
pico-flash: setup pico-prep-flash dependencies
	@sleep 5
	@echo "Flashing with $(PICO_FIRMWARE_FILE_NAME)..."
	@find /media/$(USER) -type d -name "RPI-RP2" -exec cp $(DEPENDENCIES_DIR)/$(PICO_FIRMWARE_FILE_NAME) {} \;


.PHONY: pico-connect
pico-connect: setup
	poetry run python -m mpremote connect auto


.PHONY: pico-disconnect
pico-disconnect: setup
	poetry run python -m mpremote disconnect

.PHONY: pico-reset
pico-reset: setup
	poetry run python -m mpremote soft-reset

$(DEPENDENCIES_DIR)/$(PICO_FIRMWARE_FILE_NAME): dependencies
	curl $(PICO_FIRMWARE_DOWNLOAD_PATH) -o $(DEPENDENCIES_DIR)/$(PICO_FIRMWARE_FILE_NAME)

.PHONY: pico-copy-project
pico-copy-project: setup
	poetry run python -m mpremote cp -r $(FIRMWARE_DIR) : + cp main.py :main.py + soft-reset + fs ls + fs ls /$(FIRMWARE_DIR)

.PHONY: pico-run
pico-reboot: setup
	poetry run python -m mpremote 

.PHONY: pico-ip-address
pico-ip-address: setup
	poetry run python -m mpremote exec "import socket; print(socket.gethostname())"