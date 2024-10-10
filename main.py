import subprocess
import ollama
import json
import os

from collections import defaultdict
from dotenv import load_dotenv
from openai import OpenAI


load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def generate_mk_query():
    # context = \
    # """
    # Using only relations found in the following minikanren implementation in Racket:

    # {mk}

    # \n

    # \n
    # """.format(mk=open(minikanren_file).read())


    
    prompt = """Generate a relatively simple Minikanren (run*) query in Scheme. \
        Do not add any other text whatsoever. \
            Do not include any other text or markdown tags or code blocks or formatting."""

    try:
        response = client.chat.completions.create(model="gpt-4",
        messages=[{"role": "user", "content": prompt}],
        # max_tokens=200,
        n=1,
        temperature=0.9)
        query = response.choices[0].message.content.strip()
        return query
    except Exception as e:
        print(f"Error generating query: {e}")
        return None

def generate_minikanren_queries(num_queries):
    queries = []
    for _ in range(num_queries):
        query = generate_mk_query()
        if query:
            queries.append(query)
    return queries

def write_racket_file(query, filepath):
    with open(filepath, 'w') as f:
        f.write("#lang racket\n\n")
        f.write("(require \"../../mk.rkt\")\n\n")
        f.write(query + '\n')

def run_racket_query(filepath):
    try:
        output = subprocess.check_output(["racket", filepath], stderr=subprocess.STDOUT)
        return output.decode("utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Error running racket query: {e}")
        return None

def predict_output(query):
    prompt = f"""
    You are an expert at running miniKanren queries in Racket. \n

    You have a good understanding of the following miniKanren implementation: \n

    {open("mk.rkt").read()} \n

    Given the following Minikanren query in Racket: \n

    {query} \n

    What is one possible output in the stream when calling the run function on this query as it would be if it were run as a program? \n

    Do not include any other text or formatting.
    """

    try:
        response = ollama.generate(
            model='llama3.2:3b-instruct-fp16',
            prompt=prompt,
            options=ollama.Options(
                num_ctx=128000,
                temperature=0.9
            )
        )

        return response['response']
    except Exception as e:
        print(f"Error predicting output: {e}")
        return None

def save_real_output(file_path, idx, real_output):
    with open(f"{file_path}/real_output_{idx}.txt", 'w') as f:
        f.write(real_output)

def save_histogram(file_path, idx, output_histogram):
    with open(f"{file_path}/histogram_{idx}.json", 'w') as f:
        json.dump(output_histogram, f, indent=2)

if __name__ == "__main__":

    # Create a new directory called run to store output files
    os.makedirs("run", exist_ok=True)

    num_queries = 1
    queries = generate_minikanren_queries(num_queries)
    query_counter = 0

    # Create a directory in run for storing query output
    os.makedirs("run/query_output", exist_ok=True)

    # Create a directory in run for storing query run output
    os.makedirs("run/query_run_output", exist_ok=True)

    #Create a directory in run for storing histograms
    os.makedirs("run/histograms", exist_ok=True)

    for idx, query in enumerate(queries):
        filepath = f"run/query_output/query_{idx}.rkt"
        write_racket_file(query, filepath)

        try:
            real_output = run_racket_query(filepath)
        except SyntaxError as e:
            print(f"Query {idx} will be discarded.")
            os.remove(filepath)
            continue

        save_real_output("run/query_run_output", idx, real_output)

        # output_histogram = defaultdict(int)

        # for _ in range(10):
        #     predicted_output = predict_output(query)
            
        #     if predict_output is None:
        #         continue

        #     output_histogram[predicted_output] += 1
        
        # save_histogram("run/histograms", idx, output_histogram)

        # query_counter += 1

        

