PROJECT_NAME := fruitymesh
BUILD_TYPE   ?= debug
VERBOSE      ?= 0

OUTPUT_FILENAME := $(PROJECT_NAME)

SDK_PATH      ?= $(HOME)/nrf/sdk/nrf52_sdk_latest
COMPONENTS     = $(SDK_PATH)/components
TEMPLATE_PATH  = $(COMPONENTS)/toolchain/gcc
ifeq ($(OS),Windows_NT)
include $(TEMPLATE_PATH)/Makefile.windows
else
include $(TEMPLATE_PATH)/Makefile.posix
endif

ifeq ("$(VERBOSE)","1")
NO_ECHO :=
else
NO_ECHO := @
endif

# Tools
MK              := mkdir
RM              := rm -rf
NRFJPROG        := nrfjprog

# Toolchain commands
CC              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-gcc'
CXX             := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-g++'
AS              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-as'
AR              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-ar' -r
LD              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-ld'
NM              := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-nm'
OBJDUMP         := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-objdump'
OBJCOPY         := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-objcopy'
SIZE            := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-size'
GDB             := '$(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-gdb'

#function for removing duplicates in a list
remduplicates = $(strip $(if $1,$(firstword $1) $(call remduplicates,$(filter-out $(firstword $1),$1))))

#source common to all targets
C_SOURCE_FILES += \
		$(COMPONENTS)/ble/common/ble_advdata.c \
		$(COMPONENTS)/ble/common/ble_conn_params.c \
		$(COMPONENTS)/ble/common/ble_srv_common.c \
		$(COMPONENTS)/ble/ble_radio_notification/ble_radio_notification.c \
		$(COMPONENTS)/ble/ble_services/ble_dfu/ble_dfu.c \
		$(COMPONENTS)/drivers_nrf/common/nrf_drv_common.c \
		$(COMPONENTS)/drivers_nrf/delay/nrf_delay.c \
		$(COMPONENTS)/drivers_nrf/pstorage/pstorage.c \
		$(COMPONENTS)/libraries/button/app_button.c \
		$(COMPONENTS)/libraries/timer/app_timer.c \
		$(COMPONENTS)/libraries/util/app_error.c \
		$(COMPONENTS)/libraries/util/nrf_assert.c \
		$(COMPONENTS)/softdevice/common/softdevice_handler/softdevice_handler.c \
		$(COMPONENTS)/toolchain/system_nrf52.c \
		$(SDK_PATH)/examples/bsp/bsp.c \
		src/nrf/simple_uart.c

