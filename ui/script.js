let currentListings = [];
let currentBuyOrders = [];
let currentHistory = [];
let currentPickups = [];
let inventoryItems = [];

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
    setupAutoRefresh();
});

// Setup event listeners
function setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const tab = btn.dataset.tab;
            switchTab(tab);
        });
    });

    // Close button
    document.getElementById('closeBtn').addEventListener('click', () => {
        closeMarketplace();
    });

    // ESC key to close
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeMarketplace();
        }
    });

    // Search functionality
    document.getElementById('listingsSearch').addEventListener('input', (e) => {
        filterListings(e.target.value);
    });

    document.getElementById('ordersSearch').addEventListener('input', (e) => {
        filterBuyOrders(e.target.value);
    });

    // Check if pickupsSearch exists before adding event listener
    const pickupsSearch = document.getElementById('pickupsSearch');
    if (pickupsSearch) {
        pickupsSearch.addEventListener('input', (e) => {
            filterPickups(e.target.value);
        });
    }

    // Sell form
    document.getElementById('sellBtn').addEventListener('click', () => {
        handleSellItem();
    });

    // Create order form
    document.getElementById('orderBtn').addEventListener('click', () => {
        handleCreateBuyOrder();
    });

    // Order total calculation
    const orderQuantity = document.getElementById('orderQuantity');
    const orderPrice = document.getElementById('orderPrice');
    orderQuantity.addEventListener('input', updateOrderTotal);
    orderPrice.addEventListener('input', updateOrderTotal);
    
    // Item selection for selling
    const sellItemSelect = document.getElementById('sellItemSelect');
    sellItemSelect.addEventListener('change', function() {
        updateSellItemQuantity();
    });

    // History filters
    document.getElementById('applyHistoryFilter').addEventListener('click', () => {
        applyHistoryFilters();
    });
}

// Switch tabs
function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.tab === tabName) {
            btn.classList.add('active');
        }
    });

    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });

    const targetTab = document.getElementById(`${tabName}-tab`);
    if (targetTab) {
        targetTab.classList.add('active');
    }

    // Refresh data when switching to certain tabs
    if (tabName === 'listings' || tabName === 'buy-orders') {
        fetch('https://' + GetParentResourceName() + '/requestRefresh', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
}

// Get parent resource name (FiveM NUI)
// In FiveM NUI, GetParentResourceName is a native function
// We'll use a cached value to avoid issues
const RESOURCE_NAME = 'ns-market';

function GetParentResourceName() {
    // In FiveM, the native GetParentResourceName is available
    // But to avoid recursion, we'll use the known resource name
    // If you need dynamic detection, uncomment the code below
    /*
    try {
        // Access native function through window or global
        const nativeFn = (window && window.GetParentResourceName) || (typeof GetParentResourceName !== 'undefined' ? GetParentResourceName : null);
        if (nativeFn && typeof nativeFn === 'function' && nativeFn !== GetParentResourceName) {
            return nativeFn();
        }
    } catch(e) {
        // Fall through
    }
    */
    return RESOURCE_NAME;
}

// Close marketplace
function closeMarketplace() {
    // Hide UI immediately
    document.getElementById('marketplace').classList.add('hidden');
    
    // Send close callback to client
    fetch('https://' + GetParentResourceName() + '/close', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => {
        console.error('Error closing marketplace:', err);
    });
}

// Update sell item quantity based on selected item
function updateSellItemQuantity() {
    const select = document.getElementById('sellItemSelect');
    const selectedValue = select.value;
    const quantityInput = document.getElementById('sellQuantity');
    const availableQty = document.getElementById('sellAvailableQty');
    
    if (selectedValue) {
        const item = inventoryItems.find(i => i.name === selectedValue);
        if (item) {
            availableQty.textContent = item.count;
            quantityInput.max = item.count;
            quantityInput.value = Math.min(parseInt(quantityInput.value) || 1, item.count);
        }
    } else {
        availableQty.textContent = '0';
        quantityInput.max = 1;
        quantityInput.value = 1;
    }
}

// Handle sell item
function handleSellItem() {
    const itemName = document.getElementById('sellItemSelect').value;
    const quantity = parseInt(document.getElementById('sellQuantity').value);
    const price = parseInt(document.getElementById('sellPrice').value);

    if (!itemName || !quantity || !price) {
        showNotification('error', 'Please fill in all fields');
        return;
    }

    if (quantity < 1) {
        showNotification('error', 'Quantity must be at least 1');
        return;
    }

    if (price < 1) {
        showNotification('error', 'Price must be at least 1');
        return;
    }
    
    // Get item metadata
    const item = inventoryItems.find(i => i.name === itemName);
    const metadata = item ? (item.metadata || {}) : {};

    fetch('https://' + GetParentResourceName() + '/listItem', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            item: itemName,
            quantity: quantity,
            price: price,
            metadata: metadata
        })
    });

    // Clear form
    document.getElementById('sellItemSelect').value = '';
    document.getElementById('sellQuantity').value = '1';
    document.getElementById('sellPrice').value = '';
    document.getElementById('sellAvailableQty').textContent = '0';
}

