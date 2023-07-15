This service provides a graphical interface for the Stable Diffusion image generation model.

## Basic Usage

Stable Diffusion is easiest to use in the "txt2img" mode. Enter some text describing your desired image into the "Prompt" box, then press the "Generate" button. Generating an image can take quite a long time, so be patient. Alternatively you can use the "img2img" mode to make changes to an existing photograph or drawing.

There a number of tutorials and guides online to help you navigate the user interface for the first time. For example, [stable-diffusion-art.com](https://stable-diffusion-art.com/automatic1111/#Text-to-image_tab) has a useful overview of the features of both the txt2img and img2img tabs. Effective prompting can also be surprisingly difficult, so if you are unhappy with your results definitely consult a [guide on the anatomy of a good prompt](https://stable-diffusion-art.com/prompt-guide/). Note that significantly increasing the resolution or batch size may crash the service, requiring you to manually restart it from the Start9 "Installed Services" tab.

All generated images are logged to the `stable-diffusion/outputs` directory in the File Browser service, and saved images are copied to the neighboring `stable-diffusion/saved` directory.

## Additional Models

The default Stable Diffusion model included with the service (v2.1) is generally quite good across a range of different styles and subjects, but you can get better results by choosing a model checkpoint finetuned with your specific goals in mind. [Civitai](https://civitai.com/) is an excellent source of such models. To install one, download your chosen ".safetensors" file and then upload it to the `stable-diffusion/models/Stable-diffusion` directory in the File Browser service. Note that ".ckpt" files can also work, but are much less secure and may damage your system.

Once the checkpoint file is uploaded, you can return to the Stable Diffusion user interface, press the refresh button (🔄) next to the "Stable Diffusion checkpoint" dropdown at the top, and then choose your desired model in the dropdown.
