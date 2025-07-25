cwlVersion: v1.2
$graph:
  - class: Workflow
    id: produce-hazard-indicator
    label: produce hazard indicator
    doc: Produce a hazard indicator with os_climate_hazard
    requirements:
      ResourceRequirement:
        coresMax: 2
        ramMax: 4096

    inputs:
      ceda_username:
        type: string
        default: ""
      ceda_password:
        type: string
        default: ""
      source_dataset:
        type: string
      source_dataset_kwargs:
        type: string
        default: "{}"
      gcm_list:
        type: string
      scenario_list:
        type: string
      threshold_list:
        type: string
        default: "[]"
      threshold_temperature:
        type: float
        default: 0
      central_year_list:
        type: string
      central_year_historical:
        type: int
      window_years:
        type: int
      indicator:
        type: string
        default: "days_tas_above_indicator"
      store:
        type: string
        default: "./indicator"
      store_netcdf_coords:
        type: boolean
        default: false
      dask_cluster_kwargs:
        type: string
        default: "{'n_workers': 1, 'threads_per_worker': 1}"

    outputs:
      - id: indicator-result
        type: Directory
        outputSource:
          - indicator-step/indicator-results

    steps:
      indicator-step:
        run: "#indicator-command"
        in:
          ceda_username: ceda_username
          ceda_password: ceda_password
          source_dataset: source_dataset
          source_dataset_kwargs: source_dataset_kwargs
          gcm_list: gcm_list
          scenario_list: scenario_list
          threshold_list: threshold_list
          threshold_temperature: threshold_temperature
          central_year_list: central_year_list
          central_year_historical: central_year_historical
          window_years: window_years
          indicator: indicator
          store: store
          store_netcdf_coords: store_netcdf_coords
          dask_cluster_kwargs: dask_cluster_kwargs
        out:
          - indicator-results


  - class: CommandLineTool
    id: indicator-command

    hints:
      DockerRequirement:
        dockerPull: public.ecr.aws/c9k5s3u3/os-hazard-indicator:48a77e6

    requirements:
      ResourceRequirement:
        coresMax: 2
        ramMax: 4096
      NetworkAccess:
        networkAccess: true
      EnvVarRequirement:
          envDef:
            CEDA_USERNAME: $(inputs.ceda_username)
            CEDA_PASSWORD: $(inputs.ceda_password)

    inputs:
      ceda_username:
        type: string
      ceda_password:
        type: string
      source_dataset:
        type: string
      source_dataset_kwargs:
        type: string
      gcm_list:
        type: string
      scenario_list:
        type: string
      threshold_list:
        type: string
      threshold_temperature:
        type: float
      central_year_list:
        type: string
      central_year_historical:
        type: int
      window_years:
        type: int
      indicator:
        type: string
      store:
        type: string
      store_netcdf_coords:
        type: boolean
      dask_cluster_kwargs:
        type: string

    outputs:
      indicator-results:
        type: Directory
        outputBinding:
          glob: $(inputs.store)

    baseCommand: os_climate_hazard

    arguments:
      - valueFrom: $(inputs.indicator)
      - prefix: --store
        valueFrom: $(inputs.store)
      - prefix: --source_dataset
        valueFrom: $(inputs.source_dataset)
      - prefix: --source_dataset_kwargs
        valueFrom: $(inputs.source_dataset_kwargs)
      - prefix: --gcm_list
        valueFrom: $(inputs.gcm_list)
      - prefix: --scenario_list
        valueFrom: $(inputs.scenario_list)
      - prefix: --threshold_list
        valueFrom: $(inputs.threshold_list)
      - prefix: --threshold_temperature
        valueFrom: $(inputs.threshold_temperature)
      - prefix: --central_year_list
        valueFrom: $(inputs.central_year_list)
      - prefix: --central_year_historical
        valueFrom: $(inputs.central_year_historical)
      - prefix: --window_years
        valueFrom: $(inputs.window_years)
      - prefix: --store_netcdf_coords
        valueFrom: $(inputs.store_netcdf_coords)
      - prefix: --dask_cluster_kwargs
        valueFrom: $(inputs.dask_cluster_kwargs)