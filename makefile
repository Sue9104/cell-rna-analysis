SHELL = /bin/bash
RLIB = $(HOME)/miniconda3/envs/seq3/lib/R/library
CRAN = https://mirrors.ustc.edu.cn/CRAN/
ENV = $(shell echo $${SHELL##*/})
PATH = $(shell pwd)
.PHONY: install

tappas:
	echo "please run the following in the terminal!!!\n"
	$(HOME)/miniconda3/bin/mamba env create -f install/tappas.conda_env.yaml
	$(HOME)/miniconda3/bin/mamba activate tappas && R --vanilla -e 'source("$(PATH)/install/tappAS_packages.R")'

environment:
	@echo add following to the shell environment
	@/usr/bin/mkdir -p $(HOME)/.$(ENV).after
	echo "export PYTHONPATH=\$$PYTHONPATH:$(PATH)/cDNA_Cupcake/sequence/:$(PATH)/cDNA_Cupcake/" > $(HOME)/.$(ENV).after/seq3.zsh
	echo "alias tappas='$(PATH)/jre1.8.0_251/bin/java -jar $(PATH)/tappAS.jar'" >> $(HOME)/.$(ENV).after/seq3.zsh

seq3:
	@echo -e "please run the following in the terminal!!!\n"
	@echo "$(HOME)/miniconda3/bin/mamba env create -f install/seq3.conda_env.yaml"

install:
	@echo -e "please run the following in the seq3 conda environment!!!\n"
	@echo $(HOME)/miniconda3/envs/seq3/bin/Rscript --vanilla -e \"source\(\'$(PATH)/install/tappAS_packages.R\'\)\"
	@echo "cd $(PATH)/cDNA_Cupcake && $(HOME)/miniconda3/envs/seq3/bin/python setup.py install"

isoseq3:
	@echo -e "please run the following in the terminal!!!\n"
	@echo "$(HOME)/miniconda3/bin/mamba create -n pacbio python==2.7.13 --force"
	@echo "$(HOME)/miniconda3/bin/mamba activate pacbio && $(HOME)/miniconda3/bin/mamba install -c bioconda -y isoseq3"

