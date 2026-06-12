import streamlit as st
import autogen
import json

st.set_page_config(page_title="AI Agent Portal", layout="wide")

st.title("🤖 Multi-Agent AI Portal")

api_key = st.text_input("Enter GROQ API Key:", type="password")

if st.button("Run Agent Discussion"):
    if api_key:
        config_list = [{
            "model": "llama-3.3-70b-versatile",
            "api_key": api_key,
            "base_url": "https://api.groq.com/openai/v1"
        }]

        user_proxy = autogen.UserProxyAgent(name="User", human_input_mode="NEVER")
        architect = autogen.AssistantAgent(name="Architect", llm_config={"config_list": config_list})
        coder = autogen.AssistantAgent(name="Coder", llm_config={"config_list": config_list})
        tester = autogen.AssistantAgent(name="Tester", llm_config={"config_list": config_list})

        groupchat = autogen.GroupChat(agents=[user_proxy, architect, coder, tester], messages=[], max_round=3)
        manager = autogen.GroupChatManager(groupchat=groupchat, llm_config={"config_list": config_list})

        with st.spinner("Agents are discussing..."):
            user_proxy.initiate_chat(manager, message="Design a task management application.")
        
        st.success("Process Completed!")
        for msg in groupchat.messages:
            st.markdown(f"**{msg.get('name')}:** {msg.get('content')}")
    else:
        st.error("API Key is required!")
