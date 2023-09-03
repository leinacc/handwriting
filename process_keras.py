#!/usr/bin/env python3

import tensorflow as tf


model = tf.keras.models.load_model("model.keras")
wp = model.get_weight_paths()
# Multiply everything to convert floats to bytes
scale = 30
dk0 = wp["dense.kernel"] * scale
db0 = wp["dense.bias"] * scale
dk1 = wp["dense_1.kernel"] * scale
db1 = wp["dense_1.bias"] * scale


def float_to_hex_digits(f, digits):
    balance = 0x10 ** digits
    mid = balance // 2
    fmt = "${:0" + str(digits) + "x}"
    rounded = int(round(float(f)))
    if rounded >= 0:
        assert rounded < mid
        return fmt.format(rounded)
    assert rounded >= -mid, (rounded, -mid)
    return fmt.format(balance + rounded)

def list_out(prefix, floats):
    match prefix:
        case "db":
            digits = 2
        case "dw":
            digits = 4
        case "dl":
            digits = 6 # actually 8 in rgbds
        case _:
            raise Exception(f"Invalid prefix: {prefix}")
    entries = [float_to_hex_digits(f, digits) for f in floats]
    return f"\t{prefix} " + ", ".join(entries)

dk0_list = "\n".join(list_out("dw", row) for row in dk0)
dk1_list = "\n".join(list_out("db", row) for row in dk1)

asm_out = f"""HiddenLayerWeights:
{dk0_list}


HiddenLayerBias:
{list_out("dw", db0)}


OutputLayerWeights:
{dk1_list}


OutputLayerBias::
{list_out("dl", db1)}
"""

with open("res/model.asm", "w") as f:
    f.write(asm_out)
