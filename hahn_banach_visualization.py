import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon

# Configuración inicial
fig, ax = plt.subplots(figsize=(10, 8))
plt.title(
    "Teorema de Hahn-Banach: Extensión de un Funcional Lineal",
    pad=20,
    fontsize=14,
    fontweight="bold",
)

# Espacio X (R^2)
ax.set_xlim(-4, 4)
ax.set_ylim(-4, 4)
ax.axhline(0, color="black", linewidth=0.5)
ax.axvline(0, color="black", linewidth=0.5)
ax.set_xlabel("$x_1$", fontsize=12)
ax.set_ylabel("$x_2$", fontsize=12)
ax.grid(True, linestyle="--", alpha=0.5)

# 1. Subespacio Z (eje x1)
Z_x = np.linspace(-3, 3, 100)
Z_y = np.zeros_like(Z_x)
ax.plot(Z_x, Z_y, "b-", linewidth=3, label="$Z$ (Subespacio donde $f$ está definido)")

# 2. Funcional f en Z (f(x1) = 2x1)
f_values = 2 * Z_x
ax.quiver(
    Z_x,
    Z_y,
    np.zeros_like(Z_x),
    f_values,
    color="green",
    scale=20,
    width=0.005,
    label="$f(x_1)$",
)

# 3. Funcional sublineal p (norma l1: |x1| + |x2|)
x = np.array([-3, 0, 3])
y_p = np.array([3, 0, 3])  # p(x,0) = |x|
ax.plot(x, y_p, "r--", label="$p(x)$ (Frontera superior)")
ax.plot(x, -y_p, "r--")  # Parte inferior

# Rellenar área de dominación
# Crear correctamente los vértices para el polígono
vertices = np.array(
    list(zip(np.concatenate([x, x[::-1]]), np.concatenate([y_p, -y_p[::-1]])))
)
polygon = Polygon(vertices, alpha=0.2, color="red")
ax.add_patch(polygon)

# 4. Extensión \tilde{f} (ejemplo: \tilde{f}(x1,x2) = 2x1 + 0x2)
X, Y = np.meshgrid(np.linspace(-3, 3, 5), np.linspace(-3, 3, 5))
U = np.zeros_like(X)
V = 2 * X + 0 * Y  # Mantiene la linealidad y dominación p
ax.quiver(
    X,
    Y,
    U,
    V,
    color="orange",
    scale=20,
    width=0.005,
    label="$\tilde{f}$ (Extensión a $X$)",
)

# Leyenda y anotaciones
ax.legend(loc="upper right", fontsize=10)
ax.text(0.5, -0.5, r"$\tilde{f}|_Z = f$", fontsize=12, color="purple")
ax.text(2.5, 2.8, r"$p(x) = \|x\|_1$", fontsize=12, color="red")
ax.text(-3.5, 1.5, r"$\tilde{f}(x) \leq p(x)$", fontsize=12, color="purple")

# Destacar propiedades
props = dict(boxstyle="round", facecolor="white", alpha=0.8)
ax.text(
    -4,
    3.5,
    r"1. $p$ es sublineal:"
    "\n"
    r"   - $p(x+y) \leq p(x) + p(y)$"
    "\n"
    r"   - $p(\alpha x) = \alpha p(x)$ ($\alpha \geq 0$)",
    fontsize=10,
    bbox=props,
)

plt.tight_layout()
plt.savefig("hahn_banach_extension.png", dpi=300)
plt.show()
input("Press Enter to close the plot...")  # Keeps console window open
