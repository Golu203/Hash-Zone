import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class HZQuantityStepper extends StatefulWidget {
  final Product product;
  final double height;
  final bool isSmall;
  final int? value;
  final ValueChanged<int>? onChanged;

  const HZQuantityStepper({
    super.key,
    required this.product,
    this.height = 36.0,
    this.isSmall = false,
    this.value,
    this.onChanged,
  });

  @override
  State<HZQuantityStepper> createState() => _HZQuantityStepperState();
}

class _HZQuantityStepperState extends State<HZQuantityStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  int _localVal = 1;

  @override
  void initState() {
    super.initState();
    _localVal = widget.value ?? 1;
    _controller = TextEditingController(text: _localVal.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant HZQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != oldWidget.value && !_focusNode.hasFocus) {
      setState(() {
        _localVal = widget.value!;
        _controller.text = _localVal.toString();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submitValue();
    }
  }

  void _submitValue() {
    final val = int.tryParse(_controller.text);
    if (widget.onChanged != null) {
      if (val != null && val >= 1) {
        setState(() {
          _localVal = val;
        });
        widget.onChanged!(val);
      } else {
        _controller.text = _localVal.toString();
      }
    } else {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final totalQty = cart.getProductTotalQuantity(widget.product.id);
      if (val != null) {
        if (val != totalQty) {
          cart.updateProductTotalQuantity(widget.product, val);
        }
      } else {
        _controller.text = totalQty.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final totalQty = widget.value ?? cart.getProductTotalQuantity(widget.product.id);

    if (!_focusNode.hasFocus) {
      _controller.text = totalQty.toString();
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minus Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.remove, size: 16, color: Colors.black),
            onPressed: () {
              if (widget.onChanged != null) {
                if (totalQty > 1) {
                  widget.onChanged!(totalQty - 1);
                }
              } else {
                cart.updateProductTotalQuantity(widget.product, totalQty - 1);
              }
            },
          ),
          // Editable text field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: widget.isSmall ? 11 : 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _submitValue(),
            ),
          ),
          // Plus Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.add, size: 16, color: Colors.black),
            onPressed: () {
              if (widget.onChanged != null) {
                widget.onChanged!(totalQty + 1);
              } else {
                cart.updateProductTotalQuantity(widget.product, totalQty + 1);
              }
            },
          ),
        ],
      ),
    );
  }
}
