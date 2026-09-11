import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

@JS('MercadoPagoBridge.initialize')
external JSPromise _initializeMercadoPago(JSString publicKey);

@JS('MercadoPagoBridge.renderPaymentBrick')
external JSPromise _renderPaymentBrick(
  JSString containerId,
  JSNumber amount,
  JSString preferenceId,
  JSFunction onSubmit,
  JSFunction onReady,
  JSFunction onError,
);

@JS('MercadoPagoBridge.destroyPaymentBrick')
external void _destroyPaymentBrick();

const String paymentBrickViewType = 'payment-brick-view';

bool _paymentBrickViewRegistered = false;

void registerPaymentBrickView() {
  if (_paymentBrickViewRegistered) {
    return;
  }

  ui_web.platformViewRegistry.registerViewFactory(paymentBrickViewType, (
    int viewId,
  ) {
    final element = web.HTMLDivElement()
      ..id = 'paymentBrickContainer'
      ..style.width = '100%'
      ..style.height = '900px'
      ..style.minHeight = '900px'
      ..style.overflowY = 'auto';

    return element;
  });

  _paymentBrickViewRegistered = true;
}

Future<void> initializeMercadoPago(String publicKey) async {
  await _initializeMercadoPago(publicKey.toJS).toDart;
}

Future<void> renderPaymentBrick({
  required double amount,
  required String preferenceId,
  required Future<void> Function(String formDataJson) onSubmit,
  required void Function() onReady,
  required void Function(String error) onError,
}) async {
  final submitCallback = ((JSString formDataJson) {
    return onSubmit(formDataJson.toDart).toJS;
  }).toJS;

  final readyCallback = () {
    onReady();
  }.toJS;

  final errorCallback = (JSAny error) {
    onError(error.toString());
  }.toJS;

  await _renderPaymentBrick(
    'paymentBrickContainer'.toJS,
    amount.toJS,
    preferenceId.toJS,
    submitCallback,
    readyCallback,
    errorCallback,
  ).toDart;
}

void destroyPaymentBrick() {
  _destroyPaymentBrick();
}
