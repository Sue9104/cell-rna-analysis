SHELL = /bin/bash
RLIB = $(HOME)/miniconda3/envs/seq3/lib/R/library
CRAN = https://mirrors.ustc.edu.cn/CRAN/
ENV = $(shell echo $${SHELL##*/})
PATH = $(shell pwd)

sqanti3:
	sed -i 's|SQANTI3.env|seq3|' install/SQANTI3.conda_env.yaml
	mamba env create -f install/SQANTI3.conda_env.yaml
	mamba activate seq3 && cd cDNA_Cupcake && python setup.py install

tappas:
	mamba env create -f install/tappas.conda_env.yaml
	mamba activate tappas && R --vanilla -e 'source("$(PATH)/install/tappAS_packages.R")'

environment:
	@echo add following to the shell environment
	@/usr/bin/mkdir -p $(HOME)/.$(ENV).after
	echo "export PYTHONPATH=\$$PYTHONPATH:$(PATH)/cDNA_Cupcake/sequence/:$(PATH)/cDNA_Cupcake/" > $(HOME)/.$(ENV).after/seq3.zsh
	echo "alias tappas='$(PATH)/jre1.8.0_251/bin/java -jar $(PATH)/tappAS.jar'" >> $(HOME)/.$(ENV).after/seq3.zsh

install:
	mamba env create -f install/seq3.conda_env.yaml
	mamba activate seq3 && R --vanilla -e 'source("$(PATH)/install/tappAS_packages.R")'
	mamba activate seq3 && cd $(PATH)/cDNA_Cupcake && python setup.py install

all: install environment
