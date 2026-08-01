import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class HZQuantityStepper extends StatefulWidget {
  final Product? product;
  final String? size;
  final int initialValue;
  final Function(int value, bool isValid)? onChanged;
  final bool isSmall;
  final double height;
  final bool isFullWidth;
  final bool showNote;

  const HZQuantityStepper({
    super.key,
    this.product,
    this.size,
    int? value,
    int? initialValue,
    this.onChanged,
    this.isSmall = false,
    this.height = 36.0,
    this.isFullWidth = false,
    this.showNote = true,
  }) : initialValue = initialValue ?? value ?? 5;

  @override
  State<HZQuantityStepper> createState() => _HZQuantityStepperState();
}

class _HZQuantityStepperState extends State<HZQuantityStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _errorText;
  late int _currentVal;

  @override
  void initState() {
    super.initState();
    _currentVal = widget.initialValue;
    // Align to multiple of 5 initially if not zero
    if (_currentVal > 0 && _currentVal % 5 != 0) {
      _currentVal = (_currentVal ~/ 5) * 5;
      if (_currentVal < 5) _currentVal = 5;
    }
    _controller = TextEditingController(text: _currentVal.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant HZQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      setState(() {
        _currentVal = widget.initialValue;
        if (_currentVal > 0 && _currentVal % 5 != 0) {
          _currentVal = (_currentVal ~/ 5) * 5;
          if (_currentVal < 5) _currentVal = 5;
        }
        _controller.text = _currentVal.toString();
        _errorText = null;
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
      _validateAndSubmit();
    }
  }

  void _validateAndSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText = 'HashZone accepts wholesale orders only in multiples of 5 pieces.';
      });
      if (widget.onChanged != null) {
        widget.onChanged!(_currentVal, false);
      }
      return;
    }

    final val = int.tryParse(text);
    if (val == null || val <= 0 || val % 5 != 0) {
      setState(() {
        _errorText = 'HashZone accepts wholesale orders only in multiples of 5 pieces.';
      });
      if (widget.onChanged != null) {
        widget.onChanged!(val ?? 0, false);
      }
      return;
    }

    setState(() {
      _currentVal = val;
      _errorText = null;
    });

    _performUpdate(val, true);
  }

  void _performUpdate(int val, bool isValid) {
    if (widget.onChanged != null) {
      widget.onChanged!(val, isValid);
    } else if (isValid) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      if (widget.product != null) {
        if (widget.size != null) {
          cart.updateQuantity(widget.product!.id, widget.size!, val);
        } else {
          cart.updateProductTotalQuantity(widget.product!, val);
        }
      }
    }
  }

  void _increment() {
    int nextVal = _currentVal + 5;
    if (nextVal % 5 != 0) {
      nextVal = ((nextVal ~/ 5) + 1) * 5;
    }
    setState(() {
      _currentVal = nextVal;
      _controller.text = _currentVal.toString();
      _errorText = null;
    });
    _performUpdate(_currentVal, true);
  }

  void _decrement() {
    if (_currentVal <= 5) {
      // If decreased below 5, it goes to 0 (which removes or goes to minimum)
      setState(() {
        _currentVal = 0;
        _controller.text = '0';
        _errorText = null;
      });
      _performUpdate(0, true);
      return;
    }
    int nextVal = _currentVal - 5;
    if (nextVal % 5 != 0) {
      nextVal = (nextVal ~/ 5) * 5;
    }
    if (nextVal < 0) nextVal = 0;
    setState(() {
      _currentVal = nextVal;
      _controller.text = _currentVal.toString();
      _errorText = null;
    });
    _performUpdate(_currentVal, true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stepper Input Row
        SizedBox(
          width: widget.isFullWidth ? double.infinity : (widget.isSmall ? 100 : 130),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _errorText != null ? Colors.red.shade700 : Colors.black,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Minus Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _currentVal > 0 ? _decrement : null,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                    ),
                    child: SizedBox(
                      width: widget.isSmall ? 28 : 36,
                      height: double.infinity,
                      child: Icon(
                        Icons.remove,
                        size: widget.isSmall ? 14 : 16,
                        color: _currentVal > 0 ? Colors.black : Colors.black26,
                      ),
                    ),
                  ),
                ),
                // Editable Text Field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: widget.isSmall ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (text) {
                      final trimmed = text.trim();
                      if (trimmed.isEmpty) {
                        setState(() {
                          _errorText = 'HashZone accepts wholesale orders only in multiples of 5 pieces.';
                        });
                        _performUpdate(_currentVal, false);
                        return;
                      }
                      final val = int.tryParse(trimmed);
                      if (val == null || val <= 0 || val % 5 != 0) {
                        setState(() {
                          _errorText = 'HashZone accepts wholesale orders only in multiples of 5 pieces.';
                        });
                        _performUpdate(val ?? 0, false);
                      } else {
                        setState(() {
                          _errorText = null;
                          _currentVal = val;
                        });
                        _performUpdate(val, true);
                      }
                    },
                    onSubmitted: (_) => _validateAndSubmit(),
                  ),
                ),
                // Plus Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _increment,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                    child: SizedBox(
                      width: widget.isSmall ? 28 : 36,
                      height: double.infinity,
                      child: Icon(
                        Icons.add,
                        size: widget.isSmall ? 14 : 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Information Note
        if (widget.showNote && !widget.isSmall) ...[
          const SizedBox(height: 8),
          Text(
            'HashZone is a wholesale supplier. Orders are accepted only in multiples of 5 pieces (5, 10, 15, 20...).',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorText!,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
