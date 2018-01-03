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
