
# Copyright (c) 2015-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the CC-by-NC license found in the
# LICENSE file in the root directory of this source tree.

.SUFFIXES: .cpp .o


MAKEFILE_INC=makefile.inc

-include $(MAKEFILE_INC)

LIBNAME=libfaiss

all: .env_ok $(LIBNAME).a tests/demo_ivfpq_indexing objects

py: _swigfaiss.so



#############################
# Various
objects:
	mkdir -p objects

LIBOBJ=hamming.o  utils.o \
       IndexFlat.o IndexIVF.o IndexLSH.o IndexPQ.o  \
       IndexIVFPQ.o   \
       Clustering.o Heap.o VectorTransform.o index_io.o \
       PolysemousTraining.o MetaIndexes.o Index.o \
       ProductQuantizer.o AutoTune.o AuxIndexStructures.o

LIBOBJ := $(addprefix objects/, $(LIBOBJ))
INCLUDE := ./include
$(LIBNAME).a: $(LIBOBJ)
	ar r $(LIBNAME).a $^

$(LIBNAME).$(SHAREDEXT): $(LIBOBJ)
	$(CC) $(LDFLAGS) $(FAISSSHAREDFLAGS) -o $(LIBNAME).$(SHAREDEXT) $^ $(BLASLDFLAGS)

.cpp.o:
	$(CC) $(CFLAGS) -c $< -o $@ $(FLAGS) $(EXTRAFLAGS)

objects/utils.o:             EXTRAFLAGS=$(BLASCFLAGS)
objects/VectorTransform.o:   EXTRAFLAGS=$(BLASCFLAGS)
objects/ProductQuantizer.o:  EXTRAFLAGS=$(BLASCFLAGS)

# for MKL, the flags when generating a dynamic lib are different from
# the ones when making an executable, but by default they are the same

BLASLDFLAGSSO ?= $(BLASLDFLAGS)


#############################
# pure C++ test in the test directory

tests/test_blas: tests/test_blas.cpp
	$(CC) $(CFLAGS) $< -o $@ $(BLASLDFLAGS) $(BLASCFLAGS)

tests/demo_ivfpq_indexing: tests/demo_ivfpq_indexing.cpp $(LIBNAME).a
	$(CC) -o $@ $(CFLAGS) -I$(INCLUDE)  $< $(LIBNAME).a $(LDFLAGS) $(BLASLDFLAGS)

tests/demo_sift1M: tests/demo_sift1M.cpp $(LIBNAME).a
	$(CC) -o $@ $(CFLAGS) $< $(LIBNAME).a $(LDFLAGS) $(BLASLDFLAGS)


#############################
# SWIG interfaces

HFILES = IndexFlat.h Index.h IndexLSH.h IndexPQ.h IndexIVF.h \
    IndexIVFPQ.h VectorTransform.h index_io.h utils.h \
    PolysemousTraining.h Heap.h MetaIndexes.h AuxIndexStructures.h \
    Clustering.h hamming.h AutoTune.h

# also silently generates python/swigfaiss.py
python/swigfaiss_wrap.cxx: swigfaiss.swig $(INCLUDE)/$(HFILES)
	$(SWIGEXEC) -python -c++ -Doverride= -o $@ $<


# extension is .so even on the mac
python/_swigfaiss.so: python/swigfaiss_wrap.cxx $(LIBNAME).a
	$(CC) -I. $(CFLAGS) $(LDFLAGS) $(PYTHONCFLAGS) $(SHAREDFLAGS) \
	-o $@ $^ $(BLASLDFLAGSSO)

_swigfaiss.so: python/_swigfaiss.so
	cp python/_swigfaiss.so python/swigfaiss.py .

# Dependencies

objects/%.o: src/%.cpp
	$(CC) $(CFLAGS) $(BLASCFLAGS) -o $@ -I ./include -c $< 

clean:
	rm -f $(LIBNAME).a $(LIBNAME).$(SHAREDEXT)* objects/*.o \
	   	lua/swigfaiss.so lua/swigfaiss_wrap.cxx \
		python/_swigfaiss.so python/swigfaiss_wrap.cxx \
		python/swigfaiss.py _swigfaiss.so swigfaiss.py
	
.env_ok:
ifeq ($(wildcard $(MAKEFILE_INC)),)
	$(error Cannot find $(MAKEFILE_INC). Did you forget to copy the relevant file from ./example_makefiles?)
endif
ifeq ($(shell command -v $(CC) 2>/dev/null),)
	$(error Cannot find $(CC), please refer to $(CURDIR)/makefile.inc to set up your environment)
endif

.swig_ok: .env_ok
ifeq ($(shell command -v $(SWIGEXEC) 2>/dev/null),)
	$(error Cannot find $(SWIGEXEC), please refer to $(CURDIR)/makefile.inc to set up your environment)
endif
