GHDL := ghdl
WORKDIR := work
VERSION := 08

# PACKAGES := src/types.vhd
TARGETS :=
TARGETS += $(wildcard *.vhd)
TARGETS += $(wildcard tests/*.vhd)

DEBUG  := 1
VISUAL := 1

GHDLFLAGS := --std=$(VERSION) --workdir=$(WORKDIR)

ifeq ($(DEBUG), 1)
GHDLFLAGS += -v
endif

analyse: | $(WORKDIR)
	$(GHDL) -i $(GHDLFLAGS) $(PACKAGES) $(TARGETS)
	# $(GHDL) -a $(GHDLFLAGS) $(PACKAGES)
	$(GHDL) -a $(GHDLFLAGS) $(TARGETS)

memory_test: | $(WORKDIR)
	$(GHDL) -e $(GHDLFLAGS) main_memory_tb
	$(GHDL) -r $(GHDLFLAGS) main_memory_tb --wave=$(WORKDIR)/$@.ghw
ifeq ($(VISUAL), 1)
	gtkwave $(WORKDIR)/$@.ghw
endif

instruction_cache_test:
	$(GHDL) -e $(GHDLFLAGS) instruction_cache_tb
	$(GHDL) -r $(GHDLFLAGS) instruction_cache_tb --wave=$(WORKDIR)/$@.ghw
ifeq ($(VISUAL), 1)
	gtkwave $(WORKDIR)/$@.ghw
endif

instruction_cache_test_fast:
	$(GHDL) -e $(GHDLFLAGS) instruction_cache_tb
	$(GHDL) -r $(GHDLFLAGS) instruction_cache_tb --wave=$(WORKDIR)/$@.vcd
ifeq ($(VISUAL), 1)
	gtkwave $(WORKDIR)/$@.vcd
endif

buffer_test:
	$(GHDL) -e $(GHDLFLAGS) write_buffer_tb
	$(GHDL) -r $(GHDLFLAGS) write_buffer_tb --wave=$(WORKDIR)/$@.ghw
ifeq ($(VISUAL), 1)
	gtkwave $(WORKDIR)/$@.ghw
endif

full_test:
	$(GHDL) -r $(GHDLFLAGS) full_tb --stop-time=8us --vcd=$(WORKDIR)/$@.vcd
ifeq ($(VISUAL), 1)
	gtkwave $(WORKDIR)/$@.vcd
endif

check_syntax: | $(WORKDIR)
	$(GHDL) -s $(GHDLFLAGS) $(PACKAGES) $(TARGETS)

clean:
	rm -rf $(WORKDIR)

$(WORKDIR):
	mkdir -p $(WORKDIR)

.PHONY: all analyse check_syntax clean

# end
