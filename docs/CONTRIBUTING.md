# Contributing to SL3-FrontierLab

A contribution to SL3-FrontierLab adds one control to an existing component, or adds one new component.
In either case it has three parts, which this guide treats in turn: a change to the configuration, a check on the deployed machine, and an entry in the system security plan.
The third part matters as much as the first two, because the entry is what allows a reader to trace the control to your configuration.

## What you need

A contribution starts from a working deployment, so the first requirement is a Proxmox server prepared as the [README](../README.md#getting-started) describes.
In addition, your computer needs Terraform 1.17 or later, git, and [`oscal-cli`](https://github.com/metaschema-framework/oscal-cli) 3.2.0, a Java tool that validates and queries OSCAL documents.
The commands of this guide run from the root of the repository.

## Add a control to a component

The six steps below lead from the text of a control to its entry in the record.

1. **Read the control.**
   Open [`oscal/sl3_profile.json`](../oscal/sl3_profile.json) and search for the identifier of the control in lower case, for example `"control-id": "sc-28"`.
   The field `prose`, a few lines below, holds RAND's text for that control.

2. **Choose the sentences.**
   A control usually contains several sentences, and a component often implements some of them.
   Note, word for word, the sentences that your change will make true, since the entry will quote them.

3. **Change the configuration.**
   The setup of a machine lives in its own folder, for example `weight-storage/cloud-init.yaml.tftpl`, and what every machine shares lives in the recipe, `modules/virtual-machine/`.
   Keep the change as small as the chosen sentences require, and follow the names and the order that the existing files use.

4. **Deploy and check on the machine.**
   Apply the change as the [Deploy](../README.md#deploy) section of the README shows, then connect to the machine and confirm each sentence with a command.
   For SC-4, for instance, `findmnt /srv/seaweedfs` shows that the folder of the weights sits on the data disk.
   Keep each command and its output, because the pull request will include them.

5. **Write the entry.**
   Add the control to [`oscal/system-security-plan.yaml`](../oscal/system-security-plan.yaml), as the section [Write the entry in the system security plan](#write-the-entry-in-the-system-security-plan) explains.

6. **Check your work.**
   Run the commands of the section [Check your work](#check-your-work), and compare each result with the expected one.

## Add a component

A component is a machine with one job, such as the Weight enclave, and it enters the repository through five additions.

1. **Its folder.**
   Create a folder at the root, named after the component in lower case with hyphens, and place its setup file `cloud-init.yaml.tftpl` there.
   The file of the Weight enclave serves as a working example.

2. **Its address.**
   Add a line to `locals.tf` that gives the machine the next free host number of the network; the Weight enclave holds number 2.

3. **Its machine.**
   Add a module call to `main.tf` that mirrors `module "weight_storage"`: the same `source`, a `count` that looks for the name of the component in `var.assets`, and the machine's own name, sizes and setup file.
   An output in `outputs.tf` can then print its address after the deployment.

4. **Its name in the settings.**
   Add the name of the folder to `TF_VAR_assets` in your `.env`, so that Terraform deploys the machine.

5. **Its entry among the components.**
   Add the component under `components` in the system security plan, with a new `uuid`, a `type`, a `title`, a `description` and a `status`, following the entry of the Weight enclave.

Once the machine runs, its controls follow one by one, as the previous section describes.
Should a machine need something that the recipe lacks, such as a graphics card, extend the recipe with a new variable, so that every machine continues to come from the same recipe.

## Write the entry in the system security plan

The system security plan holds one entry for each control, under `implemented-requirements`, and the entry for SC-4 is the model to follow.
A new entry takes the following shape:

```yaml
    - uuid: <new identifier>
      control-id: <identifier of the control, for example sc-28>
      by-components:
      - component-uuid: <uuid of the component, as listed under components>
        uuid: <new identifier>
        description: |-
          <The component> implements <number> sentences of the control's statement.

          "<First implemented sentence, word for word.>"
          <How the machine meets it, in one or two sentences.>
        implementation-status:
          state: <implemented, partial or planned>
          remarks: <Which sentences remain, and which component will bring them.>
        links:
        - href: ../<path of the file>
          rel: reference
          text: "<The resource or section of that file, and what it does.>"
```

Each field has a precise role:

| Field | What to write |
|---|---|
| `uuid` | A new identifier for the entry and another for each item of `by-components`, produced with `uuidgen` and written in lower case. |
| `control-id` | The identifier of the control as the profile writes it, for example `sc-28` or `ac-2.1`. |
| `component-uuid` | The `uuid` of the component that implements the control, copied from `components`. |
| `description` | The implemented sentences, quoted word for word, each followed by one or two sentences that say how the machine meets it. |
| `implementation-status` | The state of the whole control: `implemented` once every sentence holds, `partial` while some hold, and `planned` while the work lies ahead; `remarks` then names what remains. |
| `links` | One link for each file that does the work: `href` gives the path from `oscal/`, and `text` names the resource or the section, so that the reference stays exact when line numbers change. |

When a second component implements further sentences of a control that already has an entry, add a second item under `by-components` of that entry, so that each control keeps a single entry.
Lastly, give the document a new `uuid` and the current time in `last-modified`, at the top of the file, since NIST's guidance for OSCAL documents asks for both with every change of content:

```bash
uuidgen | tr 'A-Z' 'a-z'
date -u +%Y-%m-%dT%H:%M:%SZ
```

## Check your work

Five checks cover the configuration and the record, and each has an expected result.
The first two concern the configuration: Terraform confirms that the files are formatted and valid.

```bash
terraform fmt -check -recursive
terraform validate
```

The first command stays silent, and the second prints `Success! The configuration is valid.`

The third check concerns the structure of the record, and its last line ends with "is valid.":

```bash
oscal-cli validate oscal/system-security-plan.yaml
```

The last two checks cover what the structure leaves open, namely that each linked file exists and that each entry names a known component.
Both read the document through NIST's definition of the system security plan in OSCAL 1.2.3, which the variable `MODEL` holds:

```bash
MODEL=https://raw.githubusercontent.com/usnistgov/OSCAL/e061961c7702afeabffdf5e59894d35e748dade1/src/metaschema/oscal_ssp_metaschema.xml
oscal-cli metaschema metapath eval -m $MODEL -i oscal/system-security-plan.yaml -e '(//import-profile/@href, //link/@href) ! resolve-uri(., document-uri(/))'
oscal-cli metaschema metapath eval -m $MODEL -i oscal/system-security-plan.yaml -e '//by-component/@component-uuid[not(. = //component/@uuid)]'
```

The first query lists the files that the plan points to, each of which has to exist, and the second prints `()` when every entry names a component of the plan.
A further query then shows the result as a reader will meet it, that is, each control with its status, for example `sc-4` and `partial`:

```bash
oscal-cli metaschema metapath eval -m $MODEL -i oscal/system-security-plan.yaml -e '//implemented-requirement/(@control-id, by-component/implementation-status/@state)'
```

## Send your change

Changes arrive as [pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests).
Fork the repository, create a branch for your change, and keep one change in each commit, with a one-line message that names the change, such as `Add the system security plan with the Weight enclave and SC-4`.
In the pull request, name the control, quote the sentences that you implement, and include each command with which you confirmed them on the machine, together with its output.
A reviewer can then repeat your check and follow your entry from the control to the configuration.

## Challenge a decision

Every choice in this repository rests on a reason, and a better reason is always welcome.
To challenge a choice, open an [issue](https://github.com/marcellomaugeri/SL3-FrontierLab/issues) that names the control or the file, cites the source that supports your view, and proposes the change.

## Writing style

The prose of the repository follows a few rules, which keep it consistent across contributors.
It uses UK English and places one sentence on each line of the source files, so that every change shows clearly in a comparison of versions.
Its sentences state what holds or what can be done, and they explain each term where it first appears.
Finally, text taken from a source is quoted word for word and attributed to it.