// Handle create buy order
function handleCreateBuyOrder() {
    const itemName = document.getElementById('orderItemName').value.trim();
    const quantity = parseInt(document.getElementById('orderQuantity').value);
    const price = parseInt(document.getElementById('orderPrice').value);

    if (!itemName || !quantity || !price) {
        showNotification('error', 'Please fill in all fields');
        return;
    }

    if (quantity < 1) {
        showNotification('error', 'Quantity must be at least 1');
        return;
    }

    if (price < 1) {
        showNotification('error', 'Price must be at least 1');
        return;
    }

    fetch('https://' + GetParentResourceName() + '/createBuyOrder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            item: itemName,
            quantity: quantity,
            price: price
        })
    });

    // Clear form
    document.getElementById('orderItemName').value = '';
    document.getElementById('orderQuantity').value = '1';
    document.getElementById('orderPrice').value = '';
    updateOrderTotal();
}

// Update order total
function updateOrderTotal() {
    const quantity = parseInt(document.getElementById('orderQuantity').value) || 0;
    const price = parseInt(document.getElementById('orderPrice').value) || 0;
    const total = quantity * price;
    document.getElementById('orderTotal').textContent = total.toLocaleString();
}

// Render listings
function renderListings(listings) {
    currentListings = listings || [];
    const container = document.getElementById('listingsContainer');
    
    if (currentListings.length === 0) {
        container.innerHTML = '<div class="empty-state">No listings available</div>';
        return;
    }

    container.innerHTML = currentListings.map(listing => `
        <div class="listing-item">
            <div class="item-name">${escapeHtml(listing.item)}</div>
            <div class="item-details">
                <div>Quantity: ${listing.quantity}</div>
                <div>Seller: ${escapeHtml(listing.sellerName || 'Unknown')}</div>
                <div>Price per item: $${listing.price.toLocaleString()}</div>
            </div>
            <div class="item-price">Total: $${(listing.price * listing.quantity).toLocaleString()}</div>
            <div class="item-actions">
                <input type="number" class="quantity-input" id="qty-${listing.id}" min="1" max="${listing.quantity}" value="1">
                <button class="action-btn success" onclick="purchaseItem(${listing.id})">Buy</button>
                ${listing.seller === GetPlayerServerId() ? `<button class="action-btn danger" onclick="cancelListing(${listing.id})">Cancel</button>` : ''}
            </div>
        </div>
    `).join('');
}

// Render buy orders
function renderBuyOrders(orders) {
    currentBuyOrders = orders || [];
    const container = document.getElementById('ordersContainer');
    
    if (currentBuyOrders.length === 0) {
        container.innerHTML = '<div class="empty-state">No buy orders available</div>';
        return;
    }

    container.innerHTML = currentBuyOrders.map(order => `
        <div class="order-item">
            <div class="item-name">${escapeHtml(order.item)}</div>
            <div class="item-details">
                <div>Quantity: ${order.quantity}</div>
                <div>Buyer: ${escapeHtml(order.buyerName || 'Unknown')}</div>
                <div>Price per item: $${order.price.toLocaleString()}</div>
            </div>
            <div class="item-price">Total: $${(order.price * order.quantity).toLocaleString()}</div>
            <div class="item-actions">
                <input type="number" class="quantity-input" id="qty-order-${order.id}" min="1" max="${order.quantity}" value="1">
                ${order.buyer === GetPlayerServerId() ? 
                    `<button class="action-btn danger" onclick="cancelBuyOrder(${order.id})">Cancel</button>` : 
                    `<button class="action-btn success" onclick="fulfillBuyOrder(${order.id})">Fulfill</button>`
                }
            </div>
        </div>
    `).join('');
}

