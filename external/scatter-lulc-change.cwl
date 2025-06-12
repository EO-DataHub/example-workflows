cwlVersion: v1.0

$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.1.8
schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf

$graph:
  - class: Workflow

    id: scatter-lulc-change
    label: LULC change
    doc: LULC change

    requirements:
      - class: ResourceRequirement
        coresMax: 1
        ramMax: 4096
      - class: ScatterFeatureRequirement

    inputs:
      areas:
        label: areas of interest
        doc: areas of interest as a polygon
        type: string[]
      source:
        label: source
        doc: data source to be processed
        type: string
      date_start:
        label: start date
        doc: start date for data queries in ISO 8601
        type: string
      date_end:
        label: end date
        doc: end date for data queries in ISO 8601
        type: string

    outputs:
      - id: results
        type: Directory
        outputSource:
          - stac_join/results

    steps:
      lc_change:
        run: "#lc_change"
        scatter: aoi
        in:
          source: source
          aoi: areas
          date_start: date_start
          date_end: date_end
        out:
          - lcc_results
      stac_join:
        run: "#stac_join"
        in:
          stac_catalog_dir:
            source: lc_change/lcc_results
        out:
          - results

  - class: CommandLineTool
    id: lc_change
    requirements:
      ResourceRequirement:
        coresMax: 1
        ramMax: 4096
      EnvVarRequirement:
        envDef:
          ENVIRONMENT: <<ENVIRONMENT>>
          SENTINEL_HUB__CLIENT_ID: <<SENTINEL_HUB__CLIENT_ID>>
          SENTINEL_HUB__CLIENT_SECRET: <<SENTINEL_HUB__CLIENT_SECRET>>
          SENTINEL_HUB__STAC_API_ENDPOINT: <<SENTINEL_HUB__STAC_API_ENDPOINT>>
          EODH__STAC_API_ENDPOINT: <<EODH__STAC_API_ENDPOINT>>
          EODH__CEDA_STAC_CATALOG_PATH: <<EODH__CEDA_STAC_CATALOG_PATH>>
    hints:
      DockerRequirement:
        dockerPull: ghcr.io/eo-datahub/eodh-workflows:latest
    baseCommand: [ "eodh", "lulc", "change" ]
    inputs:
      source:
        type: string
        inputBinding:
          position: 2
          prefix: --source
      aoi:
        type: string
        inputBinding:
          position: 3
          prefix: --aoi
      date_start:
        type: string
        inputBinding:
          position: 4
          prefix: --date_start
      date_end:
        type: string
        inputBinding:
          position: 5
          prefix: --date_end
    outputs:
      lcc_results:
        type: Directory
        outputBinding:
          glob: ./data/stac-catalog/

  - class: CommandLineTool
    id: stac_join
    requirements:
      ResourceRequirement:
        coresMax: 2
        ramMax: 4096
      EnvVarRequirement:
        envDef:
          ENVIRONMENT: <<ENVIRONMENT>>
          SENTINEL_HUB__CLIENT_ID: <<SENTINEL_HUB__CLIENT_ID>>
          SENTINEL_HUB__CLIENT_SECRET: <<SENTINEL_HUB__CLIENT_SECRET>>
          SENTINEL_HUB__STAC_API_ENDPOINT: <<SENTINEL_HUB__STAC_API_ENDPOINT>>
          EODH__STAC_API_ENDPOINT: <<EODH__STAC_API_ENDPOINT>>
          EODH__CEDA_STAC_CATALOG_PATH: <<EODH__CEDA_STAC_CATALOG_PATH>>
    hints:
      DockerRequirement:
        dockerPull: ghcr.io/eo-datahub/eodh-workflows:latest
    baseCommand: [ "eopro", "stac", "join_v2" ]
    inputs:
      stac_catalog_dir:
        type:
          type: array
          items: Directory
          inputBinding:
            position: 1
            prefix: --stac_catalog_dir
    outputs:
      results:
        type: Directory
        outputBinding:
          glob: ./stac-join/