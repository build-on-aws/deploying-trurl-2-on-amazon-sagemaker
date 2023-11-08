import sagemaker
import streamlit as st

from sagemaker.huggingface.model import HuggingFacePredictor


START = "<s>"
END = "</s>"

SYSTEM_START = "<<SYS>>"
SYSTEM_END = "<</SYS>>"

USER_START = "[INST]"
USER_END = "[/INST]"

STARTING_PROMPT = "Na początek podaj kategorię w której będziemy zgadywać rzecz, którą masz na myśli."


def clear_history():
    st.session_state.messages = [{"role": "assistant", "content": STARTING_PROMPT}]


def build_llama2_prompt(dict_messages):
    system_message = """Jesteś przyjaznym uczestnikiem gry o nazwie '20 pytań'. Twoim zadaniem jest odgadnąć jaką
rzecz pytający ma na myśli poprzez zadawanie pytań. Na początku gracz powie, w jakiej kategorii pojęć będziemy
zgadywać. Zawsze zadajesz jedno pytanie, na które można odpowiedzieć twierdząco lub przecząco. Kolejne pytania
powinny zawężać wybraną na początku gry kategorię i przybliżać Ciebie do wytypowania właściwej rzeczy. Gra dobiega
końca, gdy wyczerpiesz limit 20 pytań lub gdy odgadniesz konkretną rzecz."""

    string_dialogue = ""

    for dict_message in dict_messages:
        if dict_message["role"] == "user":
            string_dialogue += USER_START + dict_message["content"] + USER_END
        else:
            string_dialogue += " " + dict_message["content"] + " "

    return f"""{START}{USER_START} {SYSTEM_START}
{system_message}
{SYSTEM_END}{USER_END}{string_dialogue}"""


def call_sagemaker_endpoint(endpoint, prompt_input):
    data = {
        'inputs': prompt_input,
        "parameters": {
            "do_sample": True,
            "top_p": top_p,
            "temperature": temperature,
            "top_k": 50,
            "max_new_tokens": max_new_tokens,
            "repetition_penalty": 1.05,
            "stop": [END]
        }
    }

    predictor_response = endpoint.predict(data)
    text = predictor_response[0]['generated_text']
    return text[len(prompt_input):]


def talk_with_trurl2(endpoint, dict_message):
    llama2_prompt = build_llama2_prompt(dict_message)
    output = call_sagemaker_endpoint(endpoint, llama2_prompt)
    return output


title = "TRURL 2 🇵🇱🤖💬"
st.set_page_config(page_title=title)

sagemaker_session = sagemaker.Session()
sagemaker_endpoint_name = ""
predictor = None

with st.sidebar:
    st.title(title)

    if 'SAGEMAKER_ENDPOINT_NAME' in st.secrets:
        st.success('Amazon SageMaker Endpoint name is already provided!', icon='✅')
        sagemaker_endpoint_name = st.secrets['SAGEMAKER_ENDPOINT_NAME']
        predictor = HuggingFacePredictor(endpoint_name=sagemaker_endpoint_name, sagemaker_session=sagemaker_session)
    else:
        sagemaker_endpoint_name = st.text_input('Enter Amazon SageMaker Endpoint name:', type='default')
        if sagemaker_endpoint_name == "":
            st.warning('Please provide Amazon SageMaker Endpoint name with TRURL 2 model.', icon='⚠️')
        else:
            st.success('Now you can enter your prompt message!', icon='⌨️')
            predictor = HuggingFacePredictor(endpoint_name=sagemaker_endpoint_name, sagemaker_session=sagemaker_session)

    st.subheader('Model Parameters')
    temperature = st.sidebar.slider('temperature', min_value=0.01, max_value=5.0, value=0.9, step=0.01)
    top_p = st.sidebar.slider('top_p', min_value=0.01, max_value=1.0, value=0.6, step=0.01)
    max_new_tokens = st.sidebar.slider('max_new_tokens', min_value=32, max_value=128, value=120, step=8)

st.subheader("Let's play a game of 20 questions! 🎲")

if "messages" not in st.session_state.keys():
    st.session_state.messages = [{"role": "assistant", "content": STARTING_PROMPT}]

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.write(message["content"])

st.sidebar.button('Clear History', on_click=clear_history)

if prompt := st.chat_input(disabled=(predictor is None)):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.write(prompt)

if st.session_state.messages[-1]["role"] != "assistant":
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            response = talk_with_trurl2(predictor, st.session_state.messages)
            placeholder = st.empty()
            full_response = ''

            for item in response:
                full_response += item
                placeholder.markdown(full_response)

            placeholder.markdown(full_response)

    message = {"role": "assistant", "content": full_response}
    st.session_state.messages.append(message)