// Render pickups
function renderPickups(pickups) {
    currentPickups = pickups || [];
    const container = document.getElementById('pickupsContainer');
    
    if (!container) {
        return; // Container doesn't exist yet
    }
    
    if (currentPickups.length === 0) {
        container.innerHTML = '<div class="empty-state">No pickups available</div>';
        return;
    }

    container.innerHTML = currentPickups.map(pickup => {
        const fulfilledDate = new Date(pickup.fulfilledTimestamp * 1000).toLocaleString();
        return `
        <div class="pickup-item">
            <div class="item-name">${escapeHtml(pickup.item)}</div>
            <div class="item-details">
                <div>Quantity: ${pickup.quantity}</div>
                <div>Seller: ${escapeHtml(pickup.sellerName || 'Unknown')}</div>
                <div>Price per item: $${pickup.price.toLocaleString()}</div>
                <div>Fulfilled: ${fulfilledDate}</div>
            </div>
            <div class="item-price">Total: $${pickup.totalPrice.toLocaleString()}</div>
            <div class="item-actions">
                <button class="action-btn success" onclick="pickupOrder(${pickup.id})">Pick Up</button>
            </div>
        </div>
    `;
    }).join('');
}

// Render history
function renderHistory(history) {
    currentHistory = history || [];
    const container = document.getElementById('historyContainer');
    
    if (currentHistory.length === 0) {
        container.innerHTML = '<div class="empty-state">No history available</div>';
        return;
    }

    container.innerHTML = currentHistory.map(entry => {
        const date = new Date(entry.timestamp * 1000);
        const dateStr = date.toLocaleString();
        
        let typeLabel = '';
        let details = '';
        
        switch(entry.type) {
            case 'listing':
                typeLabel = 'Listing Created';
                details = `Listed ${entry.quantity}x ${entry.item} for $${entry.price.toLocaleString()} each`;
                break;
            case 'purchase':
                typeLabel = 'Purchase';
                details = `${entry.buyerName} bought ${entry.quantity}x ${entry.item} from ${entry.sellerName} for $${entry.totalPrice.toLocaleString()}`;
                break;
            case 'buyOrder':
                typeLabel = 'Buy Order Created';
                details = `Created buy order for ${entry.quantity}x ${entry.item} at $${entry.price.toLocaleString()} each`;
                break;
            case 'fulfill':
                typeLabel = 'Order Fulfilled';
                details = `${entry.sellerName} fulfilled ${entry.buyerName}'s order: ${entry.quantity}x ${entry.item} for $${entry.totalPrice.toLocaleString()}`;
                break;
            case 'listingCancel':
                typeLabel = 'Listing Cancelled';
                details = `Cancelled listing: ${entry.quantity}x ${entry.item}`;
                break;
            case 'buyOrderCancel':
                typeLabel = 'Buy Order Cancelled';
                details = `Cancelled buy order: ${entry.quantity}x ${entry.item}`;
                break;
        }
        
        return `
            <div class="history-item">
                <div class="item-name">${typeLabel}</div>
                <div class="item-details">
                    <div>${details}</div>
                    <div style="margin-top: 10px; color: #888; font-size: 12px;">${dateStr}</div>
                </div>
            </div>
        `;
    }).join('');
}

// Filter listings
function filterListings(searchTerm) {
    const filtered = currentListings.filter(listing => {
        return listing.item.toLowerCase().includes(searchTerm.toLowerCase()) ||
               (listing.sellerName && listing.sellerName.toLowerCase().includes(searchTerm.toLowerCase()));
    });
    
    const container = document.getElementById('listingsContainer');
    if (filtered.length === 0) {
        container.innerHTML = '<div class="empty-state">No listings match your search</div>';
        return;
    }
    
    container.innerHTML = filtered.map(listing => `
        <div class="listing-item">
            <div class="item-name">${escapeHtml(listing.item)}</div>
            <div class="item-details">
                <div>Quantity: ${listing.quantity}</div>
                <div>Seller: ${escapeHtml(listing.sellerName || 'Unknown')}</div>
                <div>Price per item: $${listing.price.toLocaleString()}</div>
            </div>
            <div class="item-price">Total: $${(listing.price * listing.quantity).toLocaleString()}</div>
            <div class="item-actions">
                <input type="number" class="quantity-input" id="qty-${listing.id}" min="1" max="${listing.quantity}" value="1">
                <button class="action-btn success" onclick="purchaseItem(${listing.id})">Buy</button>
                ${listing.seller === GetPlayerServerId() ? `<button class="action-btn danger" onclick="cancelListing(${listing.id})">Cancel</button>` : ''}
            </div>
        </div>
    `).join('');
}

