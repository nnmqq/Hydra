# Binary name
TARGET := Hydra

# Some settings
          CXX = clang++
      WIN_CXX = ~/llvm-mingw/llvm/bin/x86_64-w64-mingw32-clang++
      SRC_EXT = cpp
   MODULE_EXT = cppm
     SRC_PATH = src
  INCLUDE_DIR = -Iinclude -Ivendor/raylib/include -Ivendor/raylibwin/include
MACRO_OPTIONS = -D NMQ -D NNMQQ

# Build paths
BUILD_PATH_DEBUG   := build/debug
BUILD_PATH_RELEASE := build/release
BUILD_PATH_WINDOWS := build/windows
BIN_PATH_DEBUG     := bin/debug
BIN_PATH_RELEASE   := bin/release
BIN_PATH_WINDOWS   := bin/windows
BUILD_TYPE         ?= release

### COMPILER ###
# General compiler flags
COMPILE_FLAGS  = -std=c++2c -stdlib=libc++ -Wall -Wextra
# Additional release-specific flag
RCOMPILE_FLAGS = -O2 -D RELEASE
# Additional debug-specific flags
DCOMPILE_FLAGS = -g -D DEBUG
# Platform Flags
WCOMPILE_FLAGS = -D WINDOWS
LCOMPILE_FLAGS = -D LINUX
################

### LINKER ###
# General linker settings
LINK_FLAGS  = -fuse-ld=lld
# Additional release-specific linker settings
RLINK_FLAGS = -Wl,--as-needed
# Additional debug-specific linker settings
DLINK_FLAGS = -Wl,-Map=$(BIN_PATH_DEBUG)/$(TARGET).map
# Linux-specific linker settings
LINUX_LINK_FLAGS = -Lvendor/raylib/lib -lraylib
# Windows-specific linker settings
WIN_LINK_FLAGS = -Lvendor/raylibwin/lib -lraylib -lgdi32 -luser32 -lwinmm
################

# Determine Compilation and Linker Flags based on Build Type
ifeq ($(BUILD_TYPE),debug)
  CXXFLAGS   := $(COMPILE_FLAGS) $(DCOMPILE_FLAGS) $(MACRO_OPTIONS) $(LCOMPILE_FLAGS)
  LDFLAGS    := $(LINK_FLAGS) $(DLINK_FLAGS) $(LINUX_LINK_FLAGS)
  CXX        := $(CXX)
  BUILD_PATH := $(BUILD_PATH_DEBUG)
  BIN_PATH   := $(BIN_PATH_DEBUG)
else ifeq ($(BUILD_TYPE),windows)
  CXXFLAGS   := $(COMPILE_FLAGS) $(WCOMPILE_FLAGS) $(MACRO_OPTIONS)
  LDFLAGS    := $(LINK_FLAGS) $(WIN_LINK_FLAGS)
  CXX        := $(WIN_CXX)
  BUILD_PATH := $(BUILD_PATH_WINDOWS)
  BIN_PATH   := $(BIN_PATH_WINDOWS)
else
  CXXFLAGS   := $(COMPILE_FLAGS) $(RCOMPILE_FLAGS) $(MACRO_OPTIONS)
  LDFLAGS    := $(LINK_FLAGS) $(RLINK_FLAGS) $(LINUX_LINK_FLAGS)
  CXX        := $(CXX)
  BUILD_PATH := $(BUILD_PATH_RELEASE)
  BIN_PATH   := $(BIN_PATH_RELEASE)
endif

# Source and Object Files
SOURCE_FILES := $(wildcard $(SRC_PATH)/*.$(SRC_EXT)) $(wildcard $(SRC_PATH)/*.$(MODULE_EXT))
OBJECTS := $(SOURCE_FILES:$(SRC_PATH)/%.$(SRC_EXT)=$(BUILD_PATH)/%.o)
DEPS    := $(OBJECTS:.o=.d)

# Default Target
.PHONY: all
all: dirs $(BIN_PATH)/$(TARGET)

# Build and output paths
.PHONY: dirs
dirs:
	@mkdir -p $(BUILD_PATH) $(BIN_PATH)

# Compile module interface files
$(BUILD_PATH)/%.o: $(SRC_PATH)/%.$(MODULE_EXT)
	@echo "Compiling module interface: $< -> $@"
	@$(CXX) $(CXXFLAGS) -I $(INCLUDE_DIR) -fmodules-ts -c $< -o $@
	@echo "Compiled module interface $< into $@"

# Compile source files
$(BUILD_PATH)/%.o: $(SRC_PATH)/%.$(SRC_EXT)
	@echo "Compiling source file: $< -> $@"
	@$(CXX) $(CXXFLAGS) -I $(INCLUDE_DIR) -MP -MMD -c $< -o $@
	@echo "Compiled $< into $@"

# Link the executable
$(BIN_PATH)/$(TARGET): $(OBJECTS)
	@echo "Linking: $@"
	@$(CXX) $(OBJECTS) $(LDFLAGS) -o $@
	@echo "Linked $(OBJECTS) into $@"

# Clean up build files
.PHONY: clean
clean:
	@echo "Cleaning build files"
	@rm -rf $(BUILD_PATH_DEBUG) $(BUILD_PATH_RELEASE) $(BUILD_PATH_WINDOWS) $(BIN_PATH_DEBUG) $(BIN_PATH_RELEASE) $(BIN_PATH_WINDOWS)
	@echo "Removed build and bin directories"

# Build with Debug Flags
.PHONY: debug
debug:
	@$(MAKE) BUILD_TYPE=debug all
	@echo "Build complete in debug mode"

# Build with Release Flags
.PHONY: release
release:
	@$(MAKE) BUILD_TYPE=release all
	@echo "Build complete in release mode"

# Build Windows
.PHONY: windows
windows:
	@$(MAKE) BUILD_TYPE=windows all
	@echo "Build complete for Windows using raylibwin"

# Run the executable
.PHONY: run
run: all
	@echo "Running $(BIN_PATH)/$(TARGET)"
	@$(BIN_PATH)/$(TARGET)

# Run with gdb
.PHONY: gdb
gdb:
	@$(MAKE) BUILD_TYPE=debug all
	@echo "Running gdb on $(BIN_PATH_DEBUG)/$(TARGET)"
	@gdb $(BIN_PATH_DEBUG)/$(TARGET)

# Include deps
-include $(DEPS)
