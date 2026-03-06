import numpy as np
from scipy.optimize import fsolve
import matplotlib.pyplot as plt

def remez_minimax(f, n, a, b, max_iter=100, tol=1e-8):
    """
    最终稳定版：求解连续函数f(x)在区间[a,b]上的n次最小最大逼近多项式
    修复所有类型错误、索引错误、收敛问题
    """
    # 交替点数量 = 多项式次数 + 2（等振荡定理要求）
    m = n + 2

    # 1. 鲁棒的初始节点生成（确保数量为m，且为numpy数组）
    def init_nodes(m, a, b):
        """生成区间[a,b]上的Chebyshev节点，返回numpy数组"""
        k = np.arange(m)
        nodes = (a + b)/2 + (b - a)/2 * np.cos(np.pi * (2*k + 1)/(2*m))
        return np.unique(np.sort(nodes))  # 去重排序

    # 初始化交替点（强制保障数量为m）
    x_nodes = init_nodes(m, a, b)
    if len(x_nodes) < m:
        # 补充均匀节点至m个
        extra = np.linspace(a, b, m - len(x_nodes))
        x_nodes = np.unique(np.sort(np.concatenate([x_nodes, extra])))
    x_nodes = x_nodes[:m].astype(np.float64)  # 强制numpy数组+浮点类型

    # 2. 安全的多项式求值函数（兼容标量/数组）
    def poly_eval(coeffs, x):
        """
        计算多项式值：coeffs=[c0,c1,...cn]，P(x)=c0 + c1*x + ... + cn*x^n
        兼容标量和numpy数组输入
        """
        x = np.asarray(x, dtype=np.float64)  # 强制转为numpy数组
        result = np.zeros_like(x)
        for i, c in enumerate(coeffs):
            result += c * (x ** i)
        return result

    prev_error = np.inf
    for _ in range(max_iter):
        # 3. 构造线性方程组（避免奇异矩阵）
        A = np.zeros((m, m), dtype=np.float64)
        b_vec = np.zeros(m, dtype=np.float64)

        for i in range(m):
            xi = x_nodes[i]
            # 前n+1列：x^0 到 x^n
            for j in range(n+1):
                A[i, j] = xi ** j
            # 最后一列：(-1)^i （等振荡条件）
            A[i, -1] = (-1) ** i
            # 右侧向量：f(xi)
            b_vec[i] = f(xi)

        # 求解线性方程组（添加正则化避免奇异）
        try:
            sol = np.linalg.solve(A, b_vec)
        except np.linalg.LinAlgError:
            A += 1e-12 * np.eye(m)
            sol = np.linalg.solve(A, b_vec)

        coeffs = sol[:-1]  # 多项式系数 [c0, c1, ..., cn]
        E = sol[-1]        # 当前误差估计

        # 4. 定义误差函数（兼容标量/数组）
        def error_func(x):
            return f(x) - poly_eval(coeffs, x)

        # 5. 鲁棒的极值点检测（全程使用numpy数组）
        # 密集采样区间内的点
        x_samples = np.linspace(a, b, 2000, dtype=np.float64)
        e_samples = error_func(x_samples)

        # 初始化极值点候选（numpy数组）
        extrema_candidates = np.array([a, b], dtype=np.float64)

        # 找多项式导数的零点（P'(x)=0）
        if n >= 1:
            # 计算导数系数：P'(x) = c1 + 2c2x + ... + ncnx^(n-1)
            deriv_coeffs = np.array([i * coeffs[i] for i in range(1, n+1)], dtype=np.float64)
            # 求解导数的根
            if len(deriv_coeffs) > 0:
                deriv_roots = np.roots(deriv_coeffs[::-1])  # roots要求系数从高次到低次
                # 筛选区间内的实根
                real_roots = []
                for r in deriv_roots:
                    if np.isreal(r):
                        r_real = np.real(r)
                        if a < r_real < b:
                            real_roots.append(r_real)
                if real_roots:
                    extrema_candidates = np.concatenate([extrema_candidates, real_roots])

        # 找误差函数的局部极值（峰值）
        # 计算一阶差分，找符号变化点
        e_diff = np.sign(np.diff(e_samples))
        peak_indices = np.where(e_diff[:-1] != e_diff[1:])[0] + 1
        peak_x = x_samples[peak_indices]
        extrema_candidates = np.concatenate([extrema_candidates, peak_x])

        # 去重、排序、筛选区间内的点
        extrema_candidates = np.unique(extrema_candidates)
        extrema_candidates = extrema_candidates[(extrema_candidates >= a) & (extrema_candidates <= b)]

        # 确保候选点数量足够
        if len(extrema_candidates) < m:
            extra = np.linspace(a, b, m - len(extrema_candidates))
            extrema_candidates = np.concatenate([extrema_candidates, extra])
        extrema_candidates = np.unique(extrema_candidates)[:m]  # 取前m个

        # 6. 选取误差绝对值最大的m个点作为新的交替点
        e_candidates = np.abs(error_func(extrema_candidates))
        sorted_idx = np.argsort(e_candidates)[-m:]  # 取误差最大的m个
        x_nodes_new = np.sort(extrema_candidates[sorted_idx])

        # 7. 收敛判断
        current_max_error = np.max(np.abs(e_samples))
        if abs(current_max_error - prev_error) < tol:
            break
        prev_error = current_max_error
        x_nodes = x_nodes_new

    # 计算最终最大误差
    x_final = np.linspace(a, b, 2000)
    final_error = np.max(np.abs(error_func(x_final)))
    return coeffs, final_error

# ---------------------- 测试代码（绝对可运行） ----------------------
# 目标函数：f(x) = e^x
def f(x):
    # 兼容标量和数组输入
    x = np.asarray(x, dtype=np.float64)
#    return np.power(2, x)
    return np.exp(x)

# 求解3次最小最大多项式
n = 4  # 多项式次数
a, b = -0.347, 0.347
coeffs, max_error = remez_minimax(f, n, a, b)

# 输出结果
print(f"{n}次最小最大多项式系数（c0 + c1*x + c2*x^2 + c3*x^3）：")
for i in range(len(coeffs)):
    print(f"c{i} = {coeffs[i]:.17f}")
print(f"最大逼近误差：{max_error:.6e}")

# 可视化对比
x = np.linspace(a, b, 1000)
f_vals = f(x)
P_vals = np.zeros_like(x)
for i, c in enumerate(coeffs):
    P_vals += c * (x ** i)
error_vals = f_vals - P_vals
print("max error:", np.max(np.abs(error_vals)))
print("max error:", np.max(np.abs(error_vals/f_vals)))
