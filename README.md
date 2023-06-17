# LiftOver-Snakemake
Snakemake workflow for doing lift on map/ped files from GRCh37 to GRCh38. Should be readily adaptable to other lifts by substituting a new *.gz chain file and relevant file references.

This workflow was developed from the scripts for performing liftover on Plink files by sritchie73, located here: https://github.com/sritchie73/liftOverPlink

1. Put the original map/ped files in a folder called 'rawdata' in the same folder as the snakefile. It should produce lifted versions in a folder called 'lifteddata'.
2. 'module load anaconda'
3. 'source activate workflow' (see GWAS Snakemake, you can use the same environment)
4. 'snakemake --use-conda --conda-frontend-conda -c*' 
      (* = number of cores, eg. 2. --use-conda because one of the steps needs conda to build a temporary environment with Python2, --conda-frontend-conda               because I figure it's easier than trying to mess around with switching default to mamba)
