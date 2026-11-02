# Reconstructed build for sacd_extract_160 (Sony Mediatek BDP SACD server)
#
# Era-correct toolchain: GCC 4.4.1 / glibc 2.9 ARM soft-float
# (CodeSourcery Sourcery G++ Lite 2009q3-67, arm-none-linux-gnueabi —
#  the public twin of the MTK gnuarm-4.4.1 toolchain the original used).
#
# The original was compiled at -O0 (frame pointers everywhere, -O0-style
# stack spills — verified by instruction-level calibration).
#
# Usage (see ../../BUILD.md):
#   make CROSS=/path/to/arm-none-linux-gnueabi-

CROSS   ?= /tc/arm-2009q3/bin/arm-none-linux-gnueabi-
CC      := $(CROSS)gcc
LD      := $(CROSS)gcc
OBJCOPY_LD := $(CROSS)ld

CFLAGS  := -O0 -marm -march=armv6z -Wall -fno-unwind-tables -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE \
           -Itool -Ilibsacd -Ilibcommon -Ilibcommon/sys -Ilibid3 -Ilibdstdec \
           -DLIBSACD_INTERNAL
LDFLAGS := -lpthread

BUILD   := build
TARGET  := sacd_extract_160

# The original was built from a tree rooted at /root/sacd-ripper (its __FILE__
# strings in assert-failure paths embed that prefix). Compile lib* sources
# through that root so __FILE__ matches byte-for-byte. tool/ files never
# materialize __FILE__. Set BUILDROOT=. to build without the prefix.
BUILDROOT ?= /root/sacd-ripper/libs

SACD_SRCS := \
	libsacd/sacd_reader.c \
	libsacd/sacd_input.c \
	libsacd/sacd_read.c \
	libsacd/scarletbook.c \
	libsacd/scarletbook_read.c \
	libsacd/scarletbook_print.c \
	libsacd/scarletbook_output.c \
	libsacd/scarletbook_helpers.c \
	libsacd/scarletbook_id3.c \
	libsacd/sacd_pb_stream.c \
	libsacd/sacd_ripper.pb.c \
	libsacd/cuesheet.c \
	libsacd/dsf.c \
	libsacd/dsdiff.c \
	libsacd/iso_writer.c

COMMON_SRCS := \
	libcommon/charset.c \
	libcommon/pb_decode.c \
	libcommon/timeout.c \
	libcommon/fileutils.c \
	libcommon/pb_encode.c \
	libcommon/usocket.c \
	libcommon/socket.c \
	libcommon/utils.c \
	libcommon/log.c \
	libcommon/logging.c

DSTDEC_SRCS := \
	libdstdec/yarn.c \
	libdstdec/buffer_pool.c \
	libdstdec/ccp_calc.c \
	libdstdec/dst_ac.c \
	libdstdec/dst_data.c \
	libdstdec/dst_decoder.c \
	libdstdec/dst_fram.c \
	libdstdec/dst_init.c \
	libdstdec/unpack_dst.c

ID3_SRCS := \
	libid3/id3.c \
	libid3/id3_frame.c \
	libid3/id3_frame_content.c \
	libid3/id3_frame_text.c \
	libid3/id3_frame_url.c \
	libid3/id3_tag.c \
	libid3/unicode.c

TOOL_SRCS := \
	tool/main.c \
	tool/install.c \
	tool/getopt.c \
	tool/getopt1.c

SRCS := $(TOOL_SRCS) $(SACD_SRCS) $(COMMON_SRCS) $(DSTDEC_SRCS) $(ID3_SRCS)
OBJS := $(patsubst %.c,$(BUILD)/%.o,$(SRCS))

all: $(TARGET)

# embedded kernel module: `ld -b binary` yields _binary_sacd_read_ko_start/_end/_size
$(BUILD)/sacd_read_ko.o: sacd_read.ko
	@mkdir -p $(dir $@)
	$(OBJCOPY_LD) -r -b binary -o $@ $<

# FSF gcc-4.4.1 libgcc pieces that differ from the CodeSourcery 2009q3 build
# (proven by byte-identical reproduction of the original binary's libgcc
# routines from vanilla FSF gcc-4.4.1 config/arm assembly).
FSFLIBGCC_OBJS := \
	fsflibgcc/f_L_arm_cmpdf2.o \
	fsflibgcc/f_L_arm_cmpsf2.o \
	fsflibgcc/f_L_arm_unorddf2.o \
	fsflibgcc/f_L_arm_unordsf2.o \
	fsflibgcc/f_L_divsi3.o \
	fsflibgcc/f_L_udivsi3.o \
	fsflibgcc/f_L_aeabi_ldivmod.o \
	fsflibgcc/f_L_aeabi_uldivmod.o \
	fsflibgcc/f_L_aeabi_lcmp.o \
	fsflibgcc/f_L_aeabi_ulcmp.o \
	fsflibgcc/f_L_dvmd_lnx.o \
	fsflibgcc/f_L_call_via_rX.o \
	fsflibgcc/f_bpabi_c.o

$(TARGET): $(OBJS) $(BUILD)/sacd_read_ko.o $(FSFLIBGCC_OBJS)
	$(LD) $(LDFLAGS) -export-dynamic -o $@ $(FSFLIBGCC_OBJS) $(OBJS) $(BUILD)/sacd_read_ko.o

$(BUILD)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c -o $@ $(if $(filter lib%,$<),$(BUILDROOT)/$<,$<)

clean:
	rm -rf $(BUILD) $(TARGET)

.PHONY: all clean

# Release pipeline (issues #3/#4): build one ELF from tracked sources
# (direct compilation of tool/install.c + tool/main.c, #line staging for the
# four __FILE__ TUs, GNU crtbegin + glibc-2.9 wrappers from source, pinned
# CodeSourcery libgcc_s.so.1) and run every check against that exact file.
# Host prerequisites are documented in tools/release_build.py.
verify:
	../tools/release_verify.sh

.PHONY: verify
