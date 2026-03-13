import struct
def split_fp32(x):
    b = struct.pack('f', x)
    u = struct.unpack('I', b)[0]
    exp = (u >> 23) & 0xFF
    mant = u & 0x7FFFFF
    if exp != 0:
        mant = mant | 0x800000
    return (u >> 31) & 1, exp, mant

def fp32_bit(x):
    b = struct.pack('f', x)
    u = struct.unpack('I', b)[0]
    return u


# 调用
s0, e0, m0 = split_fp32(1.0)

# 输出
print(f"0x{s0:X}")  # 符号位 0/1
print(f"0x{e0:02X}")  # 8位指数（十进制）
print(f"0x{m0:06X}")  # 23位尾数（十进制）

# 调用
s1, e1, m1 = split_fp32(2.5)

# 输出
print(f"0x{s1:X}")  # 符号位 0/1
print(f"0x{e1:02X}")  # 8位指数（十进制）
print(f"0x{m1:06X}")  # 23位尾数（十进制）


# 调用
s2, e2, m2 = split_fp32(3.5)
bit2 = fp32_bit(3.5)
# 输出
print(f"0x{s2:X}")  # 符号位 0/1
print(f"0x{e2:02X}")  # 8位指数（十进制）
print(f"0x{m2:06X}")  # 23位尾数（十进制）
print(f"0x{bit2:08X}")  # 23位尾数（十进制）

