## Deploying *TRURL 2* on *Amazon SageMaker*

This is a repository that contains a demo for deploying **[TRURL 2](https://huggingface.co/Voicelab/trurl-2-7b)** on [Amazon SageMaker](https://aws.amazon.com/sagemaker). It is a *Large Language Model (LLM)*, which is a fine-tuned version of [LLaMA 2](https://ai.meta.com/llama/) with support for *Polish* :poland: language that was prepared by [VoiceLab](https://voicelab.ai) and published on their company's [Hugging Face](https://huggingface.co/Voicelab) profile.

### What is *TRURL 2*?

For the majority of people, *TRURL 2* is the least familiar term in the title above - so allow me to start here. [TRURL 2](https://huggingface.co/Voicelab#models) is a fine-tuned version of [LLaMA 2](https://ai.meta.com/llama/#inside-the-model). According to the authors it is trained on over 1.7B tokens (970k conversational Polish and English samples) with a large context of 4096 tokens. To be precise, *TRURL 2* is not a single model, but a collection of fine-tuned generative text models with 7 billion and 13 billion parameters, optimized for dialogue use cases. You can read more about it on their official [blog post](https://voicelab.ai/trurl-is-here) after model's release.

#### Who created *TRURL* family of models?

It was created by a Polish :poland: company called [Voicelab.AI](https://voicelab.ai). They are based in [Gdańsk](https://en.wikipedia.org/wiki/Gda%C5%84sk) and specialise in developing solutions related to *[Conversational Intelligence](https://voicelab.ai/conversational-intelligence)* and *[Cognitive Automation](https://voicelab.ai/cognitive-automation)*.

#### What this word really means? Who is *Trurl*? :robot:

Even that *Trurl* as a word may look like a set of arbitrary letters put together, it actually makes sense. *Trurl* is one of the characters known from [Stanislaw Lem’s](https://en.wikipedia.org/wiki/Stanis%C5%82aw_Lem) science-fiction novel, ["The Cyberiad"](https://en.wikipedia.org/wiki/The_Cyberiad). According to the author of the book, he is a robotic engineer, *a constructor*, with almost godlike abilities. In one of the stories, he creates a machine called "Elektrybałt", which by description resembles today’s [GPT](https://en.wikipedia.org/wiki/Generative_pre-trained_transformer) solutions. You can clearly see, that this particular name is definitely not a coincidence.

#### What is *LLaMA 2*?

[LLaMA 2](https://ai.meta.com/resources/models-and-libraries/llama/) is a family of *Large Language Models (LLMs)* developed by Meta. This collection of pretrained and fine-tuned models is ranging in scale from 7 billion to 70 billion parameters. As the name suggests it is a 2nd iteration, and those models are trained on 2 trillion tokens and have double the context length of [LLaMA 1](https://ai.meta.com/blog/large-language-model-llama-meta-ai).

Additionally, remember to review and refer to the [*Meta’s Responsible Use Guide*](https://ai.meta.com/llama/responsible-use-guide) for the exact details and specific usage restrictions.

## Prerequisites and Setup

In order to successfully execute all steps in the given repository, you need to have the following prerequisites:

- Pre-installed tools:
  - Most recent *AWS CLI*.
  - *AWS CDK* in version 2.104.0 or higher.
  - Python 3.10 or higher.
  - Node.js v21.x or higher.
- Configured profile in the installed *AWS CLI* with credentials for your *AWS IAM* User account of choice.

### How to use that repository?

First, we need to configure local environment - and here are the steps:

```shell
# Do those in the repository root, after checking out.
# Ideally you should do them in a single terminal session.

# Node.js v21 is not yet supported inside JSII, but it works for that example - so "shush", please.
$ export JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=true

$ make
$ source ./.env/bin/activate

$ cd ../infrastructure
$ npm install

# Or `export AWS_PROFILE=<YOUR_PROFILE_FROM_AWS_CLI>`
$ export AWS_DEFAULT_PROFILE=<YOUR_PROFILE_FROM_AWS_CLI>
$ export AWS_USERNAME=<YOUR_IAM_USERNAME>

$ cdk bootstrap
$ npm run package
$ npm run deploy-shared-infrastructure

# Answer a few questions from the AWS CDK CLI wizard, and wait for the completion.

# Now you can push code from this repository to the created AWS CodeCommit git repository remote.
#
# Here you can find an official guide how to configure your local `git` for AWS CodeCommit:
#   https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up.html

$ git remote add aws <HTTPS_REPOSITORY_URL_PRESENT_IN_THE_CDK_OUTPUTS_FROM_PREVIOUS_COMMAND>
$ git push aws main

$ npm run deploy

# Again, answer a few questions from the AWS CDK CLI wizard, and wait for the completion.
```

Now, you can go to the newly created *Amazon SageMaker Studio* domain and open studio prepared for the provided username.

![Let's clone the repository - step 1](./docs/setup-1-clone-repository.png)
![Let's clone the repository - step 2](./docs/setup-2-clone-aws-codecommit-repository.png)

After studio's successfully start, in the next step you should clone *AWS CodeCommit* repository via the *user interface* of the *SageMaker Studio*.

Then, we need to install all project dependencies, and it would be great to enable the *Amazon CodeWhisperer* extension in your *SageMaker Studio* domain. If you would like to do that in the future on your own, [here you can find the exact steps](https://docs.aws.amazon.com/codewhisperer/latest/userguide/sagemaker-setup.html). In our case, steps up to 4th point are automated by the provided *infrastructure as code* solution. To execute the last two steps, you should open the *Launcher tab*.

![Open launcher](./docs/setup-3-open-launcher.png)
![Open a system terminal, not the Image terminal](./docs/setup-4-open-system-terminal.png)

Then, in the *System terminal* (not the *Image terminal*, see the different on the image above), run the following scripts:

```shell
# Those steps should be invoked in the *System terminal* inside *Amazon SageMaker Studio*:

$ cd deploying-trurl-2-on-amazon-sagemaker
$ ./install-amazon-code-whisperer-in-sagemaker-studio.sh
$ ./install-project-dependencies-in-sagemaker-studio.sh
```

Force refresh the browser tab with *SageMaker Studio* and you are ready to proceed. Now it's time to follow the steps inside the notebook available in the `trurl-2` directory and explore capabilities of *TRURL 2* model that you will deploy from *SageMaker Studio* notebook as an *Amazon SageMaker Endpoint*, and *CodeWhisperer* will be our AI-powered coding companion throughout the process.

### Exploration via *Jupyter Lab 3.0* in *Amazon SageMaker Studio*

So now it's time to deploy the model as an *SageMaker Endpoint* and explore the possibilities, but first - you need to locate and open the notebook.

![Locate the notebook file and open it](./docs/exploration-1-open-notebook.png)

After opening it for a first time, new dialog window will appear asking you to configure *kernel* (environment that will be executing our code inside the notebook). Please configure it accordingly to the screenshot below. If that window did not appear, or you've closed that by accident - you can always find that in the opened tab with notebook under the 3rd icon on the screenshot above.

![Configure kernel for your exploration notebook](./docs/exploration-2-configure-kernel.png)

Now you should be able to follow instructions inside the notebook by executing each cell with code one after another (via toolbar or keyboard shortcut: `CTRL/CMD + ENTER`). Keep in mind that before you will execute the clean-up section and invoke cell with `predictor.delete_endpoint()` you should *stop* :stop:, as we will need the running endpoint for the next section.

### Developing a prototype chatbot application with *Streamlit*

Now, we would like to use the deployed *Amazon SageMaker Endpoint* with *TRURL 2* model to develop a simple *chatbot* application that will play in a game of *20 questions* with us. You can find an example of such application developed with the use of *Streamlit* that can be invoked locally (assuming you have configured *AWS* credentials properly for the account), or inside *Amazon SageMaker Studio*.

![Final user interface in *Streamlit* with a sample '20 questions' conversation - this time he won! :(](./docs/streamlit-1-final-conversation.png)

In order to run it locally, you need to invoke following commands:

```shell
# If you use the previously used terminal session, you can skip this line:
$ source ./.env/bin/activate

$ cd trurl-2
$ streamlit run chatbot-app.st.py
```

If you would like to run that on the *Amazon SageMaker Studio*, you need to open *System terminal* as previously, and start it a bit differently:

```shell
$ conda activate studio
$ cd deploying-trurl-2-on-amazon-sagemaker/trurl-2
$ ./run-streamlit-in-sagemaker-studio.sh chatbot-app.st.py
```

Then, open the URL marked with a green color as on the screenshot below:

![Final user interface in *Streamlit* with a sample '20 questions' conversation - this time he won! :(](./docs/streamlit-2-run-on-sagemaker-studio.png)

Remember, that in both cases in order to communicate with chatbot you need to pass the name of *Amazon SageMaker Endpoint* in the text field inside sidebar on the left-hand side. How to find that? You can either look it up in the *[Amazon SageMaker Endpoints tab](https://eu-west-1.console.aws.amazon.com/sagemaker/home#/endpoints)* (keep in mind it is neither *URL*, nor *ARN* - only the name) or refer to the provided `endpoint_name` value inside *Jupyter* notebook, when you invoked `huggingface_model.deploy(...)` operation.

If you are interested in detailed explanation how we can run *Streamlit* inside *Amazon SageMaker Studio*, have a look on [this blog post](https://aws.amazon.com/blogs/machine-learning/build-streamlit-apps-in-amazon-sagemaker-studio) from the official *AWS* blog.

### Clean-up and Costs

This one is pretty easy! Assuming that you have followed all the steps inside the notebook in the *SageMaker Studio*, the only thing you need to do to clean-up is delete *AWS CloudFormation* stacks via *AWS CDK* (remember to close all the *applications* and *kernels* inside *Amazon SageMaker Studio* to be on the safe side). However, *Amazon SageMaker Studio* leaves a bit more resources hanging around related to the *Amazon Elastic File Storage (EFS)*, so first you have to delete the stack with *SageMaker Studio*, invoke clean-up script, and then delete everything else:

```shell
# Those steps should be invoked locally, from the repository root:

$ export STUDIO_STACK_NAME="Environment-SageMakerStudio"
$ export EFS_ID=$(aws cloudformation describe-stacks --stack-name "${STUDIO_STACK_NAME}" --query "Stacks[0].Outputs[?OutputKey=='SharedAmazonSageMakerStudioDomainEFS'].OutputValue" --output text)
$ export DOMAIN_ID=$(aws cloudformation describe-stacks --stack-name "${STUDIO_STACK_NAME}" --query "Stacks[0].Outputs[?OutputKey=='SharedAmazonSageMakerStudioDomainId'].OutputValue" --output text)

$ (cd infrastructure && cdk destroy "${STUDIO_STACK_NAME}")

$ ./clean-up-after-sagemaker-studio.sh "${EFS_ID}" "${DOMAIN_ID}"

$ (cd infrastructure && cdk destroy --all)
```

Last, but not least - here is a quick summary in terms of *how much does that cost*. The biggest cost factor are obviously machines used for *Amazon SageMaker Endpoint* (1x `ml.g5.2xlarge`) and *kernel* that was used by *Amazon SageMaker Studio Notebook* (1x `ml.t3.medium`). Assuming, that we have set up all infrastructure in `eu-west-1`, the total cost of using for 8 hours cloud resources from this code sample will be lower than $15 ([here you can find detailed calculation](https://calculator.aws/#/estimate?id=789a6cd85ffac96e8b4321cca2a9a4d53cdb5210)).

## Contact

If you have more questions, feel free to [contact me directly](https://awsmaniac.com/contact).

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the *MIT-0* License. See the [LICENSE](LICENSE) file.
