import { useState, useEffect } from 'react';
import './index.css';

// Product type expected from Flutter
interface Product {
  id: string;
  name: string;
  price: number;
  imageUrl: string;
}

interface CartItem extends Product {
  quantity: number;
}

function App() {
  const [cartItems, setCartItems] = useState<CartItem[]>([]);
  const [authToken, setAuthToken] = useState<string | null>(null);

  useEffect(() => {
    // 1. Read injected token
    if ((window as any).superAppAuthToken) {
      setAuthToken((window as any).superAppAuthToken);
    }

    // 2. Setup Bridge Listener for Native -> Web messages
    (window as any).receiveMessageFromNative = (action: string, data: any) => {
      if (action === 'updateToken') {
        setAuthToken(data);
      } else if (action === 'addToCart') {
        // Handle incoming product from Flutter
        const product = data as Product;
        setCartItems(prev => {
          const existing = prev.find(item => item.id === product.id);
          if (existing) {
            return prev.map(item => 
              item.id === product.id 
                ? { ...item, quantity: item.quantity + 1 } 
                : item
            );
          }
          return [...prev, { ...product, quantity: 1 }];
        });
      }
    };
    
    // 3. Notify Flutter we are ready (so it can send any pending addToCart messages)
    sendMessageToNative('reactAppReady');
    
  }, []);

  const sendMessageToNative = (action: string, payload: any = {}) => {
    if ((window as any).SuperAppBridge) {
      const message = JSON.stringify({ action, data: payload });
      (window as any).SuperAppBridge.postMessage(message);
    }
  };

  const handleCheckout = () => {
    sendMessageToNative('checkoutClicked', { total: cartTotal });
  };
  
  const handleClose = () => {
    sendMessageToNative('close');
  };

  const removeOne = (id: string) => {
     setCartItems(prev => {
        const item = prev.find(i => i.id === id);
        if (item && item.quantity > 1) {
            return prev.map(i => i.id === id ? { ...i, quantity: i.quantity - 1 } : i);
        }
        return prev.filter(i => i.id !== id);
     });
  };

  const cartTotal = cartItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900 flex flex-col font-sans">
      {/* Header */}
      <header className="bg-white px-4 py-4 shadow-sm flex items-center justify-between sticky top-0 z-10">
        {/*<div className="flex items-center gap-3">
          <button onClick={handleClose} className="p-2 -ml-2 rounded-full hover:bg-gray-100 text-gray-500">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <h1 className="text-xl font-bold">Your Cart</h1>
        </div>*/}
        <span className="text-sm bg-blue-100 text-blue-800 px-2 py-1 rounded-full font-medium">
          {cartItems.length} items
        </span>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto px-4 py-6 pb-32">
        {cartItems.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-gray-400 gap-4 mt-20">
            <svg xmlns="http://www.w3.org/2000/svg" className="h-16 w-16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            <p className="text-lg font-medium">Your cart is empty</p>
            <p className="text-sm">Add products from the Native Shop</p>
          </div>
        ) : (
          <ul className="space-y-4">
            {cartItems.map(item => (
              <li key={item.id} className="bg-white p-4 rounded-2xl shadow-sm flex gap-4 items-center border border-gray-100">
                <div className="w-16 h-16 bg-gray-100 rounded-xl overflow-hidden flex-shrink-0 flex items-center justify-center text-3xl">
                  {item.imageUrl}
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-gray-900 truncate">{item.name}</h3>
                  <p className="text-blue-600 font-medium">${item.price.toFixed(2)}</p>
                </div>
                <div className="flex flex-col items-end gap-2">
                   <div className="bg-gray-100 rounded-lg flex items-center px-1 py-1">
                      <span className="px-3 font-semibold text-sm">x{item.quantity}</span>
                   </div>
                   <button onClick={() => removeOne(item.id)} className="text-xs text-red-500 font-medium hover:underline">
                     Remove
                   </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </main>

      {/* Bottom Fixed Checkout Bar */}
      {cartItems.length > 0 && (
        <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 p-4 pb-8 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
          <div className="flex justify-between items-center mb-4">
            <span className="text-gray-500 font-medium">Total Amount</span>
            <span className="text-2xl font-bold text-gray-900">${cartTotal.toFixed(2)}</span>
          </div>
          <button 
            onClick={handleCheckout}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-4 rounded-xl shadow-lg shadow-blue-500/30 transition-all active:scale-[0.98]"
          >
            Checkout Securely
          </button>
          {authToken && (
             <p className="text-center text-[10px] text-gray-400 mt-3 flex items-center justify-center gap-1">
               <svg xmlns="http://www.w3.org/2000/svg" className="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd" />
               </svg>
               Authenticated User
             </p>
          )}
        </div>
      )}
    </div>
  );
}

export default App;
