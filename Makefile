REBAR := rebar3

QUICER_VERSION ?= $(shell git describe --tags --always)
export QUICER_VERSION

.PHONY: all
all: compile

.PHONY: default
default: build-nif

.PHONY: build-nif
build-nif:
	./build.sh 'v2.2.3'

compile:
	$(REBAR) compile

.PHONY: clean
clean: distclean


fmt:
	@clang-format-12 -i c_src/*
	@rebar3 fmt


.PHONY: distclean
distclean:
	$(REBAR) unlock --all
	rm -rf _build erl_crash.dump rebar3.crashdump
	rm -rf c_build/*
	rm -rf priv/*

.PHONY: xref
xref:
	$(REBAR) xref

.PHONY: eunit
eunit:
	$(REBAR) eunit -v -c --cover_export_name eunit 

.PHONY: proper
proper:
	$(REBAR) proper

.PHONY: proper-cover
proper-cover:
	QUICER_TEST_COVER=1 QUICER_USE_SNK=1 $(REBAR) as test proper
	lcov -c  --directory c_build/CMakeFiles/quicer_nif.dir/c_src/ \
	--exclude "${PWD}/msquic/src/inc/*" \
	--output-file ./coverage/proper-lcov.info

.PHONY: ct
ct:
	QUICER_USE_SNK=1 $(REBAR) as test ct -v --readable=true

.PHONY: cover
cover: eunit
	mkdir -p coverage
	QUICER_TEST_COVER=1 QUICER_USE_SNK=1 $(REBAR) as test ct --cover --cover_export_name=ct -v
	$(REBAR) as test cover -v
	lcov -c  --directory c_build/CMakeFiles/quicer_nif.dir/c_src/ \
	--exclude "${PWD}/msquic/src/inc/*" \
	--output-file ./coverage/lcov.info

.PHONY: cover-html
cover-html: cover proper-cover
	genhtml -o coverage/ coverage/lcov.info coverage/proper-lcov.info

.PHONY: dialyzer
dialyzer:
	$(REBAR) dialyzer

.PHONY: test
test: eunit ct

.PHONY: check
check: clang-format

.PHONY: clang-format
clang-format:
	clang-format-11 --Werror --dry-run c_src/*

.PHONY: ci
ci: test dialyzer

.PHONY: tar
tar:
	$(REBAR) tar

.PHONY: doc
doc:
	$(REBAR) as doc ex_doc

.PHONY: publish
publish:
	$(REBAR) as doc hex publish
