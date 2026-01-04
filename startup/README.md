=== Basic Info ===

From the Comfy UI Docker Image Template Readme:
https://cloud.vast.ai/template/readme/3272574a688022dd7062b4e5303d1348

They provide a link to the source base image and custom comfy UI image (which extends from it)

Base:
https://github.com/vast-ai/base-image/blob/main/Dockerfile

Comfy UI Extension:
https://github.com/vast-ai/base-image/tree/main/derivatives/pytorch/derivatives/comfyui

The docker file installs comfy UI.

You can also see there is both a docker entrypoint shell script that runs (after reviewing with the AI, you shouldn't need to modify this, as it just sets up Python and permissions, and is located on the base image). 
After, it runs a special provisioning script. This script downloads the required models and workflows to be used in Comfy UI.

By default, the env var in the template sets the provisioning script to:
https://github.com/vast-ai/base-image/blob/main/derivatives/pytorch/derivatives/comfyui/provisioning_scripts/default.sh

But you can actually select another one from Vast AI's github repo, such as:
https://github.com/vast-ai/base-image/blob/main/derivatives/pytorch/derivatives/comfyui/provisioning_scripts/ltx-video.sh

So this way you can setup an image to video model and workflow from the start! 

=== UPDATES ===

Note you have created your own Comfy UI custom template (look under my templates) that you can use to modify and update the provisioning script (and other env vars) as needed (click my templates):
https://cloud.vast.ai/templates/

For LTX, I checked for the latest updates:
https://huggingface.co/Lightricks/LTX-Video

I forked the LTX provisioning script, and updated to use the latest version of LTX and the recommended workflow using above as a guide and with the AI's help:
https://gist.github.com/bartnic2/e0b6c5928430bd9047ea33127869f4c5

So you can just update that LTS script as needed, and make sure the custom template has your gist URL set as the provisioning_script env var.
