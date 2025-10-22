import sys
import os
import re
import random

def hapus_duplikat_cframe(filepath):
    if not os.path.exists(filepath):
        print(f"❌ File '{filepath}' tidak ditemukan.")
        return

    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    cframes = []
    for line in lines:
        if "CFrame.new(" in line:
            cframes.append(line.strip())

    unique = {}
    for line in cframes:
        # Ambil nilai X pertama di CFrame.new(
        match = re.search(r"CFrame\.new\(\s*(-?\d+\.\d+)", line)
        if match:
            x_value = match.group(1).strip()
            unique[x_value] = line  # Simpan baris terakhir untuk X itu

    # Buat nama file acak
    random_name = f"result_{random.randint(1000, 9999)}.lua"

    with open(random_name, "w", encoding="utf-8") as f:
        f.write("return {\n")
        for line in unique.values():
            # 1️⃣ Hilangkan semua koma, spasi, atau tab di akhir baris
            clean_line = re.sub(r"[, \t]+$", "", line)
            # 2️⃣ Pastikan hanya tambahkan dua koma di akhir
            f.write(f"\t{clean_line},,\n")
        f.write("}\n")

    print(f"✅ Duplikat berdasarkan X dihapus & koma sudah dibersihkan total.")
    print(f"💾 Hasil disimpan di: {random_name}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("⚠️  Pemakaian: python3 dup.py <nama_file.lua>")
    else:
        hapus_duplikat_cframe(sys.argv[1])