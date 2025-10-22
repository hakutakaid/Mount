import glob
import re

# Ambil semua file lua dengan urutan angka (0.lua, 1.lua, dst)
files = sorted(glob.glob("*.lua"), key=lambda x: int(re.findall(r'\d+', x)[0]))

output_lines = []

for file in files:
    with open(file, "r", encoding="utf-8") as f:
        content = f.read().strip()

        # Ambil isi di antara return { ... }
        match = re.search(r"return\s*{(.*)}", content, re.DOTALL)
        if match:
            inner = match.group(1).strip()
            if inner.endswith(","):
                inner = inner[:-1]
            output_lines.append(inner)

# Gabungkan semua
merged = "return {\n\t" + ",\n\t".join(output_lines) + ",\n}"

# Simpan ke file baru
with open("merged.lua", "w", encoding="utf-8") as f:
    f.write(merged)

print("✅ File merged.lua berhasil dibuat!")