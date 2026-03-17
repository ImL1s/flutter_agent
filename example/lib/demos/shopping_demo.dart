import 'package:flutter/material.dart';
import '../agent_demo_base.dart';

/// Shopping Demo — tests `tap` + `scrollDown` actions.
///
/// Agent task: Add specific items to the shopping cart.
class ShoppingDemo extends StatefulWidget {
  const ShoppingDemo({super.key});

  @override
  State<ShoppingDemo> createState() => _ShoppingDemoState();
}

class _ShoppingDemoState extends State<ShoppingDemo> {
  final List<_Product> _products = [
    _Product('Wireless Headphones', '\$49.99', Icons.headphones),
    _Product('Phone Case', '\$14.99', Icons.phone_android),
    _Product('USB Cable', '\$9.99', Icons.cable),
    _Product('Bluetooth Speaker', '\$34.99', Icons.speaker),
    _Product('Screen Protector', '\$7.99', Icons.screen_lock_portrait),
    _Product('Laptop Stand', '\$29.99', Icons.laptop),
    _Product('Webcam', '\$44.99', Icons.videocam),
    _Product('Mouse Pad', '\$12.99', Icons.mouse),
    _Product('Keyboard Cover', '\$19.99', Icons.keyboard),
    _Product('HDMI Adapter', '\$16.99', Icons.settings_input_hdmi),
  ];

  int get _cartCount => _products.where((p) => p.inCart).length;

  void _toggleCart(int index) {
    setState(() => _products[index].inCart = !_products[index].inCart);
  }

  @override
  Widget build(BuildContext context) {
    return AgentDemoScaffold(
      title: 'Shopping Demo',
      agentTask:
          "Add 'Wireless Headphones' and 'USB Cable' to the shopping cart "
          "by tapping their 'Add to Cart' buttons. You may need to scroll down to find items.",
      maxSteps: 10,
      body: Column(
        children: [
          // Cart summary bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Shopping cart count',
                  value: '$_cartCount items',
                  child: Text(
                    'Cart: $_cartCount items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product list
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Semantics(
                  label: product.name,
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Icon(product.icon, size: 32),
                      title: Text(product.name),
                      subtitle: Text(product.price),
                      trailing: product.inCart
                          ? Semantics(
                              label: 'Remove ${product.name} from cart',
                              button: true,
                              child: FilledButton.tonal(
                                onPressed: () => _toggleCart(index),
                                child: const Text('In Cart ✓'),
                              ),
                            )
                          : Semantics(
                              label: 'Add ${product.name} to cart',
                              button: true,
                              child: FilledButton(
                                onPressed: () => _toggleCart(index),
                                child: const Text('Add to Cart'),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Product {
  final String name;
  final String price;
  final IconData icon;
  bool inCart;
  _Product(this.name, this.price, this.icon, [this.inCart = false]);
}
