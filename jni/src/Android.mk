# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH:=$(call my-dir)

# Project directory relative to this file.
SPLAT_DIR:=$(realpath $(LOCAL_PATH)/../..)
include $(SPLAT_DIR)/jni/android_config.mk

# relative to project root

# The following block generates build rules which result in headers being
# rebuilt from flatbuffers schemas.

# Directory that contains the FlatBuffers compiler.
FLATBUFFERS_FLATC_PATH?=$(realpath $(SPLAT_DIR)/bin)

# Location of FlatBuffers compiler.
FLATC?=$(realpath $(firstword \
            $(wildcard $(FLATBUFFERS_FLATC_PATH)/flatc*) \
            $(wildcard $(FLATBUFFERS_FLATC_PATH)/Release/flatc*) \
            $(wildcard $(FLATBUFFERS_FLATC_PATH)/Debug/flatc*)))
ifeq (,$(wildcard $(FLATC)))
$(error flatc binary not found!)
endif

# Generated includes directory (relative to SPLAT_DIR).
GENERATED_INCLUDES_PATH := gen/include/$(TARGET_ARCH_ABI)
# Flatbuffers schemas used to generate includes.
FLATBUFFERS_SCHEMAS := $(wildcard $(SPLAT_DIR)/src/flatbufferschemas/*.fbs)

# Convert the specified fbs path to a Flatbuffers generated header path.
# For example: src/flatbuffers/schemas/config.fbs will be converted to
# gen/include/config.h.
define flatbuffers_fbs_to_h
$(subst src/flatbufferschemas,$(GENERATED_INCLUDES_PATH),\
	$(patsubst %.fbs,%_generated.h,$(1)))
endef

# Generate a build rule that will convert a Flatbuffers schema to a generated
# header derived from the schema filename using flatbuffers_fbs_to_h.
define flatbuffers_header_build_rule
$(eval \
  $(call flatbuffers_fbs_to_h,$(1)): $(1)
	$(call host-echo-build-step,generic,Generate) \
		$(subst $(SPLAT_DIR)/,,$(call flatbuffers_fbs_to_h,$(1)))
	$(hide) $(FLATC) --gen-includes -o $$(dir $$@) -c $$<)
endef

# Create the list of generated headers.
GENERATED_INCLUDES := \
	$(foreach schema,$(FLATBUFFERS_SCHEMAS),\
		$(call flatbuffers_fbs_to_h,$(schema)))

# Generate a build rule for each header.
$(foreach schema,$(FLATBUFFERS_SCHEMAS),\
	$(call flatbuffers_header_build_rule,$(schema)))
.PHONY: generated_includes
generated_includes: $(GENERATED_INCLUDES)

# Build rule which builds assets for the game.
.PHONY: build_assets_$(TARGET_ARCH_ABI)
build_assets_$(TARGET_ARCH_ABI):
	python $(SPLAT_DIR)/scripts/build_assets.py


include $(CLEAR_VARS)

LOCAL_MODULE := main

LOCAL_C_INCLUDES := $(DEPENDENCIES_SDL_DIR)/include \
                    $(DEPENDENCIES_SDL_MIXER_DIR) \
                    $(DEPENDENCIES_FLATBUFFERS_DIR)/include \
                    $(DEPENDENCIES_GPG_DIR)/include \
                    $(DEPENDENCIES_WEBP_DIR)/src \
                    $(GENERATED_INCLUDES_PATH) \
                    src

LOCAL_SRC_FILES := \
  $(DEPENDENCIES_SDL_DIR)/src/main/android/SDL_android_main.c \
  $(SPLAT_DIR)/src/ai_controller.cpp \
  $(SPLAT_DIR)/src/async_loader.cpp \
  $(SPLAT_DIR)/src/audio_engine.cpp \
  $(SPLAT_DIR)/src/character.cpp \
  $(SPLAT_DIR)/src/character_state_machine.cpp \
  $(SPLAT_DIR)/src/controller.cpp \
  $(SPLAT_DIR)/src/full_screen_fader.cpp \
  $(SPLAT_DIR)/src/gamepad_controller.cpp \
  $(SPLAT_DIR)/src/game_camera.cpp \
  $(SPLAT_DIR)/src/game_state.cpp \
  $(SPLAT_DIR)/src/gpg_manager.cpp \
  $(SPLAT_DIR)/src/impel_engine.cpp \
  $(SPLAT_DIR)/src/impel_flatbuffers.cpp \
  $(SPLAT_DIR)/src/impel_processor_overshoot.cpp \
  $(SPLAT_DIR)/src/impel_processor_smooth.cpp \
  $(SPLAT_DIR)/src/input.cpp \
  $(SPLAT_DIR)/src/main.cpp \
  $(SPLAT_DIR)/src/material.cpp \
  $(SPLAT_DIR)/src/material_manager.cpp \
  $(SPLAT_DIR)/src/mesh.cpp \
  $(SPLAT_DIR)/src/player_controller.cpp \
  $(SPLAT_DIR)/src/particles.cpp \
  $(SPLAT_DIR)/src/precompiled.cpp \
  $(SPLAT_DIR)/src/renderer.cpp \
  $(SPLAT_DIR)/src/shader.cpp \
  $(SPLAT_DIR)/src/sound.cpp \
  $(SPLAT_DIR)/src/sound_collection.cpp \
  $(SPLAT_DIR)/src/splat_game.cpp \
  $(SPLAT_DIR)/src/touchscreen_button.cpp \
  $(SPLAT_DIR)/src/touchscreen_controller.cpp \
  $(SPLAT_DIR)/src/utilities.cpp

# Make each source file dependent upon the generated_includes and build_assets
# targets.
$(foreach src,$(LOCAL_SRC_FILES),$(eval $$(src): generated_includes))
$(foreach src,$(LOCAL_SRC_FILES),$(eval $$(src): \
                                       build_assets_$(TARGET_ARCH_ABI)))

LOCAL_STATIC_LIBRARIES := libgpg libmathfu libwebp SDL2 SDL2_mixer

LOCAL_SHARED_LIBRARIES :=

LOCAL_LDLIBS := -lGLESv1_CM -lGLESv2 -llog -lz

include $(BUILD_SHARED_LIBRARY)

$(call import-add-path,$(abspath $(DEPENDENCIES_MATHFU_DIR)/..))
$(call import-add-path,$(abspath $(DEPENDENCIES_WEBP_DIR)/..))

$(call import-module,mathfu/jni)
$(call import-module,webp)

