# Example: LaTeX Math in Obsidian → Pandoc → DOCX

This document demonstrates various LaTeX equations that will be preserved
as plain text for MathType Toggle TeX.

## Inline Math

The quadratic formula $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$ solves $ax^2 + bx + c = 0$.

A dot product: $\mathbf{a} \cdot \mathbf{b} = \sum_{i=1}^{n} a_i b_i$.

Greek letters: $\alpha$, $\beta$, $\gamma$, $\Delta$, $\Theta$, $\Omega$.

Operators: $\sin^2 x + \cos^2 x = 1$, $\exp\left(-\frac{x^2}{2}\right)$, $\ln x$.

## Display Math

The Gaussian integral:

$$
\int_{-\infty}^{\infty} e^{-x^2} \, dx = \sqrt{\pi}
$$

A multi-line aligned equation:

$$
\begin{aligned}
\nabla \times \mathbf{E} &= -\frac{\partial \mathbf{B}}{\partial t} \\
\nabla \times \mathbf{H} &= \mathbf{J} + \frac{\partial \mathbf{D}}{\partial t}
\end{aligned}
$$

The definition of the Laplace transform:

$$
\mathcal{L}\{f(t)\} = F(s) = \int_0^{\infty} e^{-st} f(t) \, dt
$$

## Matrix

A $2 \times 2$ rotation matrix:

$$
\mathbf{R}(\theta) =
\begin{bmatrix}
\cos\theta & -\sin\theta \\
\sin\theta &  \cos\theta
\end{bmatrix}
$$

## Piecewise

The Heaviside step function:

$$
H(x) =
\begin{cases}
0, & x < 0 \\
1, & x \geq 0
\end{cases}
$$

## Chemical Notation (via LaTeX)

Water: $\mathrm{H_2O}$, sulfate ion: $\mathrm{SO_4^{2-}}$.

## Mixed Text and Math

According to Newton's second law, $\mathbf{F} = m\mathbf{a}$, the acceleration
of an object is directly proportional to the net force acting on it.

---

*Written in Obsidian · Exported via Pandoc · Processed with MathType Toggle TeX*
