name: "🩹 New troubleshooting entry"
description: Suggest a new troubleshooting cheat-sheet or add a fix to an existing one
title: "[troubleshooting] <topic>: <short summary>"
labels: ["troubleshooting", "new-entry"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for contributing a troubleshooting step! Sheets live at `<Topic>/Generic/<topic>.md` (one markdown file per topic, symptom → cause → fix, with commands). See CONTRIBUTING.md for the full workflow.

  - type: input
    id: topic
    attributes:
      label: Topic
      description: e.g. Linux, Kubernetes, Ceph, vSphere, Rancher, RKE, Windows, Veeam, Others
      placeholder: Linux
    validations:
      required: true

  - type: input
    id: symptom
    attributes:
      label: Symptom
      description: What breaks / what the user sees
      placeholder: Pod stuck in CrashLoopBackOff
    validations:
      required: true

  - type: textarea
    id: cause
    attributes:
      label: Likely cause
      description: Root cause or common causes
    validations:
      required: true

  - type: textarea
    id: fix
    attributes:
      label: Fix / commands
      description: Step-by-step fix, include shell/PowerShell commands in code blocks
    validations:
      required: true

  - type: input
    id: verify
    attributes:
      label: How you verified it
      description: Command or check that confirms the fix works
      placeholder: kubectl get pods | grep -v Running → empty

  - type: textarea
    id: ponytail
    attributes:
      label: Scope ceiling (optional)
      description: What this sheet intentionally does not cover, and when to extend it
