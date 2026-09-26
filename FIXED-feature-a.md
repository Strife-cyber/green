# Feature A — buying & money-flow fixes

All paths relative to `green/`. No forbidden files touched (`api_repositories.dart`,
`api_client.dart`, `socket_service.dart`, `app_router.dart`, `auth_controller.dart`).

## Files changed

| File | Change |
| --- | --- |
| `lib/features/buyer/controllers/checkout_controller.dart` | `submit()` now creates **every** seller group's order, collects all ids + `paymentStatus`es into a `CheckoutResult` (`List<PlacedOrder>` + `failedGroups`), and a failed group no longer aborts the rest. `CheckoutState` carries the result. |
| `lib/features/buyer/screens/checkout_screen.dart` | On success clears the cart **only after all orders are placed**; on partial failure removes only the placed seller lines and shows a "Some orders were placed" dialog (Pay placed / Retry the rest / Close). Routes to payment for the first placed order. |
| `lib/features/buyer/controllers/cart_controller.dart` | Sold-out (`quantityKg <= 0`) products can no longer be added (`add` no-ops); the stepper cap is live stock via a new `_capped` guard (no `1000` fallback); added `removeLinesWhere`, `restore`, and `Cart.totalKg`. |
| `lib/features/buyer/widgets/cart_line_tile.dart` | Stepper max = live stock (0 kg → stepper disabled) instead of a 1000 kg fallback. |
| `lib/features/buyer/widgets/product_sheet.dart` | "Out of stock" badge + disabled "Out of stock" add button when 0 kg. |
| `lib/features/buyer/screens/product_detail_screen.dart` | Same out-of-stock state; quantity stepper hidden; add button disabled. |
| `lib/features/buyer/screens/cart_screen.dart` | Counts now show "N products · X kg" (was "N items"); "Clear cart" is confirmed with a dialog and is undoable via a snackbar. |
| `lib/features/buyer/screens/order_detail_screen.dart` | Buyer can cancel their own **PENDING** order: confirm dialog → `updateStatus(id, OrderStatus.cancelled)`, then reloads the detail and the orders list. |
| `lib/features/wallet/screens/payment_screen.dart` | Shows + lets you edit the mobile-money number charged (from the buyer profile); "Order X of Y · N unpaid left" banner; after a success it can continue to the next unpaid order. |
| `lib/features/receipts/screens/receipt_screen.dart` | Download button disabled with an honest "Receipt PDF comes soon" caption (no `printing`/`pdf` dependency exists — none added). |
| `lib/features/buyer/screens/buyer_home_screen.dart` | Category chips loading skeleton (cream/tan pills at the 40 px chip height) + inline "Retry" on error. |
| `lib/features/buyer/screens/buyer_orders_screen.dart` | Unpaid orders expose a "Pay now" button (`PaymentStatus.unpaid` is already on the model). |

## Checkout pay-all flow (as implemented)

1. `CheckoutController.submit()` loops the seller groups and calls
   `orderRepository.create()` once per group, appending
   `PlacedOrder(sellerId, orderId, paymentStatus)` on success and counting a
   failure instead of aborting. It returns a `CheckoutResult` regardless of
   partial failure.
2. `CheckoutScreen._placeOrder()`:
   - **All placed** → `cartController.clear()` (the cart is cleared only now),
     invalidate the orders list, `pushReplacement(payment(firstOrderId))`.
   - **Partial** → `cartController.removeLinesWhere(...)` drops only the lines
     that became orders; an alert explains "N of M orders placed" with
     **Pay placed orders** / **Retry the rest** / **Close**. Retry resubmits the
     groups still left in the cart; Close leaves them for a later tap of
     "Place order".
   - **None placed** → bare error snackbar, cart untouched (unchanged behaviour).
3. The payment screen watches the buyer order list and shows a
   "Order X of Y · N unpaid left" banner while paying one of several orders. On
   success it offers **Pay next order (N left)** (navigates to the next unpaid
   order) plus **Done for now** (Orders tab). Because the Orders list also now
   shows a **Pay now** button per unpaid order, a buyer who exits mid-flow can
   resume paying from the Orders tab.
4. Single-seller behaviour is unchanged: one order → payment for that order.

## Repository-method gaps found

- `OrderRepository` has **no dedicated `cancel`/`cancelOrder`** method. The
  buyer-cancel uses the existing `updateStatus(String id, OrderStatus status)`
  (`PATCH /orders/{id}/status`) with `OrderStatus.cancelled`. No edit to
  `api_repositories.dart` was made — the backend must enforce "cancel only when
  `status == PENDING`" server-side; the client only shows the action for
  `PENDING` orders.
- `PaymentRepository` already exposes `initiate`/`status`; no changes needed.
- Buyer phone comes from the auth session (`authControllerProvider.user.phone`);
  editing goes through `UserRepository.updateProfile(UpdateProfileInput(phone: …))`.
- Receipt PDF: `printing`/`pdf` are not in `pubspec.yaml`, so the download was
  disabled honestly instead of adding dependencies.
