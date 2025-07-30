# Freesurfer-Flow

Run the FastSurfer recon-all pipeline and generate customized FreeSurfer, Brainnetome, and Glasser connectivity atlases in native space.

## Citation

If you use this pipeline, please cite the following works:

- **FastSurfer**:  
    Henschel, Leonie, et al. "Fastsurfer-a fast and accurate deep learning-based neuroimaging pipeline." *NeuroImage* 219 (2020).  
    [https://doi.org/10.1016/j.neuroimage.2020.117012](https://doi.org/10.1016/j.neuroimage.2020.117012)

- **FreeSurfer**:  
    Fischl, Bruce. "FreeSurfer." *NeuroImage* 62.2 (2012).  
    [https://dx.doi.org/10.1016%2Fj.neuroimage.2012.01.021](https://dx.doi.org/10.1016%2Fj.neuroimage.2012.01.021)

- **Singularity**:  
    Kurtzer GM, Sochat V, Bauer MW. "Singularity: Scientific containers for mobility of compute." *PLoS ONE* 12(5): e0177459 (2017).  
    [https://doi.org/10.1371/journal.pone.0177459](https://doi.org/10.1371/journal.pone.0177459)

- **Nextflow**:  
    P. Di Tommaso, et al. "Nextflow enables reproducible computational workflows." *Nature Biotechnology* 35, 316–319 (2017).  
    [https://doi.org/10.1038/nbt.3820](https://doi.org/10.1038/nbt.3820)

## Containerized Execution

### Docker
To run with Docker, use the Docker profile:  
`-profile docker`

### Singularity
To run with Singularity, use the Singularity profile:  
`-profile singularity`

### Apptainer
To run with Apptainer, use the Apptainer profile:  
`-profile apptainer`

## GPU Support

To enable GPU acceleration for the FastSurfer module, use the GPU profile. For example, with Docker:  
`-profile docker,use_gpu`

## Usage

Refer to the **USAGE** section or run the following command for detailed help:  
`nextflow run main.nf --help`
