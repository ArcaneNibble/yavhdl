#!/usr/bin/env python3

import difflib
import json
import os
import os.path
import subprocess
import sys


def do_parser_tests():
    print("*" * 80)
    print("Running parser tests...")
    print("*" * 80)

    # Gather tests
    test_files = os.listdir("parser_tests")
    test_files_real = []
    test_files_set = set()
    for f in test_files:
        name, ext = os.path.basename(f).rsplit(".", 1)
        vhd_name = "parser_tests/" + name + ".vhd"
        json_name = "parser_tests/" + name + ".json"
        fail_name = "parser_tests/" + name + ".fail"
        if (os.path.isfile(vhd_name) and
            (os.path.isfile(json_name) or os.path.isfile(fail_name))):
            if os.path.isfile(json_name):
                this_test = (vhd_name, json_name, name)
            else:
                this_test = (vhd_name, None, name)
            if name not in test_files_set:
                print("Found test \"" + name + "\"")
                test_files_real.append(this_test)
                test_files_set.add(name)

    print("Found " + str(len(test_files_real)) + " tests")

    # Run each test
    failures = False
    for vhd_file, json_file, base_name in test_files_real:
        if json_file:
            print(base_name + ": ", end='')
        else:
            print(base_name + " (expect fail): ", end='')

        # Run parser
        subp = subprocess.run(['./vhdl_parser', vhd_file],
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE)

        if json_file:
            # Load reference
            with open(json_file, 'r') as inf:
                reference = json.load(inf)

            if subp.returncode != 0:
                failures = True
                print("\x1b[31m✗")
                print("Executing parser failed!\x1b[0m")
                print("\x1b[33m----- stdout -----\x1b[0m")
                sys.stdout.buffer.write(subp.stdout)
                print("\x1b[33m----- stderr -----\x1b[0m")
                sys.stdout.buffer.write(subp.stderr)
                continue

            # Load parser result
            try:
                prog_output = json.loads(subp.stdout.decode('ascii'))
            except:
                failures = True
                print("\x1b[31m✗")
                print("Bad parser output!\x1b[0m")
                print("\x1b[33m----- stdout -----\x1b[0m")
                sys.stdout.buffer.write(subp.stdout)
                print("\x1b[33m----- stderr -----\x1b[0m")
                sys.stdout.buffer.write(subp.stderr)
                continue

            # Compare
            if prog_output != reference:
                failures = True
                print("\x1b[31m✗")
                print("Test output mismatch!\x1b[0m")
                # Re-encode in sorted order for proper diffing
                ref_json = json.dumps(reference, indent=4,
                                      separators=(',', ': '), sort_keys=True)
                out_json = json.dumps(prog_output, indent=4,
                                      separators=(',', ': '), sort_keys=True)
                print("\x1b[33m----- expected -----\x1b[0m")
                print(ref_json)
                print("\x1b[33m----- actual -----\x1b[0m")
                print(out_json)
                print("\x1b[33m----- diff -----\x1b[0m")
                udiff = difflib.unified_diff(ref_json.split('\n'),
                                             out_json.split('\n'),
                                             fromfile="expected_output",
                                             tofile="parser_output",
                                             lineterm='')
                print('\n'.join(udiff))
            else:
                print("\x1b[32m✓\x1b[0m")
        else:
            # Expect failure
            if subp.returncode == 0:
                failures = True
                print("\x1b[31m✗")
                print("Executing parser succeeded when it should not!\x1b[0m")
                print("\x1b[33m----- stdout -----\x1b[0m")
                sys.stdout.buffer.write(subp.stdout)
                print("\x1b[33m----- stderr -----\x1b[0m")
                sys.stdout.buffer.write(subp.stderr)
                continue

            print("\x1b[32m✓\x1b[0m")

    return failures


def main():
    # I have been burned too many times by this flakiness, so we first set our
    # CWD to "definitely where this file is" which also must be in the root
    # of the repo
    os.chdir(os.path.dirname(__file__))

    failures = False
    failures = failures or do_parser_tests()

    if failures:
        sys.exit(1)

if __name__ == '__main__':
    main()
