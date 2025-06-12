$graph:
- class: CommandLineTool
  id: s2_make_stac
  inputs:
  - id: files
    doc: FILES
    type:
      type: array
      items: File
  - id: geometry
    inputBinding:
      prefix: --geometry
    type:
    - 'null'
    - string
  requirements:
  - class: DockerRequirement
    dockerPull: ghcr.io/eo-datahub/user-workflows/s2_make_stac:main
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
  id: s2_mosaic
  inputs:
  - id: all_images
    doc: ALL_IMAGES
    type:
      type: array
      items: File
  - id: intersects
    inputBinding:
      prefix: --intersects
    type:
    - 'null'
    - string
  - id: month_json
    inputBinding:
      prefix: --month-json
    type: File
  outputs:
  - id: best_pixel
    outputBinding:
      glob: '*.tif'
    type: File
  requirements:
  - class: DockerRequirement
    dockerPull: ghcr.io/eo-datahub/user-workflows/s2_mosaic:main
  - class: InlineJavascriptRequirement
  doc: "None\n"
  baseCommand:
  - python
  - /app/app.py
- class: CommandLineTool
  id: s2_rm_cloud
  inputs:
  - id: item_url
    inputBinding:
      prefix: --item-url
    type:
    - 'null'
    - string
  outputs:
  - id: cloud_masked
    outputBinding:
      glob: '*.tif'
    type: File
  requirements:
  - class: DockerRequirement
    dockerPull: ghcr.io/eo-datahub/user-workflows/s2_rm_cloud:main
  - class: InlineJavascriptRequirement
  doc: "None\n"
  baseCommand:
  - /usr/local/bin/_entrypoint.sh
  - env
  - HOME=/tmp
  - python
  - /app/app.py
- class: CommandLineTool
  id: s2_search
  inputs:
  - id: catalog
    inputBinding:
      prefix: --catalog
    type:
    - 'null'
    - string
  - id: collection
    inputBinding:
      prefix: --collection
    type:
    - 'null'
    - string
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
  - id: start_datetime
    inputBinding:
      prefix: --start-datetime
    type:
    - 'null'
    - string
  outputs:
  - id: months
    outputBinding:
      glob: month_*.json
    type:
      items: File
      type: array
  - id: urls
    outputBinding:
      glob: urls.txt
      loadContents: true
      outputEval: $(self[0].contents.split('\n'))
    type:
      items: string
      type: array
  requirements:
  - class: DockerRequirement
    dockerPull: ghcr.io/eo-datahub/user-workflows/s2_search:main
  - class: InlineJavascriptRequirement
  doc: "None\n"
  baseCommand:
  - python
  - /app/app.py
- class: Workflow
  id: cloud-free-best-pixel
  inputs:
  - id: catalog
    label: Catalog path
    doc: Full catalog path
    default: supported-datasets/ceda-stac-catalogue
    type: string
  - id: collection
    label: collection id
    doc: collection id
    default: sentinel2_ard
    type: string
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
  outputs:
  - id: stac_output
    outputSource:
    - s2_make_stac/stac_catalog
    type: Directory
  requirements:
  - class: ScatterFeatureRequirement
  - class: ResourceRequirement
    coresMin: 4
    ramMin: 16000
  label: Cloud free best pixel
  doc: Generate cloud free best pixel mosaic on a per month basis
  steps:
  - id: s2_search
    in:
    - id: catalog
      source: catalog
    - id: collection
      source: collection
    - id: intersects
      source: intersects
    - id: start_datetime
      source: start_datetime
    - id: end_datetime
      source: end_datetime
    out:
    - id: urls
    - id: months
    run: '#s2_search'
  - id: s2_rm_cloud
    in:
    - id: item_url
      source: s2_search/urls
    out:
    - id: cloud_masked
    run: '#s2_rm_cloud'
    scatter:
    - item_url
    scatterMethod: dotproduct
  - id: s2_mosaic
    in:
    - id: intersects
      source: intersects
    - id: month_json
      source: s2_search/months
    - id: all_images
      source: s2_rm_cloud/cloud_masked
    out:
    - id: best_pixel
    run: '#s2_mosaic'
    scatter:
    - month_json
    scatterMethod: dotproduct
  - id: s2_make_stac
    in:
    - id: geometry
      source: intersects
    - id: files
      source: s2_mosaic/best_pixel
    out:
    - id: stac_catalog
    run: '#s2_make_stac'
cwlVersion: v1.0