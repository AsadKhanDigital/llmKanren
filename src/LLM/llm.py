from dotenv import load_dotenv
from openai import OpenAI
from os import getenv

load_dotenv()
client = OpenAI(api_key=getenv("OPENAI_API_KEY"))

def generate_solution(prompt):

    response = None

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.95,
        )
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

    solution = response.choices[0].message.content

    return solution