// Filter buy orders
function filterBuyOrders(searchTerm) {
    const filtered = currentBuyOrders.filter(order => {
        return order.item.toLowerCase().includes(searchTerm.toLowerCase()) ||
               (order.buyerName && order.buyerName.toLowerCase().includes(searchTerm.toLowerCase()));
    });
    
    const container = document.getElementById('ordersContainer');
    if (filtered.length === 0) {
        container.innerHTML = '<div class="empty-state">No buy orders match your search</div>';
        return;
    }
    
    container.innerHTML = filtered.map(order => `
        <div class="order-item">
            <div class="item-name">${escapeHtml(order.item)}</div>
            <div class="item-details">
                <div>Quantity: ${order.quantity}</div>
                <div>Buyer: ${escapeHtml(order.buyerName || 'Unknown')}</div>
                <div>Price per item: $${order.price.toLocaleString()}</div>
            </div>
            <div class="item-price">Total: $${(order.price * order.quantity).toLocaleString()}</div>
            <div class="item-actions">
                <input type="number" class="quantity-input" id="qty-order-${order.id}" min="1" max="${order.quantity}" value="1">
                ${order.buyer === GetPlayerServerId() ? 
                    `<button class="action-btn danger" onclick="cancelBuyOrder(${order.id})">Cancel</button>` : 
                    `<button class="action-btn success" onclick="fulfillBuyOrder(${order.id})">Fulfill</button>`
                }
            </div>
        </div>
    `).join('');
}

// Filter pickups
function filterPickups(searchTerm) {
    const filtered = currentPickups.filter(pickup => {
        return pickup.item.toLowerCase().includes(searchTerm.toLowerCase()) ||
               (pickup.sellerName && pickup.sellerName.toLowerCase().includes(searchTerm.toLowerCase()));
    });
    
    const container = document.getElementById('pickupsContainer');
    if (filtered.length === 0) {
        container.innerHTML = '<div class="empty-state">No pickups match your search</div>';
        return;
    }
    
    container.innerHTML = filtered.map(pickup => {
        const fulfilledDate = new Date(pickup.fulfilledTimestamp * 1000).toLocaleString();
        return `
        <div class="pickup-item">
            <div class="item-name">${escapeHtml(pickup.item)}</div>
            <div class="item-details">
                <div>Quantity: ${pickup.quantity}</div>
                <div>Seller: ${escapeHtml(pickup.sellerName || 'Unknown')}</div>
                <div>Price per item: $${pickup.price.toLocaleString()}</div>
                <div>Fulfilled: ${fulfilledDate}</div>
            </div>
            <div class="item-price">Total: $${pickup.totalPrice.toLocaleString()}</div>
            <div class="item-actions">
                <button class="action-btn success" onclick="pickupOrder(${pickup.id})">Pick Up</button>
            </div>
        </div>
    `;
    }).join('');
}

// Purchase item
function purchaseItem(listingId) {
    const qtyInput = document.getElementById(`qty-${listingId}`);
    const quantity = parseInt(qtyInput.value) || 1;
    
    fetch('https://' + GetParentResourceName() + '/purchaseItem', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            listingId: listingId,
            quantity: quantity
        })
    });
}

// Cancel listing
function cancelListing(listingId) {
    if (!confirm('Are you sure you want to cancel this listing?')) {
        return;
    }
    
    fetch('https://' + GetParentResourceName() + '/cancelListing', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            listingId: listingId
        })
    });
}

// Cancel buy order
function cancelBuyOrder(orderId) {
    if (!confirm('Are you sure you want to cancel this buy order?')) {
        return;
    }
    
    fetch('https://' + GetParentResourceName() + '/cancelBuyOrder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            orderId: orderId
        })
    });
}

// Fulfill buy order
function fulfillBuyOrder(orderId) {
    const qtyInput = document.getElementById(`qty-order-${orderId}`);
    const quantity = parseInt(qtyInput.value) || 1;
    
    fetch('https://' + GetParentResourceName() + '/fulfillBuyOrder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            orderId: orderId,
            quantity: quantity
        })
    });
}

