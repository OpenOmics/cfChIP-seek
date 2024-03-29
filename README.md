> [!WARNING]  
> This pipeline has been archived, and the project has moved to another location. Do not use this pipeline as it will not receive any future updates! **Please use our new cell-free ChIP-sequencing pipeline,  [`chrom-seek`](https://github.com/OpenOmics/chrom-seek).**

<div align="center">
   
  <h1>cfChIP-seek 🔬</h1>
  
  **_An Awesome cell-free ChIP-sequencing Pipeline_**

  [![tests](https://github.com/OpenOmics/cfChIP-seek/workflows/tests/badge.svg)](https://github.com/OpenOmics/cfChIP-seek/actions/workflows/main.yaml) [![docs](https://github.com/OpenOmics/cfChIP-seek/workflows/docs/badge.svg)](https://github.com/OpenOmics/cfChIP-seek/actions/workflows/docs.yml) [![GitHub issues](https://img.shields.io/github/issues/OpenOmics/cfChIP-seek?color=brightgreen)](https://github.com/OpenOmics/cfChIP-seek/issues)  [![GitHub license](https://img.shields.io/github/license/OpenOmics/cfChIP-seek)](https://github.com/OpenOmics/cfChIP-seek/blob/main/LICENSE) 
  
  <i>
    This is the home of the pipeline, cfChIP-seek. Its long-term goals: to accurately call and annotate peaks, to infer cell types, and to boldly quantify diferential binding like no pipeline before!
  </i>
</div>

## Overview
Welcome to cfChIP-seek! Before getting started, we highly recommend reading through [cfChIP-seek's documentation](https://openomics.github.io/cfChIP-seek/).

The **`./cfChIP-seek`** pipeline is composed several inter-related sub commands to setup and run the pipeline across different systems. Each of the available sub commands perform different functions: 

 * [<code>cfChIP-seek <b>run</b></code>](https://openomics.github.io/cfChIP-seek/usage/run/): Run the cfChIP-seek pipeline with your input files.
 * [<code>cfChIP-seek <b>unlock</b></code>](https://openomics.github.io/cfChIP-seek/usage/unlock/): Unlocks a previous runs output directory.
 * [<code>cfChIP-seek <b>cache</b></code>](https://openomics.github.io/cfChIP-seek/usage/cache/): Cache remote resources locally, coming soon!

**cfChIP-seek** is a comprehensive ...insert long description. It relies on technologies like [Singularity<sup>1</sup>](https://singularity.lbl.gov/) to maintain the highest-level of reproducibility. The pipeline consists of a series of data processing and quality-control steps orchestrated by [Snakemake<sup>2</sup>](https://snakemake.readthedocs.io/en/stable/), a flexible and scalable workflow management system, to submit jobs to a cluster.

The pipeline is compatible with data generated from Illumina short-read sequencing technologies. As input, it accepts a set of FastQ files and can be run locally on a compute instance or on-premise using a cluster. A user can define the method or mode of execution. The pipeline can submit jobs to a cluster using a job scheduler like SLURM (more coming soon!). A hybrid approach ensures the pipeline is accessible to all users.

Before getting started, we highly recommend reading through the [usage](https://openomics.github.io/cfChIP-seek/usage/run/) section of each available sub command.

For more information about issues or trouble-shooting a problem, please checkout our [FAQ](https://openomics.github.io/cfChIP-seek/faq/questions/) prior to [opening an issue on Github](https://github.com/OpenOmics/cfChIP-seek/issues).

## Dependencies
**Requires:** `singularity>=3.5`  `snakemake>=6.0`

At the current moment, the pipeline uses a mixture of enviroment modules and docker images; however, this will be changing soon! In the very near future, the pipeline will only use docker images. With that being said, [snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) and [singularity](https://singularity.lbl.gov/all-releases) must be installed on the target system. Snakemake orchestrates the execution of each step in the pipeline. To guarantee the highest level of reproducibility, each step of the pipeline will rely on versioned images from [DockerHub](https://hub.docker.com/orgs/nciccbr/repositories). Snakemake uses singularity to pull these images onto the local filesystem prior to job execution, and as so, snakemake and singularity will be the only two dependencies in the future.

## Installation
Please clone this repository to your local filesystem using the following command:
```bash
# Clone Repository from Github
git clone https://github.com/OpenOmics/cfChIP-seek.git
# Change your working directory
cd cfChIP-seek/
# Add dependencies to $PATH
# Biowulf users should run
module load snakemake singularity
# Get usage information
./cfChIP-seek -h
```

## Contribute 
This site is a living document, created for and by members like you. cfChIP-seek is maintained by the members of OpenOmics and is improved by continous feedback! We encourage you to contribute new content and make improvements to existing content via pull request to our [GitHub repository](https://github.com/OpenOmics/cfChIP-seek).

## References
<sup>**1.**  Kurtzer GM, Sochat V, Bauer MW (2017). Singularity: Scientific containers for mobility of compute. PLoS ONE 12(5): e0177459.</sup>  
<sup>**2.**  Koster, J. and S. Rahmann (2018). "Snakemake-a scalable bioinformatics workflow engine." Bioinformatics 34(20): 3600.</sup>  
