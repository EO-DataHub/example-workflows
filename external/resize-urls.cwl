$graph:
- class: CommandLineTool
  id: 'resize_make_stac'
  inputs:
  - id: 'files'
    doc: FILES
    type:
      type: array
      items: File
    inputBinding: {}
  requirements:
  - class: DockerRequirement
    dockerPull: ghcr.io/eo-datahub/user-workflows/resize_make_stac:main
  - class: InlineJavascriptRequirement
  doc: "None\n"
  baseCommand:
  - python
  - /app/app.py
  outputs:
  - id: 'stac_catalog'
    outputBinding:
      glob: .
    type: Directory
- class: CommandLineTool
  inputs:
  - id: 'url'
    inputBinding:
      position: 1
      prefix: /vsicurl/
      separate: false
    type: string
  - id: 'fname'
    inputBinding:
      position: 2
      valueFrom: $(inputs.url.split('/').pop() + "_resized.tif")
    type: string
  - id: 'outsize_x'
    inputBinding:
      position: 4
      prefix: -outsize
      separate: true
    type: string
  - id: 'outsize_y'
    inputBinding:
      position: 5
    type: string
  outputs:
  - type: File
    outputBinding:
      glob: '*.tif'
    id: 'resized'
  requirements:
  - class: DockerRequirement
    dockerPull: ghcr.io/osgeo/gdal:ubuntu-small-latest
  - class: InlineJavascriptRequirement
  baseCommand: gdal_translate
  id: 'resize_process'
- class: Workflow
  id: 'resize-urls'
  inputs:
  - id: 'urls'
    label: urls
    doc: urls
    type:
      type: array
      items: string
  - id: 'outsize_x'
    label: outsize_x
    doc: outsize_x
    default: 5%
    type: string
  - id: 'outsize_y'
    label: outsize_y
    doc: outsize_y
    default: 5%
    type: string
  outputs:
  - id: 'stac_output'
    outputSource:
    - 'resize_make_stac/stac_catalog'
    type: Directory
  requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  label: Resize urls
  doc: Resize urls
  steps:
  - id: 'resize_process'
    in:
    - id: 'outsize_x'
      source: 'outsize_x'
    - id: 'outsize_y'
      source: 'outsize_y'
    - id: 'url'
      source: 'urls'
    - id: 'fname'
      valueFrom: $(inputs.url.split('/').pop() + "_resized.tif")
    out:
    - id: 'resized'
    run: '#resize_process'
    scatter:
    - 'url'
    scatterMethod: dotproduct
  - id: 'resize_make_stac'
    in:
    - id: 'files'
      source: 'resize_process/resized'
    out:
    - id: 'stac_catalog'
    run: '#resize_make_stac'
cwlVersion: v1.0