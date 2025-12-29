let currentListings = [];
let currentBuyOrders = [];
let currentHistory = [];
let currentPickups = [];
let inventoryItems = [];
let allAvailableItems = []; // All available items from ox_inventory
let blacklistedItems = []; // Blacklisted items that cannot be used
let itemLabelMap = {}; // Map of item name -> label
let labelToNameMap = {}; // Map of item label -> name (for buy orders)

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
    
    // Add autocomplete suggestions for buy order item input
    const orderItemInput = document.getElementById('orderItemName');
    if (orderItemInput) {
        orderItemInput.addEventListener('input', (e) => {
            showItemSuggestions(e.target.value);
        });
        
        orderItemInput.addEventListener('blur', () => {
            // Hide suggestions after a short delay to allow clicking
            setTimeout(() => {
                hideItemSuggestions();
            }, 200);
        });
    }

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
    
    // History search - real-time filtering
    document.getElementById('historySearch').addEventListener('input', (e) => {
        applyHistoryFilters();
    });
    
    // History type filter - real-time filtering
    document.getElementById('historyType').addEventListener('change', () => {
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
    
    // Load history when switching to history tab
    if (tabName === 'history') {
        fetch('https://' + GetParentResourceName() + '/getHistory', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ filters: {} })
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
    const itemLabel = document.getElementById('orderItemName').value.trim();
    const quantity = parseInt(document.getElementById('orderQuantity').value);
    const price = parseInt(document.getElementById('orderPrice').value);

    if (!itemLabel || !quantity || !price) {
        showNotification('error', 'Please fill in all fields');
        return;
    }

    // Validate that the label exists
    if (!doesLabelExist(itemLabel)) {
        showNotification('error', 'Item label not found. Please enter a valid item name.');
        return;
    }

    // Convert label to item name
    const itemName = getItemNameFromLabel(itemLabel);
    if (!itemName) {
        showNotification('error', 'Could not find item. Please check the item name and try again.');
        return;
    }

    // Check if item is blacklisted
    if (isItemBlacklisted(itemName)) {
        showNotification('error', 'This item cannot be ordered on the marketplace');
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
            <div class="item-name">${escapeHtml(getItemLabel(listing.item))}</div>
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
            <div class="item-name">${escapeHtml(getItemLabel(order.item))}</div>
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
            <div class="item-name">${escapeHtml(getItemLabel(pickup.item))}</div>
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
        
        // Helper function to get name safely
        const getName = (name, fallback = 'Unknown') => {
            if (!name || name === 'undefined' || name.trim() === '') {
                return fallback;
            }
            return name.trim();
        };
        
        let typeLabel = '';
        let details = '';
        
        switch(entry.type) {
            case 'listing':
                typeLabel = 'Listing Created';
                const listingSeller = getName(entry.sellerName, 'Unknown Seller');
                details = `${listingSeller} listed ${entry.quantity}x ${getItemLabel(entry.item)} for $${entry.price.toLocaleString()} each`;
                break;
            case 'purchase':
                typeLabel = 'Purchase';
                const purchaseBuyer = getName(entry.buyerName, 'Unknown Buyer');
                const purchaseSeller = getName(entry.sellerName, 'Unknown Seller');
                details = `${purchaseBuyer} bought ${entry.quantity}x ${getItemLabel(entry.item)} from ${purchaseSeller} for $${entry.totalPrice.toLocaleString()}`;
                break;
            case 'buyOrder':
                typeLabel = 'Buy Order Created';
                const orderBuyer = getName(entry.buyerName, 'Unknown Buyer');
                details = `${orderBuyer} created buy order for ${entry.quantity}x ${getItemLabel(entry.item)} at $${entry.price.toLocaleString()} each`;
                break;
            case 'fulfill':
                typeLabel = 'Order Fulfilled';
                const fulfillSeller = getName(entry.sellerName, 'Unknown Seller');
                const fulfillBuyer = getName(entry.buyerName, 'Unknown Buyer');
                details = `${fulfillSeller} fulfilled ${fulfillBuyer}'s order: ${entry.quantity}x ${getItemLabel(entry.item)} for $${entry.totalPrice.toLocaleString()}`;
                break;
            case 'listingCancel':
                typeLabel = 'Listing Cancelled';
                const cancelListingSeller = getName(entry.sellerName, 'Unknown Seller');
                details = `${cancelListingSeller} cancelled listing: ${entry.quantity}x ${getItemLabel(entry.item)}`;
                break;
            case 'buyOrderCancel':
                typeLabel = 'Buy Order Cancelled';
                const cancelOrderBuyer = getName(entry.buyerName, 'Unknown Buyer');
                details = `${cancelOrderBuyer} cancelled buy order: ${entry.quantity}x ${getItemLabel(entry.item)}`;
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
        const itemLabel = getItemLabel(listing.item).toLowerCase();
        return itemLabel.includes(searchTerm.toLowerCase()) ||
               listing.item.toLowerCase().includes(searchTerm.toLowerCase()) ||
               (listing.sellerName && listing.sellerName.toLowerCase().includes(searchTerm.toLowerCase()));
    });
    
    const container = document.getElementById('listingsContainer');
    if (filtered.length === 0) {
        container.innerHTML = '<div class="empty-state">No listings match your search</div>';
        return;
    }
    
    container.innerHTML = filtered.map(listing => `
        <div class="listing-item">
            <div class="item-name">${escapeHtml(getItemLabel(listing.item))}</div>
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
        const itemLabel = getItemLabel(order.item).toLowerCase();
        return itemLabel.includes(searchTerm.toLowerCase()) ||
               order.item.toLowerCase().includes(searchTerm.toLowerCase()) ||
               (order.buyerName && order.buyerName.toLowerCase().includes(searchTerm.toLowerCase()));
    });
    
    const container = document.getElementById('ordersContainer');
    if (filtered.length === 0) {
        container.innerHTML = '<div class="empty-state">No buy orders match your search</div>';
        return;
    }
    
    container.innerHTML = filtered.map(order => `
        <div class="order-item">
            <div class="item-name">${escapeHtml(getItemLabel(order.item))}</div>
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
        const itemLabel = getItemLabel(pickup.item).toLowerCase();
        return itemLabel.includes(searchTerm.toLowerCase()) ||
               pickup.item.toLowerCase().includes(searchTerm.toLowerCase()) ||
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
            <div class="item-name">${escapeHtml(getItemLabel(pickup.item))}</div>
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

// Apply history filters (client-side filtering)
function applyHistoryFilters() {
    const searchTerm = document.getElementById('historySearch').value.trim();
    const typeFilter = document.getElementById('historyType').value;
    
    // Filter history entries client-side
    let filtered = currentHistory;
    
    // Filter by type if selected
    if (typeFilter) {
        filtered = filtered.filter(entry => entry.type === typeFilter);
    }
    
    // Filter by search term (item label, item name, buyer name, seller name)
    if (searchTerm) {
        const searchLower = searchTerm.toLowerCase();
        filtered = filtered.filter(entry => {
            // Search by item label
            const itemLabel = getItemLabel(entry.item).toLowerCase();
            if (itemLabel.includes(searchLower)) {
                return true;
            }
            
            // Search by item name
            if (entry.item && entry.item.toLowerCase().includes(searchLower)) {
                return true;
            }
            
            // Search by buyer name
            if (entry.buyerName && entry.buyerName.toLowerCase().includes(searchLower)) {
                return true;
            }
            
            // Search by seller name
            if (entry.sellerName && entry.sellerName.toLowerCase().includes(searchLower)) {
                return true;
            }
            
            return false;
        });
    }
    
    // Render filtered history
    renderFilteredHistory(filtered);
}

// Render filtered history
function renderFilteredHistory(history) {
    const container = document.getElementById('historyContainer');
    
    if (history.length === 0) {
        container.innerHTML = '<div class="empty-state">No history matches your search</div>';
        return;
    }

    container.innerHTML = history.map(entry => {
        const date = new Date(entry.timestamp * 1000);
        const dateStr = date.toLocaleString();
        
        // Helper function to get name safely
        const getName = (name, fallback = 'Unknown') => {
            if (!name || name === 'undefined' || name.trim() === '') {
                return fallback;
            }
            return name.trim();
        };
        
        let typeLabel = '';
        let details = '';
        
        switch(entry.type) {
            case 'listing':
                typeLabel = 'Listing Created';
                const listingSeller = getName(entry.sellerName, 'Unknown Seller');
                details = `${listingSeller} listed ${entry.quantity}x ${getItemLabel(entry.item)} for $${entry.price.toLocaleString()} each`;
                break;
            case 'purchase':
                typeLabel = 'Purchase';
                const purchaseBuyer = getName(entry.buyerName, 'Unknown Buyer');
                const purchaseSeller = getName(entry.sellerName, 'Unknown Seller');
                details = `${purchaseBuyer} bought ${entry.quantity}x ${getItemLabel(entry.item)} from ${purchaseSeller} for $${entry.totalPrice.toLocaleString()}`;
                break;
            case 'buyOrder':
                typeLabel = 'Buy Order Created';
                const orderBuyer = getName(entry.buyerName, 'Unknown Buyer');
                details = `${orderBuyer} created buy order for ${entry.quantity}x ${getItemLabel(entry.item)} at $${entry.price.toLocaleString()} each`;
                break;
            case 'fulfill':
                typeLabel = 'Order Fulfilled';
                const fulfillSeller = getName(entry.sellerName, 'Unknown Seller');
                const fulfillBuyer = getName(entry.buyerName, 'Unknown Buyer');
                details = `${fulfillSeller} fulfilled ${fulfillBuyer}'s order: ${entry.quantity}x ${getItemLabel(entry.item)} for $${entry.totalPrice.toLocaleString()}`;
                break;
            case 'listingCancel':
                typeLabel = 'Listing Cancelled';
                const cancelListingSeller = getName(entry.sellerName, 'Unknown Seller');
                details = `${cancelListingSeller} cancelled listing: ${entry.quantity}x ${getItemLabel(entry.item)}`;
                break;
            case 'buyOrderCancel':
                typeLabel = 'Buy Order Cancelled';
                const cancelOrderBuyer = getName(entry.buyerName, 'Unknown Buyer');
                details = `${cancelOrderBuyer} cancelled buy order: ${entry.quantity}x ${getItemLabel(entry.item)}`;
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

// Get item label from item name
function getItemLabel(itemName) {
    if (!itemName) return 'Unknown Item';
    
    // Check if we have a label in our map
    if (itemLabelMap[itemName]) {
        return itemLabelMap[itemName];
    }
    
    // Fallback: format the item name nicely (capitalize and replace underscores)
    return itemName
        .split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');
}

// Update item label map from inventory items
function updateItemLabelMap() {
    itemLabelMap = {};
    inventoryItems.forEach(item => {
        if (item.name && item.label) {
            itemLabelMap[item.name] = item.label;
        }
    });
}

// Check if item is blacklisted
function isItemBlacklisted(itemName) {
    if (!itemName || !blacklistedItems || blacklistedItems.length === 0) {
        return false;
    }
    
    // Normalize item name for comparison
    const normalizedItem = itemName.toLowerCase();
    const normalizedItemUpper = itemName.toUpperCase();
    
    return blacklistedItems.some(blacklisted => {
        const normalizedBlacklisted = blacklisted.toLowerCase();
        const normalizedBlacklistedUpper = blacklisted.toUpperCase();
        
        // Check exact match (case-insensitive)
        return normalizedItem === normalizedBlacklisted || 
               normalizedItemUpper === normalizedBlacklistedUpper ||
               itemName === blacklisted;
    });
}

// Update label to name map from all available items
function updateLabelToNameMap() {
    labelToNameMap = {};
    allAvailableItems.forEach(item => {
        // Skip blacklisted items
        if (item.name && item.label && !isItemBlacklisted(item.name)) {
            // Handle case-insensitive matching and multiple items with same label
            const labelLower = item.label.toLowerCase();
            if (!labelToNameMap[labelLower]) {
                labelToNameMap[labelLower] = [];
            }
            labelToNameMap[labelLower].push({
                name: item.name,
                label: item.label
            });
        }
    });
}

// Get item name from label (for buy orders)
function getItemNameFromLabel(label) {
    if (!label) return null;
    
    const labelLower = label.trim().toLowerCase();
    const matches = labelToNameMap[labelLower];
    
    if (matches && matches.length > 0) {
        // If multiple items have the same label, return the first one
        // In most cases, labels should be unique
        return matches[0].name;
    }
    
    // Try exact case-insensitive match first
    for (const [mapLabel, items] of Object.entries(labelToNameMap)) {
        if (mapLabel === labelLower) {
            return items[0].name;
        }
    }
    
    // Try partial match (label contains input or input contains label)
    for (const [mapLabel, items] of Object.entries(labelToNameMap)) {
        if (mapLabel.includes(labelLower) || labelLower.includes(mapLabel)) {
            return items[0].name;
        }
    }
    
    return null;
}

// Validate if label exists
function doesLabelExist(label) {
    if (!label) return false;
    
    const labelLower = label.trim().toLowerCase();
    
    // Check exact match
    if (labelToNameMap[labelLower]) {
        return true;
    }
    
    // Check partial match
    for (const mapLabel of Object.keys(labelToNameMap)) {
        if (mapLabel === labelLower || mapLabel.includes(labelLower) || labelLower.includes(mapLabel)) {
            return true;
        }
    }
    
    return false;
}

// Show item suggestions for autocomplete
function showItemSuggestions(input) {
    if (!input || input.length < 1) {
        hideItemSuggestions();
        return;
    }
    
    const inputLower = input.toLowerCase();
    const suggestions = [];
    
    // Find matching items (excluding blacklisted)
    for (const [label, items] of Object.entries(labelToNameMap)) {
        if (label.includes(inputLower) || inputLower.includes(label)) {
            items.forEach(item => {
                // Only add if not blacklisted
                if (!isItemBlacklisted(item.name)) {
                    suggestions.push(item.label);
                }
            });
        }
    }
    
    // Remove duplicates
    const uniqueSuggestions = [...new Set(suggestions)];
    
    // Limit to 10 suggestions
    const limitedSuggestions = uniqueSuggestions.slice(0, 10);
    
    // Remove existing suggestions container
    const existing = document.getElementById('itemSuggestions');
    if (existing) {
        existing.remove();
    }
    
    if (limitedSuggestions.length === 0) {
        return;
    }
    
    // Create suggestions container
    const suggestionsDiv = document.createElement('div');
    suggestionsDiv.id = 'itemSuggestions';
    suggestionsDiv.className = 'item-suggestions';
    
    limitedSuggestions.forEach(suggestion => {
        const suggestionItem = document.createElement('div');
        suggestionItem.className = 'suggestion-item';
        suggestionItem.textContent = suggestion;
        suggestionItem.addEventListener('click', () => {
            document.getElementById('orderItemName').value = suggestion;
            hideItemSuggestions();
        });
        suggestionsDiv.appendChild(suggestionItem);
    });
    
    // Insert after the input field
    const orderItemInput = document.getElementById('orderItemName');
    if (orderItemInput && orderItemInput.parentNode) {
        orderItemInput.parentNode.insertBefore(suggestionsDiv, orderItemInput.nextSibling);
    }
}

// Hide item suggestions
function hideItemSuggestions() {
    const suggestions = document.getElementById('itemSuggestions');
    if (suggestions) {
        suggestions.remove();
    }
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
    
    // Update item label map when inventory items change
    updateItemLabelMap();
    
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
            allAvailableItems = data.allAvailableItems || [];
            blacklistedItems = data.blacklistedItems || [];
            updateItemLabelMap(); // Update label map when opening
            updateLabelToNameMap(); // Update label-to-name map when opening (filters blacklisted)
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
            updateItemLabelMap(); // Update label map when inventory changes
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
            // Re-apply filters if any are active
            const historySearch = document.getElementById('historySearch');
            const historyType = document.getElementById('historyType');
            if ((historySearch && historySearch.value.trim()) || (historyType && historyType.value)) {
                applyHistoryFilters();
            }
            break;
            
        case 'notification':
            showNotification(data.type, data.message);
            break;
    }
});


