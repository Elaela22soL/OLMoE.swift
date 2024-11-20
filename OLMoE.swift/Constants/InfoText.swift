//
//  InfoText.swift
//  OLMoE.swift
//
//  Created by Thomas Jones on 11/19/24.
//

enum InfoText {

    static let body =
    """
    **What is the OLMoE App?**
    
    This application allows you to interact with Ai2’s OLMoE model, a mixture of Mixture-of-Experts model that can run on device.

    
    **What type of data is used to train the models:**

    OLMoE is pre-trained on the Ai2 [OLMoE-mix-0924](https://huggingface.co/datasets/allenai/OLMoE-mix-0924) dataset, including a diverse mix of web content, academic publications, code, math, and encyclopedic materials, and fine-tuned on the [Tulu 3 preview](https://huggingface.co/datasets/allenai/tulu-v3.1-mix-preview-4096-OLMoE) dataset.

    
    **How up-to-date is the training data?**

    The OLMoE-Instruct model is trained on the [OLMoE-mix dataset](https://huggingface.co/datasets/allenai/OLMoE-mix-0924), which consists of training data collected up until December 2023. Accordingly, the OLMoE-Instruct model only includes events or publications before that date.

    
    **How accurate and reliable is generated content on this app?**

    OLMoE-generated content is built for research and educational purposes only. It is not intended to be accurate or reliable, but rather as a research tool and to help the general public better understand LLMs. Please do not rely on any OMLoE generated content and always use your best judgment, fact-check important information, and consider the context when interpreting content generated in this app.

    
    **What data does Ai2 collect about me?**

    The only time this app collects data is when you choose to share a conversation. Once you share a conversation, we use this interaction data to identify areas for improvement and to develop new features that advance the scientific and educational purposes of Ai2, as described in our general [Terms of Use](https://allenai.org/terms/2024-09-25) and [Privacy Policy](https://allenai.org/privacy-policy).

    Please do not include PII (personally identifiable information) in model prompts or elsewhere in this app.
    """
}
