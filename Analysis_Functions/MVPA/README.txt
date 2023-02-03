Steps for running MVPA

(1) Preprocessing

- Open prep_mvpa
  - Under Specifications, change directories and AnalysisName
- Run prep_mvpa_all(first_part, last_part)
  - Input arguments: first_part = index of first id to run (e.g. 1), last_part = index of last id to run (e.g. 720)

(2) MVPA

- Open coscience_config_v1
  - Under General Study Parameters, change directory bdir and AnalysisName
- Open runall
  - Under Specifications insert index of participants to run
- Run runall for first-level analyses
- Run ANALYSE_DECODING_ERP('coscience',1,0,'all',1) for second-level analyses
