# Git Repository of Example Workflows to be Used with the EO Datahub Workflow Runner
This repository includes a number of workflows, defined as Common Workflow Language (CWL) scripts. These can be deployed to a user's workspace via the Workflow Runner and executed on a set of inputs.

The following workflows are currently defined within this repository:
- Internal Workflows - those developed alongside the DataHub
  - snuggs (based on EOEPCA)
  - convert-url (borrowed from EOEPCA)
  - convert-stac (borrowed from EOEPCA)
  - water-bodies (borrowed from EOEPCA)

- External Workflows - those developed by other users of the DataHub, including those produced by:
  - Oxidian
  - Spyrosoft
  - Sparkgeo
  - Airbus
  - NPL


You can use the provided Jupyter Notebook to deploy, execute and view these workflows. To get set up you will need to start a Notebook server and generate a workspace-scoped API token for your workspace. You can place this token in a .env file within this directory.

Run Jupyter Notebook
```
jupyter notebook
```

Copy the example sample.env file
```
cp sample.env .env
```

And place your token inside it, as generated from the DataHub [Workspace UI](https://eodatahub.org.uk/workspaces/) under Credentials.