// Pickup order
function pickupOrder(pickupId) {
    fetch('https://' + GetParentResourceName() + '/pickupOrder', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            pickupId: pickupId
        })
    });
}

// Apply history filters
function applyHistoryFilters() {
    const searchTerm = document.getElementById('historySearch').value.trim();
    const typeFilter = document.getElementById('historyType').value;
    
    const filters = {};
    if (typeFilter) {
        filters.type = typeFilter;
    }
    if (searchTerm) {
        filters.search = searchTerm;
    }
    
    fetch('https://' + GetParentResourceName() + '/getHistory', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ filters: filters })
    });
}

// Show notification
function showNotification(type, message) {
    const container = document.getElementById('notificationContainer');
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    container.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideIn 0.3s ease-out reverse';
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// Setup auto refresh
function setupAutoRefresh() {
    setInterval(() => {
        if (document.getElementById('listings-tab').classList.contains('active') ||
            document.getElementById('buy-orders-tab').classList.contains('active')) {
            fetch('https://' + GetParentResourceName() + '/requestRefresh', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    }, 5000); // Refresh every 5 seconds
}

// Escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Get player server ID
let playerServerId = 0;
function GetPlayerServerId() {
    return playerServerId;
}

// Populate inventory dropdown
function populateInventoryDropdown() {
    const select = document.getElementById('sellItemSelect');
    const currentValue = select.value;
    
    // Clear existing options except the first one
    select.innerHTML = '<option value="">Select an item from your inventory...</option>';
    
    // Add inventory items
    inventoryItems.forEach(item => {
        const option = document.createElement('option');
        option.value = item.name;
        option.textContent = `${item.label || item.name} (${item.count}x)`;
        select.appendChild(option);
    });
    
    // Restore selection if item still exists
    if (currentValue) {
        const stillExists = inventoryItems.find(i => i.name === currentValue);
        if (stillExists) {
            select.value = currentValue;
            updateSellItemQuantity();
        }
    }
}

// Message listener from FiveM
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'open':
            document.getElementById('marketplace').classList.remove('hidden');
            currentListings = data.listings || [];
            currentBuyOrders = data.buyOrders || [];
            currentPickups = data.pickups || [];
            inventoryItems = data.inventoryItems || [];
            if (data.playerId) {
                playerServerId = data.playerId;
            }
            renderListings(currentListings);
            renderBuyOrders(currentBuyOrders);
            renderPickups(currentPickups);
            populateInventoryDropdown();
            break;
            
        case 'pickups':
            currentPickups = data.pickups || [];
            renderPickups(currentPickups);
            break;
            
        case 'inventoryItems':
            inventoryItems = data.inventoryItems || [];
            populateInventoryDropdown();
            break;
            
        case 'close':
            document.getElementById('marketplace').classList.add('hidden');
            break;
            
        case 'refresh':
            if (data.listings) {
                currentListings = data.listings;
                if (document.getElementById('listings-tab').classList.contains('active')) {
                    const searchTerm = document.getElementById('listingsSearch').value;
                    if (searchTerm) {
                        filterListings(searchTerm);
                    } else {
                        renderListings(currentListings);
                    }
                }
            }
            if (data.buyOrders) {
                currentBuyOrders = data.buyOrders;
                // Always update buy orders when refreshed, regardless of active tab
                const ordersSearch = document.getElementById('ordersSearch');
                const searchTerm = ordersSearch ? ordersSearch.value : '';
                if (searchTerm && document.getElementById('buy-orders-tab').classList.contains('active')) {
                    filterBuyOrders(searchTerm);
                } else {
                    renderBuyOrders(currentBuyOrders);
                }
            }
            if (data.pickups) {
                currentPickups = data.pickups || [];
                // Always update pickups when refreshed, regardless of active tab
                const pickupsSearch = document.getElementById('pickupsSearch');
                const searchTerm = pickupsSearch ? pickupsSearch.value : '';
                if (searchTerm && document.getElementById('pickups-tab').classList.contains('active')) {
                    filterPickups(searchTerm);
                } else {
                    renderPickups(currentPickups);
                }
            }
            break;
            
        case 'history':
            renderHistory(data.history);
            break;
            
        case 'notification':
            showNotification(data.type, data.message);
            break;
    }
});


