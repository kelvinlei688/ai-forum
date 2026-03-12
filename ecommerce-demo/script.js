// 商品数据
const products = [
    {
        id: 1,
        name: "AirPods Pro 无线耳机",
        description: "主动降噪，空间音频，超长续航",
        price: 1299,
        image: "🎧",
        category: "数码"
    },
    {
        id: 2,
        name: "iPhone 15 Pro Max",
        description: "钛金属边框，A17 Pro 芯片",
        price: 9999,
        image: "📱",
        category: "数码"
    },
    {
        id: 3,
        name: "MacBook Air M2",
        description: "超薄设计，全天候续航",
        price: 8999,
        image: "💻",
        category: "数码"
    },
    {
        id: 4,
        name: "Apple Watch Ultra",
        description: "专业运动，更长续航",
        price: 6499,
        image: "⌚",
        category: "数码"
    },
    {
        id: 5,
        name: "Nike Air Jordan",
        description: "经典运动鞋，限量配色",
        price: 899,
        image: "👟",
        category: "服饰"
    },
    {
        id: 6,
        name: "雷蛇电竞鼠标",
        description: "RGB灯效，高精度传感器",
        price: 399,
        image: "🖱️",
        category: "数码"
    },
    {
        id: 7,
        name: "机械键盘 红轴",
        description: "热插拔，RGB背光",
        price: 499,
        image: "⌨️",
        category: "数码"
    },
    {
        id: 8,
        name: "男士商务风衣",
        description: "优质面料，修身剪裁",
        price: 599,
        image: "🧥",
        category: "服饰"
    },
    {
        id: 9,
        name: "4K 27寸 显示器",
        description: "IPS面板，高色域，144Hz",
        price: 1599,
        image: "🖥️",
        category: "数码"
    },
    {
        id: 10,
        name: "无线充电板",
        description: "MagSafe 快充，15W",
        price: 199,
        image: "🔋",
        category: "数码"
    }
];

// 购物车
let cart = [];

// DOM 加载完成
document.addEventListener('DOMContentLoaded', () => {
    renderProducts();
    setupEventListeners();
});

// 渲染商品
function renderProducts() {
    const grid = document.getElementById('productsGrid');
    grid.innerHTML = products.map(product => `
        <div class="product-card">
            <div class="product-image">${product.image}</div>
            <div class="product-info">
                <h3 class="product-title">${product.name}</h3>
                <p class="product-description">${product.description}</p>
                <div class="product-footer">
                    <span class="product-price">¥${product.price}</span>
                    <button class="add-to-cart" onclick="addToCart(${product.id})">加入购物车</button>
                </div>
            </div>
        </div>
    `).join('');
}

// 添加到购物车
function addCart(productId) {
    return addToCart(productId);
}

function addToCart(productId) {
    const product = products.find(p => p.id === productId);
    const existing = cart.find(item => item.id === productId);
    
    if (existing) {
        existing.quantity += 1;
    } else {
        cart.push({...product, quantity: 1});
    }
    
    updateCartUI();
    alert('已加入购物车！');
}

// 从购物车移除
function removeFromCart(productId) {
    cart = cart.filter(item => item.id !== productId);
    updateCartUI();
}

// 更新购物车UI
function updateCartUI() {
    const cartCount = document.getElementById('cartCount');
    const cartItems = document.getElementById('cartItems');
    const cartTotal = document.getElementById('cartTotal');
    
    // 总数
    const totalItems = cart.reduce((sum, item) => sum + item.quantity, 0);
    cartCount.textContent = totalItems;
    
    // 购物车列表
    if (cart.length === 0) {
        cartItems.innerHTML = '<div class="empty-cart">购物车还是空的哦 🛒</div>';
    } else {
        cartItems.innerHTML = cart.map(item => `
            <div class="cart-item">
                <div class="cart-item-info">
                    <h4>${item.name}</h4>
                    <div>
                        <span class="cart-item-price">¥${item.price} x ${item.quantity}</span>
                    </div>
                </div>
                <button class="remove-item" onclick="removeFromCart(${item.id})">删除</button>
            </div>
        `).join('');
    }
    
    // 总价
    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    cartTotal.textContent = `¥${total.toFixed(2)}`;
}

// 设置事件监听
function setupEventListeners() {
    const modal = document.getElementById('cartModal');
    const cartBtn = document.getElementById('cartBtn');
    const closeBtn = document.getElementById('closeModal');
    
    cartBtn.addEventListener('click', () => {
        modal.classList.add('active');
    });
    
    closeBtn.addEventListener('click', () => {
        modal.classList.remove('active');
    });
    
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            modal.classList.remove('active');
        }
    });
}

// 滚动到商品
function scrollToProducts() {
    document.getElementById('products').scrollIntoView({ behavior: 'smooth' });
}

// 结算
function checkout() {
    if (cart.length === 0) {
        alert('购物车是空的！');
        return;
    }
    
    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    alert(`感谢购买！\n总金额: ¥${total.toFixed(2)}\n这是演示网站，不会真的扣款 😊`);
    cart = [];
    updateCartUI();
    document.getElementById('cartModal').classList.remove('active');
}

// 让外部可以访问
window.addToCart = addToCart;
window.removeFromCart = removeFromCart;
window.scrollToProducts = scrollToProducts;
window.checkout = checkout;
