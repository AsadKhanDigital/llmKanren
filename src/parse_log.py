#!/usr/bin/env python3
import re
import csv
import argparse
import sys

def parse_log_file(log_file_path):
    """Parse the log file and extract test case data"""
    with open(log_file_path, 'r') as file:
        content = file.read()
    
    # Split content by test cases
    test_case_pattern = r"----------------------------------------\nTest Case: ([a-zA-Z0-9-]+)\n----------------------------------------"
    test_cases = re.split(test_case_pattern, content)
    
    # First element is empty, then we have pairs of (test_name, test_content)
    results = []
    for i in range(1, len(test_cases), 2):
        test_name = test_cases[i]
        test_content = test_cases[i+1]
        
        # Create a dictionary to hold this test case's data
        test_data = {"test_case": test_name}
        
        # Extract Expert data
        expert_match = re.search(r"----------------------------------------\nExpert\n----------------------------------------.*?Inc-count: (\d+).*?Evalo-count: (\d+).*?(\d+\.\d+)s elapsed cpu time", 
                                test_content, re.DOTALL)
        if expert_match:
            test_data["expert"] = {
                "inc_count": expert_match.group(1),
                "evalo_count": expert_match.group(2),
                "mk_time": expert_match.group(3)
            }
        
        # Extract Zinkov 2-gram data
        zinkov_2_match = re.search(r"----------------------------------------\nZinkov \(n=2\)\n----------------------------------------.*?Inc-count: (\d+).*?Evalo-count: (\d+).*?(\d+\.\d+)s elapsed cpu time", 
                                  test_content, re.DOTALL)
        if zinkov_2_match:
            test_data["zinkov_2"] = {
                "inc_count": zinkov_2_match.group(1),
                "evalo_count": zinkov_2_match.group(2),
                "mk_time": zinkov_2_match.group(3)
            }
        
        # Extract Zinkov 3-gram data
        zinkov_3_match = re.search(r"----------------------------------------\nZinkov \(n=3\)\n----------------------------------------.*?Inc-count: (\d+).*?Evalo-count: (\d+).*?(\d+\.\d+)s elapsed cpu time", 
                                  test_content, re.DOTALL)
        if zinkov_3_match:
            test_data["zinkov_3"] = {
                "inc_count": zinkov_3_match.group(1),
                "evalo_count": zinkov_3_match.group(2),
                "mk_time": zinkov_3_match.group(3)
            }
        
        # Extract LLM 2-gram data
        llm_2_match = re.search(r"----------------------------------------\nLLM \(n=2\)\n----------------------------------------.*?system \(apply string-append.*?(\d+\.\d+)s elapsed real time.*?Inc-count: (\d+).*?Evalo-count: (\d+).*?(\d+\.\d+)s elapsed cpu time", 
                               test_content, re.DOTALL)
        if llm_2_match:
            test_data["llm_2"] = {
                "llm_time": llm_2_match.group(1),
                "inc_count": llm_2_match.group(2),
                "evalo_count": llm_2_match.group(3),
                "mk_time": llm_2_match.group(4)
            }
        
        # Extract LLM 3-gram data
        llm_3_match = re.search(r"----------------------------------------\nLLM \(n=3\)\n----------------------------------------.*?system \(apply string-append.*?(\d+\.\d+)s elapsed real time.*?Inc-count: (\d+).*?Evalo-count: (\d+).*?(\d+\.\d+)s elapsed cpu time", 
                               test_content, re.DOTALL)
        if llm_3_match:
            test_data["llm_3"] = {
                "llm_time": llm_3_match.group(1),
                "inc_count": llm_3_match.group(2),
                "evalo_count": llm_3_match.group(3),
                "mk_time": llm_3_match.group(4)
            }
        
        # Extract LLM 4-gram data
        llm_4_match = re.search(r"----------------------------------------\nLLM \(n=4\)\n----------------------------------------.*?system \(apply string-append.*?(\d+\.\d+)s elapsed real time.*?Inc-count: (\d+).*?Evalo-count: (\d+).*?(\d+\.\d+)s elapsed cpu time", 
                               test_content, re.DOTALL)
        if llm_4_match:
            test_data["llm_4"] = {
                "llm_time": llm_4_match.group(1),
                "inc_count": llm_4_match.group(2),
                "evalo_count": llm_4_match.group(3),
                "mk_time": llm_4_match.group(4)
            }
        
        results.append(test_data)
    
    return results

def write_csv(results, output_file):
    """Write results to a CSV file"""
    headers = [
        "Test Case", 
        "Expert", 
        "2-gram Zinkov",
        "3-gram Zinkov",
        "2-gram LLM",
        "3-gram LLM",
        "4-gram LLM"
    ]
    
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        
        for result in results:
            row = [result["test_case"]]
            
            # Expert
            if "expert" in result:
                expert_data = result["expert"]
                row.append(f"inc_count: {expert_data['inc_count']}\nevalo_count: {expert_data['evalo_count']}\nmk_time: {expert_data['mk_time']}s")
            else:
                row.append("N/A")
            
            # Zinkov 2-gram
            if "zinkov_2" in result:
                zinkov_2_data = result["zinkov_2"]
                row.append(f"inc_count: {zinkov_2_data['inc_count']}\nevalo_count: {zinkov_2_data['evalo_count']}\nmk_time: {zinkov_2_data['mk_time']}s")
            else:
                row.append("N/A")
            
            # Zinkov 3-gram
            if "zinkov_3" in result:
                zinkov_3_data = result["zinkov_3"]
                row.append(f"inc_count: {zinkov_3_data['inc_count']}\nevalo_count: {zinkov_3_data['evalo_count']}\nmk_time: {zinkov_3_data['mk_time']}s")
            else:
                row.append("N/A")
            
            # LLM 2-gram
            if "llm_2" in result:
                llm_2_data = result["llm_2"]
                row.append(f"inc_count: {llm_2_data['inc_count']}\nevalo_count: {llm_2_data['evalo_count']}\nllm_time: {llm_2_data['llm_time']}s\nmk_time: {llm_2_data['mk_time']}s")
            else:
                row.append("N/A")
            
            # LLM 3-gram
            if "llm_3" in result:
                llm_3_data = result["llm_3"]
                row.append(f"inc_count: {llm_3_data['inc_count']}\nevalo_count: {llm_3_data['evalo_count']}\nllm_time: {llm_3_data['llm_time']}s\nmk_time: {llm_3_data['mk_time']}s")
            else:
                row.append("N/A")
            
            # LLM 4-gram
            if "llm_4" in result:
                llm_4_data = result["llm_4"]
                row.append(f"inc_count: {llm_4_data['inc_count']}\nevalo_count: {llm_4_data['evalo_count']}\nllm_time: {llm_4_data['llm_time']}s\nmk_time: {llm_4_data['mk_time']}s")
            else:
                row.append("N/A")
            
            writer.writerow(row)

def main():
    parser = argparse.ArgumentParser(description='Parse minikanren test output log and generate CSV report')
    parser.add_argument('log_file', help='Path to the log file')
    parser.add_argument('-o', '--output', default='output.csv', help='Output CSV file name (default: output.csv)')
    args = parser.parse_args()
    
    try:
        results = parse_log_file(args.log_file)
        write_csv(results, args.output)
        print(f"CSV report successfully generated: {args.output}")
    except Exception as e:
        print(f"Error processing log file: {e}", file=sys.stderr)
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())