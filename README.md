# Publication Code for Balkus et al. (2024)
Code to reproduce the results reported in our upcoming paper. 

- `data-cleaning` contains R scripts used to harmonize California ZEV data at the ZCTA-level (treatment), gridded NO2 pollution forecasts (outcome), socioeconomic Census data and EPA Smart Mapping land use data (confounders), as well as the interference network from Census LODES data.
- `data-analysis` contains Julia and R scripts used to perform the data analysis using the `ModifiedTreatment.jl` and `Condensity.jl` packages. 
- `simulations` contains Julia code to generate synthetic data using `CausalTables.jl` and evaluate operating characteristics of the model using `ModifiedTreatment.jl` and `Condensity.jl` to fit the models.

Note that `data-analysis` and `simulations` depend on Julia packages still under development. If any issues or concerns arise, please [file an issue](https://github.com/salbalkus/pub-code-mtp-interfere/issues) describing the problem at hand.
