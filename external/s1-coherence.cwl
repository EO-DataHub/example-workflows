$graph:
- class: CommandLineTool
  id: s1_make_stac
  inputs:
  - id: files
    doc: FILES
    type:
      type: array
      items: File
  - id: intersects
    inputBinding:
      prefix: --intersects
    type:
    - 'null'
    - string
  requirements:
  - class: DockerRequirement
    dockerPull: ghcr.io/eo-datahub/user-workflows/s1_make_stac:main
  - class: InlineJavascriptRequirement
  doc: "None\n"
  baseCommand:
  - python
  - /app/app.py
  outputs:
  - id: stac_catalog
    outputBinding:
      glob: .
    type: Directory
- class: CommandLineTool
  id: s1_process
  inputs:
  - id: aws_access_key_id
    inputBinding:
      prefix: --aws-access-key-id
    type:
    - 'null'
    - string
  - id: aws_secret_access_key
    inputBinding:
      prefix: --aws-secret-access-key
    type:
    - 'null'
    - string
  - id: aws_session_token
    inputBinding:
      prefix: --aws-session-token
    type:
    - 'null'
    - string
  - id: intersects
    inputBinding:
      prefix: --intersects
    type:
    - 'null'
    - string
  - id: pair
    inputBinding:
      prefix: --pair
    type: File
  - id: password
    inputBinding:
      prefix: --password
    type:
    - 'null'
    - string
  - id: username
    inputBinding:
      prefix: --username
    type:
    - 'null'
    - string
  - id: workspace
    inputBinding:
      prefix: --workspace
    type:
    - 'null'
    - string
  outputs:
  - id: coherence
    outputBinding:
      glob: data/results/coh_vv.tif
    type: File
  requirements:
  - class: DockerRequirement
    dockerPull: ghcr.io/eo-datahub/user-workflows/s1_process:main
  - class: InlineJavascriptRequirement
  doc: "None\n"
  baseCommand:
  - /usr/local/bin/_entrypoint.sh
  - env
  - HOME=/tmp
  - python
  - /app/app.py
- class: CommandLineTool
  id: s1_search
  inputs:
  - id: end_datetime
    inputBinding:
      prefix: --end-datetime
    type:
    - 'null'
    - string
  - id: intersects
    inputBinding:
      prefix: --intersects
    type:
    - 'null'
    - string
  - id: password
    inputBinding:
      prefix: --password
    type:
    - 'null'
    - string
  - id: start_datetime
    inputBinding:
      prefix: --start-datetime
    type:
    - 'null'
    - string
  - id: username
    inputBinding:
      prefix: --username
    type:
    - 'null'
    - string
  outputs:
  - id: pairs
    outputBinding:
      glob: pair_*.geojson
    type:
      items: File
      type: array
  requirements:
  - class: DockerRequirement
    dockerPull: ghcr.io/eo-datahub/user-workflows/s1_search:main
  - class: InlineJavascriptRequirement
  doc: "None\n"
  baseCommand:
  - python
  - /app/app.py
- class: Workflow
  id: s1-coherence
  inputs:
  - id: intersects
    label: Intersects
    doc: "a GeoJSON-like json string, which provides a \"type\" member describing
      the type of the geometry and \"coordinates\"  member providing a list of coordinates.
      Will search for images intersecting this geometry.\n"
    default: "{\n  \"type\": \"Polygon\",\n  \"coordinates\": [\n    [\n      [0.08905898091569497,
      52.69722175598818],\n      [0.08905898091569497, 52.15527412683906],\n     \
      \ [0.9565339502005088, 52.15527412683906],\n      [0.9565339502005088, 52.69722175598818],\n\
      \      [0.08905898091569497, 52.69722175598818]\n    ]\n  ]\n}\n"
    type: string
  - id: start_datetime
    label: Start datetime
    doc: Start datetime
    default: '2023-04-01'
    type: string
  - id: end_datetime
    label: End datetime
    doc: End datetime
    default: '2023-06-30'
    type: string
  - id: username
    label: Username
    doc: Username
    type: string
  - id: password
    label: Password
    doc: Password
    type: string
  outputs:
  - id: stac_output
    outputSource:
    - s1_make_stac/stac_catalog
    type: Directory
  requirements:
  - class: ScatterFeatureRequirement
  label: S1 coherence
  doc: Generate Sentinel 1 image pair coherence
  steps:
  - id: s1_search
    in:
    - id: intersects
      source: intersects
    - id: start_datetime
      source: start_datetime
    - id: end_datetime
      source: end_datetime
    - id: username
      source: username
    - id: password
      source: password
    out:
    - id: pairs
    run: '#s1_search'
  - id: s1_process
    in:
    - id: pair
      source: s1_search/pairs
    - id: intersects
      source: intersects
    - id: username
      source: username
    - id: password
      source: password
    out:
    - id: coherence
    run: '#s1_process'
    scatter:
    - pair
    scatterMethod: dotproduct
  - id: s1_make_stac
    in:
    - id: intersects
      source: intersects
    - id: files
      source: s1_process/coherence
    out:
    - id: stac_catalog
    run: '#s1_make_stac'
cwlVersion: v1.0