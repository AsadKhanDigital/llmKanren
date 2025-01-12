import os
import re
import csv

# Regex patterns for times and calls
pattern_llm_time = re.compile(r"LLM call time \(ms\):\s*([\d\.]+)")
pattern_scheme_time = re.compile(r"Scheme logic time \(ms\):\s*([\d\.]+)")
pattern_total_time = re.compile(r"Total time \(ms\):\s*([\d\.]+)")
pattern_eval_calls = re.compile(r"Number of evalo calls:\s*(\d+)")
pattern_expert = re.compile(r"^Expert ordering version \(no LLM\)!", re.MULTILINE)

def parse_transcript(filepath):
    """
    Parse a single transcript file.
    Returns a dictionary with 'approach' ('LLM-based' or 'expert'),
    plus the times/calls. If missing info, returns None.
    """
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Determine approach
    approach = "LLM-based"
    if pattern_expert.search(content):
        approach = "expert"

    # Search for numeric patterns
    llm_match = pattern_llm_time.search(content)
    scheme_match = pattern_scheme_time.search(content)
    total_match = pattern_total_time.search(content)
    eval_match = pattern_eval_calls.search(content)

    if not (llm_match and scheme_match and total_match and eval_match):
        # If any piece is missing, skip
        return None

    return {
        "approach": approach,
        "llm_time": llm_match.group(1),
        "scheme_time": scheme_match.group(1),
        "total_time": total_match.group(1),
        "eval_calls": eval_match.group(1),
    }

def base_test_name(filename):
    """
    For something like output-1691178357.txt => 'output-1691178357'
    For output-1691178357-expert.txt => 'output-1691178357'
    """
    # Remove the extension .txt
    if filename.endswith(".txt"):
        filename = filename[:-4]  # remove .txt

    # If it ends with '-expert', remove that
    if filename.endswith("-expert"):
        filename = filename[:-7]  # remove '-expert'

    return filename

def main():
    # We'll parse all transcripts in run/
    run_dir = "run"
    # We'll group by the base test name
    # data_by_test[test_name] = {"LLM-based": {...}, "expert": {...}}
    data_by_test = {}

    for filename in os.listdir(run_dir):
        if filename.startswith("output-") and filename.endswith(".txt"):
            filepath = os.path.join(run_dir, filename)
            info = parse_transcript(filepath)
            if info:
                testname = base_test_name(filename)
                if testname not in data_by_test:
                    data_by_test[testname] = {}
                data_by_test[testname][info["approach"]] = info

    # Now write out a single CSV row per test name
    with open("results_comparison.csv", "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)

        # Write header with columns grouped in pairs
        # You can adapt the columns/labels as you want
        writer.writerow([
            "test_name",
            # LLM-based columns
            "llm_eval_calls",
            "llm_call_time_ms",
            "llm_scheme_time_ms",
            "llm_total_time_ms",
            # Expert columns
            "expert_eval_calls",
            "expert_llm_call_time_ms",
            "expert_scheme_time_ms",
            "expert_total_time_ms",
        ])

        for testname, info_dict in sorted(data_by_test.items()):
            llm_info = info_dict.get("LLM-based")
            exp_info = info_dict.get("expert")

            # It's possible one is missing if e.g. only an expert or only an LLM transcript was found
            if not (llm_info and exp_info):
                # skip or store partial?
                continue

            row = [
                testname,

                # LLM-based
                llm_info["eval_calls"],
                llm_info["llm_time"],
                llm_info["scheme_time"],
                llm_info["total_time"],

                # Expert
                exp_info["eval_calls"],
                exp_info["llm_time"],       # Yes, "llm_time" is ironically the 'LLM call time' for the expert approach (which is usually 0)
                exp_info["scheme_time"],
                exp_info["total_time"],
            ]
            writer.writerow(row)

    print("Wrote results_comparison.csv with combined LLM + expert data.")

if __name__ == "__main__":
    main()
