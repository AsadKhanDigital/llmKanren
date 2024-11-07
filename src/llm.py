from dotenv import load_dotenv
from openai import OpenAI

import os

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Generate candidate solutions for the provided scheme definition given defined logic variables and sample test cases
def gen_solutions(definition, logic_vars, test_cases):

    prompt = \
        f"Given the following scheme definition with 'holes' :\n\n{definition}\n\n" + \
        "With the following logic variables defined:\n\n" + \
        "\n".join([f"{var}" for var in logic_vars]) + \
        "\n\nGenerate 100 valid candidate solutions for the following test cases:\n\n" + \
        "\n".join([f"{test_case['input']}: {test_case['output']}" for test_case in test_cases]) + \
        """
        \n
        - 'define'
        - 'letrec'
        - 'lambda'
        - 'if'
        - 'symbol?'
        - 'not'
        - 'and'
        - 'or'
        - 'list'
        - 'null?'
        - 'pair?'
        - 'car'
        - 'cdr'
        - 'cons'
        - 'equal?'
        - 'let'
        - 'match'
        - 'quote'
        - function application
        """ + \
        "\n\n Output only the function definitions. Do not include other text or formatting." + \
        "\n\nDo not include the ```scheme formatting in your response." + \
        "\n\nMake sure that all parantheses are balanced and there are no missing or extra parantheses."

    try:
    
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.9
        )

    except Exception as e:
        print(e)
        return None

    return response.choices[0].message.content.strip()

def balance_parantheses(text):
    stack = []
    opening = "([{"
    closing = ")]}"
    pairs = dict(zip(opening, closing))
    
    balanced = ""
    
    for char in text:
        balanced += char
        if char in opening:
            stack.append(char)
        elif char in closing:
            if not stack or pairs[stack.pop()] != char:
                # Mismatched closing bracket, ignore it
                balanced = balanced[:-1]
    
    # Add any remaining closing brackets
    while stack:
        balanced += pairs[stack.pop()]
    
    return balanced

if __name__ == "__main__":

    definition = \
    """
    (define (f x y)
        ,A
    )
    """
    logic_vars = [",A"]
    test_cases = [{"input": "'() '()", "output": "'()"}, {"input": "'(1 2 3) '(4 5 6)", "output": "'(1 2 3 4 5 6)"}]

    response = gen_solutions(definition, logic_vars, test_cases)

    if response:
        with open("corpus.scm", "w") as file:
            file.write(response)