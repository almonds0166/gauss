# Overview

In Summer 2017 thru Fall 2018, I used UV-Vis spectroscopy to investigate the bonding behavior of telechelic metal-coordinating polymers in hydrogels under various chemical stimuli such as pH and oxidants. I did this by fitting the spectral data to a gaussian peak superposition model. This repository contains the MATLAB scripts I've used to do this.

# Functions

Most of the files are well-documented in the sense that you may type, e.g. `help gauss`, to see the documentation in MATLAB's command window. Additionally, the files are briefly described below as well as a bit in [this presentation](https://drive.google.com/file/d/1istZ8gzPNU0de1oDi6_1fh67RGW8jslc/view?usp=sharing). Nevertheless, if something is unclear, feel free to reach out to me.

## Research-specific functions

### `CSV2MATRIX` and `UVVIS`

Both `CSV2MATRIX` and `UVVIS` convert a `.csv` file from the [DeNovix UV-Vis spectrophotometer](https://www.denovix.com/ds-11-fx-spectrophotometer-fluorometer/) into a matrix. The former is an earlier and bulkier version of the latter, added for completeness. The matrix returned is used in several of the functions here including `SPEC`, `GAUSS`, and `DECOMP`.

### `SPEC`

`SPEC` simply plots spectrograms from the data matrix returned by `UVVIS` into a figure like the one below:

![Snazzy spectra plot](https://i.imgur.com/bDfdTHU.png)
Given an output from `GAUSS`, `SPEC` can also make [a nice `.gif` slideshow](https://i.imgur.com/WMU4CB8.gifv).

If you have a list of values that correspond to each spectrograph (for my research, this would be pH values), you can use `REDBLUE` and `COP` to make color matrices ready for use by `SPEC`.

### `MONTE`

Using a Monte Carlo method, suggests a guess matrix `Gi` to be used with `GAUSS`.

### `GAUSS`

The MATLAB function I called `GAUSS` takes in a matrix `M` of experimental data whose size is (*the number of measurements in* `M`)+1 rows by (*the number of wavelengths in* `M`) columns. The +1 is for the top row, which lists all the wavelengths, usually 220 thru 750 (nm). `GAUSS` also takes in a matrix `Gi`, the guess matrix, which is (*the number of peaks used in your model*) by 2. The first column of `Gi` represents positions and the second represents the widths (specifically FWHMs) for each peak in your model.

`GAUSS` takes `M` and `Gi`, and iterates to find a better match of the model to the data. The iteration is from a gradient descent strategy for trying to fit the peak positions. And at each iteration, it uses a non-negative least squares algorithm to calculate the best-fit peak heights and widths. After it's finished, `GAUSS` returns a structure `W` with several useful fields, such as an updated guess matrix `G` and a matrix `H` containing the best-fit heights of the peaks at each measurements. This `H` is used for `HPH` below.

### `DECOMP`

An interactive version of `GAUSS`. `DECOMP` uses human input *via* keyboard to guide the fitting. In the first mode, you can change the current measurement you're looking at and update the guess matrix by one iteration. In the second mode, you can move around the peaks individually.

#### Keys for first mode

Key | Action
--- | ---
**Left** and **Right** | Browse through the measurements
`I` | Update the fit by one iteration
`W` | Update only the widths and heights
`X` | Update only the positions and heights
`Z` | Undo the last fitting action
`G` | Print the current guess matrix to the command window
`Q` | Reset the shift-cutting factor to its initial value
`1` thru `9` | Select a peak (changes to second mode)

#### Keys for second mode

Key | Action
--- | ---
`1` thru `9` | Select a peak
**Left** and **Right** | Adjust the peak position
**Up** and **Down** | Adjust the peak width
`X` | Lock the current peak's position
`W` | Lock the current peak's width
`Esc` | Go back to the first mode

#### Keys for both modes

Key | Action
--- | ---
`L` | Toggle the legend
`R` | Plot the average residual
`=` | Increase sensitivity
`-` | Decrease sensitivity

The sensitivity affects by how much a peak is adjusted in the second mode and by how many solutions are skipped when browsing in the first mode.

### `HPH`

Given `W` from `GAUSS`, plots the height of each peak versus the pH.

## General functions

### `COG`

`COG` is a function created to help me with parsing arguments.

### `ASKYN`

Asks a yes-or-no question and returns a logical.

### `CHOICE`

Prints a list of choices and waits for your input. Returns your choice.

### `GIF`

Makes creating `.gifs` easier than by using GIMP or `IMWRITE` or `RBG2IND`. It takes the filename and the frame handle, then adds the frame to the `.gif`.

# Background

A hydrogel is a gelled network of polymers with a dispersed substantial amount of water. Hydrogels have impressive properties and potential for applications. For example, hydrogels are similar to many of the viscoelastic tissues in the body required to frequently store and dissipate energy (cyclic load), suggesting biomedical applications such as replacing damaged cartilage.

![(Picture of mussel)](https://upload.wikimedia.org/wikipedia/commons/b/bc/Mytilus_with_byssus.jpg)
In the intertidal zone of beaches, the mussel remains fixed to inorganic substrates in changing environments. This includes dry and wet environments and the cyclic load from bombardment by turbulent waves. The mussel secretes a thread called the "byssus"; the cuticles on these threads can withstand the harshness of these conditions.

The [Laboratory for Bio-Inspired Interfaces](https://sites.google.com/site/holtengroup/) led by Niels Holten-Andersen studies synthetic metal-coordinating polymers inspired by the mussel's cuticles that exhibit promising mechanical properties such as self-healing and tunable viscoelastic relaxations.

By combining various metal salts with catechol- or nitrocatechol-modified polyethylene-glycol (PEG) polymers, we are able to form strong, hydrophilic coordination polymer networks that mimic the properties of the mussel's cuticles. Due to the unique, metal-dopa bonds that form between the metal ion and the ligand that spontaneously reform when broken and are only slightly weaker than a covalent bond, the formed hydrogel is soft, yet can be subjected to large amounts of strain and withstand underwater conditions, just as the mussel's cuticles can.

# Relevant readings

In order of abstract to specific

* 1995, [Simultaneous decomposition of several spectra into the constituent Gaussian peaks](https://doi.org/10.1016/0003-2670(95)00354-3)
* 1973, [The differentiation of pseudo-inverses and nonlinear least squares problems whose variables separate](https://doi.org/10.1137/0710036)
* 1991, [Dynamics of Reversible Networks](https://www.doi.org/10.1021/ma00016a034)
* 2004, [Visible absorption spectra of metal–catecholate and metal–tironate complexes](https://doi.org/10.1039/B315811J)
* 2006, [Absorption spectroscopy and binding constants for first-row transition metal complexes of a DOPA-containing peptide](https://www.doi.org/10.1039/B509586G)
* 2013, [Versatile tuning of supramolecular hydrogels through metal complexation of oxidation-resistant catecholinspired ligands](https://doi.org/10.1039/C3SM51824H)
* 2016, [Controlling Hydrogel Mechanics *via* Bio-Inspired Polymer−Nanoparticle Bond Dynamics](https://doi.org/10.1021/acsnano.5b06692)
* 2011, [pH-induced metal-ligand cross-links inspired by mussel yield self-healing polymer networks with near-covalent elastic moduli](https://doi.org/10.1073/pnas.1015862108)