CPP_SOURCE_FILES = $(wildcard \
		src/*.cpp \
		src/base/*.cpp \
		src/mesh/*.cpp \
		src/modules/*.cpp \
		src/test/*.cpp \
		src/utility/*.cpp \
		)

#assembly files common to all targets
ASM_SOURCE_FILES  = $(COMPONENTS)/toolchain/gcc/gcc_startup_nrf52.s

#includes common to all targets
INC_PATHS += -Iinc
INC_PATHS += -Iinc_c
INC_PATHS += -Iconfig
INC_PATHS += -I$(COMPONENTS)/ble/common
INC_PATHS += -I$(COMPONENTS)/ble/ble_radio_notification
INC_PATHS += -I$(COMPONENTS)/ble/ble_services/ble_dfu
INC_PATHS += -I$(COMPONENTS)/device
INC_PATHS += -I$(COMPONENTS)/drivers_nrf/common
INC_PATHS += -I$(COMPONENTS)/drivers_nrf/config
INC_PATHS += -I$(COMPONENTS)/drivers_nrf/delay
INC_PATHS += -I$(COMPONENTS)/drivers_nrf/gpiote
INC_PATHS += -I$(COMPONENTS)/drivers_nrf/hal
INC_PATHS += -I$(COMPONENTS)/drivers_nrf/pstorage
INC_PATHS += -I$(COMPONENTS)/libraries/button
INC_PATHS += -I$(COMPONENTS)/libraries/timer
INC_PATHS += -I$(COMPONENTS)/libraries/util
INC_PATHS += -I$(COMPONENTS)/softdevice/common/softdevice_handler
INC_PATHS += -I$(COMPONENTS)/softdevice/s132/headers
INC_PATHS += -I$(COMPONENTS)/softdevice/s132/headers/nrf52
INC_PATHS += -I$(COMPONENTS)/toolchain
INC_PATHS += -I$(COMPONENTS)/toolchain/gcc
INC_PATHS += -I$(SDK_PATH)/examples/bsp

OBJECT_DIRECTORY = _build
LISTING_DIRECTORY = $(OBJECT_DIRECTORY)
OUTPUT_BINARY_DIRECTORY = $(OBJECT_DIRECTORY)

# Sorting removes duplicates
BUILD_DIRECTORIES := $(sort $(OBJECT_DIRECTORY) $(OUTPUT_BINARY_DIRECTORY) $(LISTING_DIRECTORY) )

ifeq ($(BUILD_TYPE),debug)
  DEBUG_FLAGS += -D DEBUG -O0 -ggdb
else
  DEBUG_FLAGS += -D NDEBUG -O3
endif

LINKER_SCRIPT := linker/gcc_nrf52_s132.ld

#flags common to all targets
CFLAGS  = -DSWI_DISABLE0
CFLAGS += -DSOFTDEVICE_PRESENT
CFLAGS += -DNRF52
CFLAGS += -DBOARD_PCA10036
CFLAGS += -DCONFIG_GPIO_AS_PINRESET
CFLAGS += -DS132
CFLAGS += -DBLE_STACK_SUPPORT_REQD
CFLAGS += -DENABLE_LOGGING
CFLAGS += -DDEST_BOARD_ID=0
CFLAGS += -D__need___va_list
CFLAGS += -mcpu=cortex-m4
CFLAGS += -mthumb -mabi=aapcs
CFLAGS += $(DEBUG_FLAGS)
CFLAGS += -Wall -Werror
CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
# keep every function in separate section. This will allow linker to dump unused functions
CFLAGS += -ffunction-sections -fdata-sections -fno-strict-aliasing
CFLAGS += --short-enums

CXXFLAGS  = $(CFLAGS)
CXXFLAGS += -fabi-version=0
CXXFLAGS += -flto
CXXFLAGS += -fmessage-length=0
CXXFLAGS += -fno-exceptions
CXXFLAGS += -fno-rtti
CXXFLAGS += -fno-threadsafe-statics -fno-move-loop-invariants
CXXFLAGS += -fno-use-cxa-atexit
CXXFLAGS += -fsigned-char
CXXFLAGS += -w


# keep every function in separate section. This will allow linker to dump unused functions
LDFLAGS += -Xlinker -Map=$(LISTING_DIRECTORY)/$(OUTPUT_FILENAME).map
LDFLAGS += -mthumb -mabi=aapcs -Llinker/ -T$(LINKER_SCRIPT)
LDFLAGS += -mcpu=cortex-m4
LDFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDFLAGS += -Wl,--gc-sections
LDFLAGS += --specs=nano.specs
LDFLAGS += -fmessage-length=0
LDFLAGS += -fsigned-char
LDFLAGS += -ffunction-sections
LDFLAGS += -flto
LDFLAGS += -fno-move-loop-invariants

# Assembler flags
ASMFLAGS += -x assembler-with-cpp

LIBS += -lgcc -lc -lnosys

#building all targets
all: $(BUILD_DIRECTORIES) $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex echosize

#target for printing all targets
help:
	@echo following targets are available:
	@echo   all
	@echo 	flash
	@echo 	flash_softdevice
	@echo   serial


C_SOURCE_FILE_NAMES = $(notdir $(C_SOURCE_FILES))
C_PATHS = $(call remduplicates, $(dir $(C_SOURCE_FILES) ) )
C_OBJECTS = $(addprefix $(OBJECT_DIRECTORY)/, $(C_SOURCE_FILE_NAMES:.c=.o) )

CPP_SOURCE_FILE_NAMES = $(notdir $(CPP_SOURCE_FILES))
CPP_PATHS = $(call remduplicates, $(dir $(CPP_SOURCE_FILES) ) )
CPP_OBJECTS = $(addprefix $(OBJECT_DIRECTORY)/, $(CPP_SOURCE_FILE_NAMES:.cpp=.o) )

ASM_SOURCE_FILE_NAMES = $(notdir $(ASM_SOURCE_FILES))
ASM_PATHS = $(call remduplicates, $(dir $(ASM_SOURCE_FILES) ))
ASM_OBJECTS = $(addprefix $(OBJECT_DIRECTORY)/, $(ASM_SOURCE_FILE_NAMES:.s=.o) )

vpath %.c $(C_PATHS)
vpath %.cpp $(CPP_PATHS)
vpath %.s $(ASM_PATHS)

OBJECTS = $(C_OBJECTS) $(CPP_OBJECTS) $(ASM_OBJECTS)

## Create build directories
$(BUILD_DIRECTORIES):
	@echo Making $@
	$(NO_ECHO)$(MK) $@

# Create objects from C SRC files
$(OBJECT_DIRECTORY)/%.o: %.c
	@echo Compiling file: $(notdir $<)
	$(NO_ECHO)$(CC) --std=gnu99 $(CFLAGS) $(INC_PATHS) -c -o $@ $<

# Create objects from C SRC files
$(OBJECT_DIRECTORY)/%.o: %.cpp
	@echo Compiling file: $(notdir $<)
	$(NO_ECHO)$(CXX) --std=c++11 $(CXXFLAGS) $(INC_PATHS) -c -o $@ $<

# Assemble files
$(OBJECT_DIRECTORY)/%.o: %.s
	@echo Compiling file: $(notdir $<)
	$(NO_ECHO)$(CC) $(ASMFLAGS) $(INC_PATHS) -c -o $@ $<

# Link
$(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out: $(OBJECTS)
	@echo Linking target: $(OUTPUT_FILENAME).out
	$(NO_ECHO)$(CXX) $(LDFLAGS) $(OBJECTS) $(LIBS) -o $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out

## Create binary .hex file from the .out file
$(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex: $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	@echo Preparing: $(OUTPUT_FILENAME).hex
	$(NO_ECHO)$(OBJCOPY) -O ihex $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex

echosize: $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	-@echo ''
	$(NO_ECHO)$(SIZE) $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	-@echo ''

clean:
	$(NO_ECHO)$(RM) $(BUILD_DIRECTORIES)

cleanobj:
	$(NO_ECHO)$(RM) $(BUILD_DIRECTORIES)/*.o

flash: $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex
	@echo Flashing: $<
	$(NO_ECHO)$(NRFJPROG) --erasepage 0x1f000-0x80000 -f nrf52
	$(NO_ECHO)$(NRFJPROG) --program $< -f nrf52
	$(NO_ECHO)$(NRFJPROG) --reset -f nrf52

## Flash softdevice
flash_softdevice:
	@echo Flashing: s132_nrf52_1.0.0-3.alpha_softdevice.hex
	$(NO_ECHO)$(NRFJPROG) --erasepage 0x0-0x1f000 -f nrf52
	$(NO_ECHO)$(NRFJPROG) --program $(COMPONENTS)/softdevice/s132/hex/s132_nrf52_1.0.0-3.alpha_softdevice.hex -f nrf52
	$(NO_ECHO)$(NRFJPROG) --reset -f nrf52

serial:
	screen /dev/serial/by-id/usb-SEGGER_J-Link_*-if00 38400

.NOTPARALLEL: clean
.PHONY: flash flash_softdevice clean serial debug
