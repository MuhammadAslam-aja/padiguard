def is_green_rice_leaf(r, g, b):
    # Real rice plant leaves: Vibrant green, g significantly higher than r and b
    # Painted room wall / pale curtain: g is close to r and b
    return (g > r + 12) and (g > b + 25) and (g > 45) and (b < 150)

print('Real Rice Leaf (R=50, G=120, B=40):', is_green_rice_leaf(50, 120, 40))
print('Painted Green Wall (R=120, G=140, B=120):', is_green_rice_leaf(120, 140, 120))
print('Light Lime Wall (R=140, G=165, B=140):', is_green_rice_leaf(140, 165, 140))
