#
JES_all = $(wildcard *.JES)
JCL_all = $(JES_all:.JES=.jcl)
DEP_all = $(JES_all:.JES=.dep)
#
all : $(JCL_all)
#
clean :
	rm -f $(JCL_all)
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
