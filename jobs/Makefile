# $Id: Makefile 1176 2019-06-30 07:16:06Z mueller $
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright 2017-2018 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
#
JES_all  = $(wildcard hewo_*.JES)
JES_all += $(wildcard mcpi_*.JES)
JES_all += $(wildcard sine_*.JES)
JES_all += $(wildcard soep_*.JES)
JES_all += $(wildcard soeq_*.JES)
JES_all += $(wildcard towh_*.JES)
JCL_all  = $(JES_all:.JES=.jcl)
DEP_all  = $(JES_all:.JES=.dep)
#
JCL_extra = ltlib_new.jcl ltlib_del.jcl
#
all : $(JCL_all)
#
clean :
	rm -f $(JCL_all) $(JCL_extra)
#
ltlib_new.jcl : ltlib_new.JES ltlib_index.txt $(JCL_all)
#
# The magic auto-dependency include
#
include $(DEP_all)
#
# build pattern
#
%.jcl : %.JES
	hercjis -o $@ $<
%.dep : %.JES
	@ echo "hercjis -M ... $<"
	@ hercjis -M -o $@ $< | sed 's/\.dep/\.jcl/' > $@
