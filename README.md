# The elective care backlog and ethnicity

## Project description

In November 2022, The Nuffield Trust released a
[report](https://www.nuffieldtrust.org.uk/research/the-elective-care-backlog-and-ethnicity) 
looking at the impact of the backlog in elective care for different ethnic groups in England. 
The report used data from Hospital Episode Statistics (HES).  

In this repository, we show:  
- how we processed data from HES and ETHPOP  
- how we applied the CHIME ruleset to reallocate conflicting ethnic categories  
- how we calculated standardised rates  
- how we calculated models by ethnic category, region, or deprivation decile.  


## Data sources

The hospital data used for this analysis is not publically available, so the code 
cannot be used to directly replicate the analysis. However, with modifications 
the code could be used on other copies of these datasets.

Population data comes from [ETHPOP](https://reshare.ukdataservice.ac.uk/852508/). 
Note that when processing the ETHPOP data, we use the 
[untranspose](https://github.com/gerhard1050/Untranspose-a-Wide-File) SAS macro. 
This is not strictly necessary as the data can be reformatted using native SAS 
approaches, but does have several advantages for the analyst. We are grateful to 
the authors.

The method for reassigning ethnic categories is based on the
[CHIME ruleset](https://www.gov.uk/government/statistics/covid-19-health-inequalities-monitoring-in-england-tool-chime/method-for-assigning-ethnic-group-in-the-covid-19-health-inequalities-monitoring-for-england-chime-tool).  

## Usage

* [01_import_setup.sas](01_import_setup.sas) has the code used to process HES data.  
* [02_reassign_ethnos.sas](02_reassign_ethnos.sas) has the code used to reassign
the ethnicity according to different rulesets.  
* [03_ethpop_prep.sas](03_ethpop_prep.sas) has the code to process raw ETHPOP data.  
* [04_rates.sas](04_rates.sas) has the code to produce standardised rates.  
* [05_models.sas](05_models.sas) has the code to run models by ethnic group.  
* [06_models_region_deprivation.sas](06_models_region_deprivation.sas) has the code 
to run models instead by region or by deprivation decile.  
* [07_models_subanalysis.sas](07_models_subanalysis.sas) has the code to run 
subanalysis models. (Note, that some of the data for this was prepared in Excel.)  

## Code authors
* Jonathan Spencer - [Twitter](https://twitter.com/jspncr_) - [Github](https://github.com/jspncrnt)
* Theo Georghiou - [Github](https://github.com/tgeorghiou)

## License
This project is licensed under the [MIT License](https://github.com/NuffieldTrust/ethnicity_coding_quality_england/blob/main/LICENSE).

## Acknowledgements
This project was supported by the NHS Race and Health Observatory.

This work uses Hospital Episode Statistics (HES) data. Copyright © 2022, NHS Digital. Re-used with permission of NHS Digital. All rights reserved. 
A data-sharing agreement with NHS Digital (DARS-NIC-226261-M2T0Q) governed access to and use of HES data for this 
project. No results or derived outputs from these datasets are present in this 
repository, but this code was used to create the results presented in the 
main report.

The untranspose macro was created by Arthur S. Tabachneck, Matthew Kastin,
Joe Matise, and Gerhard Svolba. The code to use the macro is available [here](https://github.com/gerhard1050/Untranspose-a-Wide-File)

## Suggested citation

Georghiou T, Spencer J, Scobie S and Raleigh V (2022) The elective care backlog and ethnicity. Research report, Nuffield Trust.
