#!/usr/bin/env python3
import re
from pathlib import Path
from collections import Counter

tex = Path("virtualized-nac-incident-validation.tex").read_text()

label_pat = re.compile(r'\\label\{([^}]+)\}')
ref_pat = re.compile(r'\\(?:ref|autoref|nameref)\{([^}]+)\}')

labels = label_pat.findall(tex)
refs = ref_pat.findall(tex)

label_set = set(labels)
ref_set = set(refs)

missing_targets = sorted(r for r in ref_set if r not in label_set)
unused_labels = sorted(l for l in label_set if l not in ref_set)

print("=== LABEL/REF AUDIT ===")
print(f"Labels defined: {len(labels)}")
print(f"Refs used:      {len(refs)}")
print()

print("Missing targets:")
for x in missing_targets:
    print(f"  {x}")

print()
print("Possibly unused labels:")
for x in unused_labels:
    print(f"  {x}")
