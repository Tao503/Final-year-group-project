from google import genai

# Setup your API Key
API_KEY = "AIzaSyAFWriMbwsC2yMEkM4TeRkCPDx1Lc-_ju8"
client = genai.Client(api_key=API_KEY)

# Use the stable 2.5 Flash model (Standard for March 2026)
MODEL_ID = "gemini-2.5-flash" 

def ask_gemini(prompt):
    try:
        # Note: 'contents' must be a list or a string in the new SDK
        response = client.models.generate_content(
            model=MODEL_ID,
            contents=prompt
        )
        print(f"Gemini: {response.text}")
    except Exception as e:
        print(f"Full Error Details: {e}")

if __name__ == "__main__":
    user_prompt = "Say hello and tell me one quick fact about Lagos."
    ask_gemini(user_prompt)