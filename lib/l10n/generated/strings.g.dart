/// Generated file. Do not edit.
///
/// Original: lib/l10n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 496 (248 per locale)
///
/// Built on 2026-08-19 at 00:28 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	en(languageCode: 'en', build: Translations.build),
	fr(languageCode: 'fr', build: _StringsFr.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	String get appTitle => 'Trendy Green';
	String get tagline => 'Fresh produce, straight from the farm to you';
	String get ok => 'OK';
	String get cancel => 'Cancel';
	String get save => 'Save';
	String get delete => 'Delete';
	String get edit => 'Edit';
	String get retry => 'Try again';
	String get search => 'Search';
	String get loading => 'Loading…';
	String get errorGeneric => 'Something went wrong. Please try again.';
	String get empty => 'Nothing here yet';
	String get back => 'Back';
	String get confirm => 'Confirm';
	String get continueLabel => 'Continue';
	String get done => 'Done';
	String get logout => 'Log out';
	String get navHome => 'Home';
	String get navSearch => 'Search';
	String get navCart => 'Cart';
	String get navOrders => 'Orders';
	String get navProfile => 'Profile';
	String get navDashboard => 'Dashboard';
	String get navProducts => 'Products';
	String get navDeliveries => 'Deliveries';
	String get navChat => 'Chat';
	String get navAdmin => 'Admin';
	String get navOverview => 'Overview';
	String get navSellers => 'Sellers';
	String get navWithdrawals => 'Withdrawals';
	String get navTickets => 'Tickets';
	String get navReports => 'Reports';
	String get navActivity => 'Activity';
	String get roleBuyer => 'Buyer';
	String get roleSeller => 'Seller';
	String get roleAdmin => 'Admin';
	String get roleDriver => 'Delivery Driver';
	String get welcomeBack => 'Welcome back';
	String get createAccount => 'Create account';
	String get signIn => 'Sign in';
	String get email => 'Email';
	String get password => 'Password';
	String get confirmPassword => 'Confirm password';
	String get forgotPassword => 'Forgot password?';
	String get firstName => 'First name';
	String get lastName => 'Last name';
	String get phone => 'Phone';
	String get region => 'Region';
	String get farmName => 'Farm / business name';
	String get mainCategory => 'Main product category';
	String get businessLicense => 'Business license (optional)';
	String get farmDescription => 'Farm description';
	String get nationalId => 'National ID card';
	String get selfie => 'Selfie of you or your market space';
	String get dontHaveAccount => 'Don\'t have an account?';
	String get alreadyHaveAccount => 'Already have an account?';
	String get createOne => 'Create one';
	String get loginWithCode => 'Log in with a code instead';
	String get sendCode => 'Send code';
	String get verifyAndLogin => 'Verify & log in';
	String get enterOtp => 'Enter the 6-digit code';
	String get pendingApproval => 'Your seller profile is pending approval. You can browse the dashboard in the meantime.';
	String get wallet => 'Wallet';
	String get balance => 'Available balance';
	String get escrow => 'Escrow';
	String get totalBalance => 'Total';
	String get withdraw => 'Withdraw';
	String get transactions => 'Transaction history';
	String get payNow => 'Pay now';
	String get mtnMomo => 'MTN Mobile Money';
	String get orangeMoney => 'Orange Money';
	String get giveCodeToDriver => 'Give this code to your driver';
	String get markDelivered => 'Mark delivered';
	String get confirmPickup => 'Confirm pickup';
	String get enterConfirmationCode => 'Enter the delivery confirmation code';
	String get quickActions => 'Quick actions';
	String get qaSearch => 'Search products';
	String get qaAddProduct => 'Add product';
	String get qaWallet => 'My wallet';
	String get qaOrders => 'My orders';
	String get qaTrackDelivery => 'Track delivery';
	String get qaSupport => 'Help & support';
	String get editProfile => 'Edit profile';
	String get language => 'Language';
	String get myOrders => 'My orders';
	String get myProducts => 'My products';
	String get wishlist => 'Wishlist';
	String get savedAddresses => 'Saved addresses';
	String get notifications => 'Notifications';
	String get support => 'Help & support';
	String get newProduct => 'New product';
	String get profileUpdated => 'Profile updated';
	String get saveFailed => 'Could not save your profile. Try again.';
	String get signUp => 'Sign up';
	String get profile => 'Profile';
	String get addProduct => 'Add product';
	String get noDeliveries => 'No deliveries assigned';
	String get deliveriesHint => 'New deliveries will appear here once assigned to you.';
	String get enRoute => 'En route';
	String get pickupPending => 'Pickup pending';
	String get deliveredStatus => 'Delivered';
	String get adminConsole => 'Admin Console';
	String get newDriver => 'New driver';
	String get statTotalUsers => 'Total users';
	String get statActiveSellers => 'Active sellers';
	String get statPendingSellers => 'Pending sellers';
	String get statGrossRevenue => 'Gross revenue';
	String get statCommission => 'Commission earned';
	String get statTotalOrders => 'Total orders';
	String get orderPrefix => 'Order #';
	String get navMore => 'More';
	String get addToCart => 'Add to cart';
	String get quantity => 'Quantity';
	String addedToCart({required Object name, required Object kg}) => '${name} added to cart (${kg} kg)';
	String get errorNoConnection => 'No internet connection. Check your connection and retry.';
	String get errorTimeout => 'The request timed out. Please try again.';
	String get errorUnauthorized => 'Your session has expired. Please sign in again.';
	String get errorServer => 'The server had a problem. Please try again later.';
	String get otpSubtitle => 'No password needed — we email you a one-time code';
	String get enterEmailFirst => 'Enter your email address first.';
	String get couldNotSendCode => 'Could not send the code. Please try again.';
	String get codeSentCheckInbox => 'Code sent to your email — check your inbox.';
	String codeExpiresIn({required Object minutes}) => 'The code expires in ${minutes} minutes.';
	String get invalidOtpCode => 'That code is not valid. Check it and try again.';
	String get resendCode => 'Resend code';
	String resendInSeconds({required Object seconds}) => 'Resend in ${seconds}s';
	String get backToPasswordSignIn => 'Back to password sign in';
	String get loginFailed => 'Login failed. Check your credentials and try again.';
	String get verifyEmailTitle => 'Verify your email';
	String get verifyEmailSubtitle => 'Almost there — one more step';
	String get verificationLinkSentTo => 'We sent a verification link to';
	String get verifyToOrderHint => 'You can browse while you wait, but you will need to verify before placing orders.';
	String get resendEmail => 'Resend email';
	String get verifyEmailSent => 'Verification email sent.';
	String get verifyEmailResendFailed => 'Could not resend. Please try again.';
	String get checkVerificationStatus => 'I\'ve verified — check status';
	String get resetTokenLabel => 'Reset token';
	String get resetTokenHint => 'Paste the link token from your email';
	String get invalidResetLink => 'The reset link is invalid or has expired. Please request a new one.';
	String get deliveryCodeEmailHint => 'Code sent to your email — check your inbox.';
	String get confirmDeliveryTitle => 'Confirm your delivery';
	String get confirmDeliveryBody => 'Enter the 6-digit code your driver shared with you to confirm the hand-off.';
	String get confirmationCode => 'Confirmation code';
	String get confirmDeliveryAction => 'Confirm delivery';
	String get deliveryConfirmed => 'Delivery confirmed — thank you!';
	String get confirmFailed => 'Could not confirm — check the code and try again.';
	String get driverCreatedTitle => 'Driver created';
	String get shareTempPassword => 'Share this temporary password with the driver — it is shown once and will be reset on their first login.';
	String get driverCreated => 'Driver account created';
	String get couldNotCreateDriver => 'Could not create the driver. Try again.';
	String get agreeTerms => 'I agree to the Terms of Service and Privacy Policy';
	String get termsRequired => 'Please accept the terms to continue.';
	String get termsOfService => 'Terms of Service';
	String get privacyPolicy => 'Privacy Policy';
	String get identityDocsOptional => 'These documents are optional but recommended. They are reviewed before your farm goes live and can be added later from your profile.';
	String get nationalIdOptional => 'National ID card (optional)';
	String get selfieOptional => 'Selfie of you or your market space (optional)';
	String get signUpFailed => 'Sign-up failed. Please try again.';
	String get markAllRead => 'Mark all read';
	String get noNotifications => 'No notifications';
	String get allCaughtUp => 'You are all caught up.';
	String get sellerRejectedTitle => 'Application rejected';
	String get sellerRejectedBody => 'Your farm profile was not approved. Please update your identity documents and re-submit.';
	String get reUploadNationalId => 'Re-upload National ID';
	String get reUploadSelfie => 'Re-upload selfie';
	String get documentsUpdated => 'Documents updated. Your profile will be reviewed again.';
	String get uploadFailed => 'Upload failed. Please try again.';
	String get report => 'Report';
	String get chatTitle => 'Chat';
	String get chatThreadsTitle => 'Chats';
	String get chatComposerHint => 'Message…';
	String get chatSend => 'Send';
	String get chatSendFailed => 'Could not send the message. Tap retry to try again.';
	String get chatAttachImage => 'Attach image';
	String get chatRecordVoice => 'Record voice note';
	String get chatStopVoice => 'Stop & send voice note';
	String get chatVoiceWebUnavailable => 'Voice notes are not available on the web yet.';
	String get chatMicPermission => 'Microphone permission is required for voice notes.';
	String get chatRecordFailed => 'Could not start recording.';
	String get chatVoiceFinishFailed => 'Could not finish the voice note.';
	String get chatVoiceNote => 'Voice note';
	String get chatNoMessages => 'No messages yet';
	String get chatNoMessagesHint => 'Say hello to start the conversation.';
	String get chatNoThreads => 'No conversations yet';
	String get chatNoThreadsHint => 'When you place an order, a chat thread is created with the seller.';
	String get chatYou => 'You';
	String get chatImageGlyph => 'Photo';
	String get chatVoiceGlyph => 'Voice note';
	String get chatToday => 'Today';
	String get chatYesterday => 'Yesterday';
	String get chatTyping => 'typing…';
	String get chatOrderContext => 'Order context';
	String get chatNoThreadForOrder => 'This order has no chat thread yet — new orders automatically get one at checkout.';
	String get orderStatusPending => 'Pending';
	String get orderStatusConfirmed => 'Confirmed';
	String get orderStatusShipped => 'On the way';
	String get orderStatusDelivered => 'Delivered';
	String get orderStatusCancelled => 'Cancelled';
	String get orderPlaced => 'Order placed';
	String get orderPreparing => 'Preparing';
	String arrivingAt({required Object time}) => 'arriving ~${time}';
	String get gotIt => 'Got it';
	String get driverArrivedTitle => 'Your driver is here';
	String get driverArrivedBody => 'Confirm that you received your order.';
	String get gotItCodeHint => 'Enter the 6-digit code sent to your email.';
	String get items => 'Items';
	String get subtotal => 'Subtotal';
	String get delivery => 'Delivery';
	String get total => 'Total';
	String get deliveryAddress => 'Delivery address';
	String get chatWithSeller => 'Chat with seller';
	String get orderDetails => 'Order details';
	String get viewReceipt => 'View receipt';
	String get rateSeller => 'Rate seller';
	String get cancelOrder => 'Cancel order';
	String get noOrdersYet => 'No orders yet';
	String get noOrdersYetHint => 'Your orders will appear here once you check out.';
	String get checkout => 'Checkout';
	String get placeOrder => 'Place order';
	String get nothingToCheckout => 'Nothing to checkout';
	String get emptyCart => 'Your cart is empty.';
	String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '1 item',
		other: '${count} items',
	);
	String get sellerQueueTitle => 'What needs you';
	String ordersToPrepare({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		zero: 'No orders to prepare',
		one: '${count} order to prepare',
		other: '${count} orders to prepare',
	);
	String awaitingPickup({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} awaiting pickup',
		other: '${count} awaiting pickup',
	);
	String get awaitingPickupLabel => 'Awaiting pickup';
	String readyToWithdraw({required Object amount}) => '${amount} ready to withdraw';
	String get toPrepare => 'To prepare';
	String get prepared => 'Prepared';
	String get noQueueHint => 'New paid orders will appear here.';
	String pickUpFrom({required Object seller}) => 'Pick up: ${seller}';
	String dropOffAt({required Object address}) => 'Drop off: ${address}';
	String distanceKm({required Object distance}) => '${distance} km';
	String get driverTaskStart => 'Start';
	String get driverTaskArrived => 'Arrived';
	String get pickedUp => 'Picked up';
	String get awaitingBuyerConfirm => 'Awaiting the buyer to confirm';
	String get codeRequiredNote => 'The buyer must enter a 6-digit code to complete.';
	String get navQueue => 'Queue';
	String get chatWithBuyer => 'Chat with buyer';
	String get currentDelivery => 'Current delivery';
	String get dropOffUnknown => 'Unknown address';
	String moreDeliveries({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} more delivery',
		other: '${count} more deliveries',
	);
}

// Path: <root>
class _StringsFr extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsFr.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _StringsFr _root = this; // ignore: unused_field

	// Translations
	@override String get appTitle => 'Trendy Green';
	@override String get tagline => 'Produits frais, directement de la ferme à votre table';
	@override String get ok => 'OK';
	@override String get cancel => 'Annuler';
	@override String get save => 'Enregistrer';
	@override String get delete => 'Supprimer';
	@override String get edit => 'Modifier';
	@override String get retry => 'Réessayer';
	@override String get search => 'Rechercher';
	@override String get loading => 'Chargement…';
	@override String get errorGeneric => 'Une erreur est survenue. Veuillez réessayer.';
	@override String get empty => 'Rien ici pour le moment';
	@override String get back => 'Retour';
	@override String get confirm => 'Confirmer';
	@override String get continueLabel => 'Continuer';
	@override String get done => 'Terminé';
	@override String get logout => 'Se déconnecter';
	@override String get navHome => 'Accueil';
	@override String get navSearch => 'Recherche';
	@override String get navCart => 'Panier';
	@override String get navOrders => 'Commandes';
	@override String get navProfile => 'Profil';
	@override String get navDashboard => 'Tableau de bord';
	@override String get navProducts => 'Produits';
	@override String get navDeliveries => 'Livraisons';
	@override String get navChat => 'Discussions';
	@override String get navAdmin => 'Admin';
	@override String get navOverview => 'Aperçu';
	@override String get navSellers => 'Vendeurs';
	@override String get navWithdrawals => 'Retraits';
	@override String get navTickets => 'Tickets';
	@override String get navReports => 'Signalements';
	@override String get navActivity => 'Activité';
	@override String get roleBuyer => 'Acheteur';
	@override String get roleSeller => 'Vendeur';
	@override String get roleAdmin => 'Administrateur';
	@override String get roleDriver => 'Livreur';
	@override String get welcomeBack => 'Bon retour';
	@override String get createAccount => 'Créer un compte';
	@override String get signIn => 'Se connecter';
	@override String get email => 'Email';
	@override String get password => 'Mot de passe';
	@override String get confirmPassword => 'Confirmer le mot de passe';
	@override String get forgotPassword => 'Mot de passe oublié ?';
	@override String get firstName => 'Prénom';
	@override String get lastName => 'Nom';
	@override String get phone => 'Téléphone';
	@override String get region => 'Région';
	@override String get farmName => 'Nom de la ferme / entreprise';
	@override String get mainCategory => 'Catégorie principale';
	@override String get businessLicense => 'Licence commerciale (optionnel)';
	@override String get farmDescription => 'Description de la ferme';
	@override String get nationalId => 'Carte d\'identité nationale';
	@override String get selfie => 'Selfie de vous ou de votre espace de vente';
	@override String get dontHaveAccount => 'Vous n\'avez pas de compte ?';
	@override String get alreadyHaveAccount => 'Vous avez déjà un compte ?';
	@override String get createOne => 'En créer un';
	@override String get loginWithCode => 'Se connecter avec un code à la place';
	@override String get sendCode => 'Envoyer le code';
	@override String get verifyAndLogin => 'Vérifier et se connecter';
	@override String get enterOtp => 'Saisissez le code à 6 chiffres';
	@override String get pendingApproval => 'Votre profil vendeur est en attente d\'approbation. Vous pouvez consulter le tableau de bord en attendant.';
	@override String get wallet => 'Portefeuille';
	@override String get balance => 'Solde disponible';
	@override String get escrow => 'Séquestre';
	@override String get totalBalance => 'Total';
	@override String get withdraw => 'Retirer';
	@override String get transactions => 'Historique des transactions';
	@override String get payNow => 'Payer maintenant';
	@override String get mtnMomo => 'MTN Mobile Money';
	@override String get orangeMoney => 'Orange Money';
	@override String get giveCodeToDriver => 'Donnez ce code à votre livreur';
	@override String get markDelivered => 'Marquer livré';
	@override String get confirmPickup => 'Confirmer le ramassage';
	@override String get enterConfirmationCode => 'Saisissez le code de confirmation de livraison';
	@override String get quickActions => 'Actions rapides';
	@override String get qaSearch => 'Rechercher des produits';
	@override String get qaAddProduct => 'Ajouter un produit';
	@override String get qaWallet => 'Mon portefeuille';
	@override String get qaOrders => 'Mes commandes';
	@override String get qaTrackDelivery => 'Suivre une livraison';
	@override String get qaSupport => 'Aide & support';
	@override String get editProfile => 'Modifier le profil';
	@override String get language => 'Langue';
	@override String get myOrders => 'Mes commandes';
	@override String get myProducts => 'Mes produits';
	@override String get wishlist => 'Liste de souhaits';
	@override String get savedAddresses => 'Adresses enregistrées';
	@override String get notifications => 'Notifications';
	@override String get support => 'Aide & support';
	@override String get newProduct => 'Nouveau produit';
	@override String get profileUpdated => 'Profil mis à jour';
	@override String get saveFailed => 'Impossible d\'enregistrer votre profil. Réessayez.';
	@override String get signUp => 'S\'inscrire';
	@override String get profile => 'Profil';
	@override String get addProduct => 'Ajouter un produit';
	@override String get noDeliveries => 'Aucune livraison assignée';
	@override String get deliveriesHint => 'Les nouvelles livraisons apparaîtront ici une fois assignées à vous.';
	@override String get enRoute => 'En route';
	@override String get pickupPending => 'Ramassage en attente';
	@override String get deliveredStatus => 'Livrée';
	@override String get adminConsole => 'Console Admin';
	@override String get newDriver => 'Nouveau livreur';
	@override String get statTotalUsers => 'Total utilisateurs';
	@override String get statActiveSellers => 'Vendeurs actifs';
	@override String get statPendingSellers => 'Vendeurs en attente';
	@override String get statGrossRevenue => 'Revenu brut';
	@override String get statCommission => 'Commission perçue';
	@override String get statTotalOrders => 'Total commandes';
	@override String get orderPrefix => 'Commande #';
	@override String get navMore => 'Plus';
	@override String get addToCart => 'Ajouter au panier';
	@override String get quantity => 'Quantité';
	@override String addedToCart({required Object name, required Object kg}) => '${name} ajouté au panier (${kg} kg)';
	@override String get errorNoConnection => 'Pas de connexion internet. Vérifiez votre connexion et réessayez.';
	@override String get errorTimeout => 'Le délai de la requête est dépassé. Veuillez réessayer.';
	@override String get errorUnauthorized => 'Votre session a expiré. Veuillez vous reconnecter.';
	@override String get errorServer => 'Le serveur a rencontré un problème. Veuillez réessayer plus tard.';
	@override String get otpSubtitle => 'Pas de mot de passe — nous vous envoyons un code unique par email';
	@override String get enterEmailFirst => 'Saisissez d\'abord votre adresse email.';
	@override String get couldNotSendCode => 'Impossible d\'envoyer le code. Veuillez réessayer.';
	@override String get codeSentCheckInbox => 'Code envoyé par email — vérifiez votre boîte de réception.';
	@override String codeExpiresIn({required Object minutes}) => 'Le code expire dans ${minutes} minutes.';
	@override String get invalidOtpCode => 'Ce code n\'est pas valide. Vérifiez-le et réessayez.';
	@override String get resendCode => 'Renvoyer le code';
	@override String resendInSeconds({required Object seconds}) => 'Renvoyer dans ${seconds}s';
	@override String get backToPasswordSignIn => 'Retour à la connexion par mot de passe';
	@override String get loginFailed => 'Échec de la connexion. Vérifiez vos identifiants et réessayez.';
	@override String get verifyEmailTitle => 'Vérifiez votre email';
	@override String get verifyEmailSubtitle => 'Encore une étape';
	@override String get verificationLinkSentTo => 'Nous avons envoyé un lien de vérification à';
	@override String get verifyToOrderHint => 'Vous pouvez naviguer en attendant, mais vous devrez vérifier votre email avant de passer commande.';
	@override String get resendEmail => 'Renvoyer l\'email';
	@override String get verifyEmailSent => 'Email de vérification envoyé.';
	@override String get verifyEmailResendFailed => 'Impossible de renvoyer. Veuillez réessayer.';
	@override String get checkVerificationStatus => 'J\'ai vérifié — vérifier le statut';
	@override String get resetTokenLabel => 'Jeton de réinitialisation';
	@override String get resetTokenHint => 'Collez le jeton du lien reçu par email';
	@override String get invalidResetLink => 'Le lien de réinitialisation est invalide ou a expiré. Veuillez en demander un nouveau.';
	@override String get deliveryCodeEmailHint => 'Code envoyé par email — vérifiez votre boîte de réception.';
	@override String get confirmDeliveryTitle => 'Confirmez votre livraison';
	@override String get confirmDeliveryBody => 'Saisissez le code à 6 chiffres que votre livreur vous a communiqué pour confirmer la remise.';
	@override String get confirmationCode => 'Code de confirmation';
	@override String get confirmDeliveryAction => 'Confirmer la livraison';
	@override String get deliveryConfirmed => 'Livraison confirmée — merci !';
	@override String get confirmFailed => 'Impossible de confirmer — vérifiez le code et réessayez.';
	@override String get driverCreatedTitle => 'Livreur créé';
	@override String get shareTempPassword => 'Partagez ce mot de passe temporaire avec le livreur — il n\'est affiché qu\'une fois et sera réinitialisé à sa première connexion.';
	@override String get driverCreated => 'Compte livreur créé';
	@override String get couldNotCreateDriver => 'Impossible de créer le livreur. Réessayez.';
	@override String get agreeTerms => 'J\'accepte les Conditions d\'utilisation et la Politique de confidentialité';
	@override String get termsRequired => 'Veuillez accepter les conditions pour continuer.';
	@override String get termsOfService => 'Conditions d\'utilisation';
	@override String get privacyPolicy => 'Politique de confidentialité';
	@override String get identityDocsOptional => 'Ces documents sont facultatifs mais recommandés. Ils sont examinés avant la mise en ligne de votre ferme et peuvent être ajoutés plus tard depuis votre profil.';
	@override String get nationalIdOptional => 'Carte d\'identité nationale (facultatif)';
	@override String get selfieOptional => 'Selfie de vous ou de votre espace de vente (facultatif)';
	@override String get signUpFailed => 'Échec de l\'inscription. Veuillez réessayer.';
	@override String get markAllRead => 'Tout marquer comme lu';
	@override String get noNotifications => 'Aucune notification';
	@override String get allCaughtUp => 'Vous êtes à jour.';
	@override String get sellerRejectedTitle => 'Demande rejetée';
	@override String get sellerRejectedBody => 'Votre profil de ferme n\'a pas été approuvé. Veuillez mettre à jour vos documents d\'identité et le soumettre à nouveau.';
	@override String get reUploadNationalId => 'Ré-uploader la carte d\'identité';
	@override String get reUploadSelfie => 'Ré-uploader le selfie';
	@override String get documentsUpdated => 'Documents mis à jour. Votre profil sera examiné à nouveau.';
	@override String get uploadFailed => 'Échec de l\'upload. Veuillez réessayer.';
	@override String get report => 'Signaler';
	@override String get chatTitle => 'Discussion';
	@override String get chatThreadsTitle => 'Discussions';
	@override String get chatComposerHint => 'Message…';
	@override String get chatSend => 'Envoyer';
	@override String get chatSendFailed => 'Impossible d\'envoyer le message. Appuyez sur réessayer pour relancer.';
	@override String get chatAttachImage => 'Joindre une image';
	@override String get chatRecordVoice => 'Enregistrer un message vocal';
	@override String get chatStopVoice => 'Arrêter et envoyer le message vocal';
	@override String get chatVoiceWebUnavailable => 'Les messages vocaux ne sont pas encore disponibles sur le web.';
	@override String get chatMicPermission => 'La permission du microphone est requise pour les messages vocaux.';
	@override String get chatRecordFailed => 'Impossible de démarrer l\'enregistrement.';
	@override String get chatVoiceFinishFailed => 'Impossible de terminer le message vocal.';
	@override String get chatVoiceNote => 'Message vocal';
	@override String get chatNoMessages => 'Aucun message';
	@override String get chatNoMessagesHint => 'Dites bonjour pour commencer la conversation.';
	@override String get chatNoThreads => 'Aucune conversation';
	@override String get chatNoThreadsHint => 'Quand vous passez une commande, une discussion est créée avec le vendeur.';
	@override String get chatYou => 'Vous';
	@override String get chatImageGlyph => 'Photo';
	@override String get chatVoiceGlyph => 'Message vocal';
	@override String get chatToday => 'Aujourd\'hui';
	@override String get chatYesterday => 'Hier';
	@override String get chatTyping => 'écrit…';
	@override String get chatOrderContext => 'Contexte de la commande';
	@override String get chatNoThreadForOrder => 'Cette commande n\'a pas encore de discussion — les nouvelles commandes en créent une automatiquement au paiement.';
	@override String get orderStatusPending => 'En attente';
	@override String get orderStatusConfirmed => 'Confirmée';
	@override String get orderStatusShipped => 'En route';
	@override String get orderStatusDelivered => 'Livrée';
	@override String get orderStatusCancelled => 'Annulée';
	@override String get orderPlaced => 'Commande passée';
	@override String get orderPreparing => 'En préparation';
	@override String arrivingAt({required Object time}) => 'arrivée vers ${time}';
	@override String get gotIt => 'J\'ai reçu';
	@override String get driverArrivedTitle => 'Votre livreur est arrivé';
	@override String get driverArrivedBody => 'Confirmez que vous avez reçu votre commande.';
	@override String get gotItCodeHint => 'Saisissez le code à 6 chiffres envoyé par email.';
	@override String get items => 'Articles';
	@override String get subtotal => 'Sous-total';
	@override String get delivery => 'Livraison';
	@override String get total => 'Total';
	@override String get deliveryAddress => 'Adresse de livraison';
	@override String get chatWithSeller => 'Discuter avec le vendeur';
	@override String get orderDetails => 'Détails de la commande';
	@override String get viewReceipt => 'Voir le reçu';
	@override String get rateSeller => 'Évaluer le vendeur';
	@override String get cancelOrder => 'Annuler la commande';
	@override String get noOrdersYet => 'Aucune commande';
	@override String get noOrdersYetHint => 'Vos commandes apparaîtront ici après votre passage en caisse.';
	@override String get checkout => 'Validation';
	@override String get placeOrder => 'Passer la commande';
	@override String get nothingToCheckout => 'Rien à régler';
	@override String get emptyCart => 'Votre panier est vide.';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
		one: '1 article',
		other: '${count} articles',
	);
	@override String get sellerQueueTitle => 'Ce qui vous attend';
	@override String ordersToPrepare({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
		zero: 'Aucune commande à préparer',
		one: '${count} commande à préparer',
		other: '${count} commandes à préparer',
	);
	@override String awaitingPickup({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
		one: '${count} en attente de ramassage',
		other: '${count} en attente de ramassage',
	);
	@override String get awaitingPickupLabel => 'En attente de ramassage';
	@override String readyToWithdraw({required Object amount}) => '${amount} prêt à retirer';
	@override String get toPrepare => 'À préparer';
	@override String get prepared => 'Préparé';
	@override String get noQueueHint => 'Les nouvelles commandes payées apparaîtront ici.';
	@override String pickUpFrom({required Object seller}) => 'Ramassage : ${seller}';
	@override String dropOffAt({required Object address}) => 'Dépôt : ${address}';
	@override String distanceKm({required Object distance}) => '${distance} km';
	@override String get driverTaskStart => 'Commencer';
	@override String get driverTaskArrived => 'Arrivé';
	@override String get pickedUp => 'Ramassé';
	@override String get awaitingBuyerConfirm => 'En attente de confirmation de l\'acheteur';
	@override String get codeRequiredNote => 'L\'acheteur doit saisir un code à 6 chiffres pour terminer.';
	@override String get navQueue => 'File';
	@override String get chatWithBuyer => 'Discuter avec l\'acheteur';
	@override String get currentDelivery => 'Livraison en cours';
	@override String get dropOffUnknown => 'Adresse inconnue';
	@override String moreDeliveries({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
		one: '${count} autre livraison',
		other: '${count} autres livraisons',
	);
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'appTitle': return 'Trendy Green';
			case 'tagline': return 'Fresh produce, straight from the farm to you';
			case 'ok': return 'OK';
			case 'cancel': return 'Cancel';
			case 'save': return 'Save';
			case 'delete': return 'Delete';
			case 'edit': return 'Edit';
			case 'retry': return 'Try again';
			case 'search': return 'Search';
			case 'loading': return 'Loading…';
			case 'errorGeneric': return 'Something went wrong. Please try again.';
			case 'empty': return 'Nothing here yet';
			case 'back': return 'Back';
			case 'confirm': return 'Confirm';
			case 'continueLabel': return 'Continue';
			case 'done': return 'Done';
			case 'logout': return 'Log out';
			case 'navHome': return 'Home';
			case 'navSearch': return 'Search';
			case 'navCart': return 'Cart';
			case 'navOrders': return 'Orders';
			case 'navProfile': return 'Profile';
			case 'navDashboard': return 'Dashboard';
			case 'navProducts': return 'Products';
			case 'navDeliveries': return 'Deliveries';
			case 'navChat': return 'Chat';
			case 'navAdmin': return 'Admin';
			case 'navOverview': return 'Overview';
			case 'navSellers': return 'Sellers';
			case 'navWithdrawals': return 'Withdrawals';
			case 'navTickets': return 'Tickets';
			case 'navReports': return 'Reports';
			case 'navActivity': return 'Activity';
			case 'roleBuyer': return 'Buyer';
			case 'roleSeller': return 'Seller';
			case 'roleAdmin': return 'Admin';
			case 'roleDriver': return 'Delivery Driver';
			case 'welcomeBack': return 'Welcome back';
			case 'createAccount': return 'Create account';
			case 'signIn': return 'Sign in';
			case 'email': return 'Email';
			case 'password': return 'Password';
			case 'confirmPassword': return 'Confirm password';
			case 'forgotPassword': return 'Forgot password?';
			case 'firstName': return 'First name';
			case 'lastName': return 'Last name';
			case 'phone': return 'Phone';
			case 'region': return 'Region';
			case 'farmName': return 'Farm / business name';
			case 'mainCategory': return 'Main product category';
			case 'businessLicense': return 'Business license (optional)';
			case 'farmDescription': return 'Farm description';
			case 'nationalId': return 'National ID card';
			case 'selfie': return 'Selfie of you or your market space';
			case 'dontHaveAccount': return 'Don\'t have an account?';
			case 'alreadyHaveAccount': return 'Already have an account?';
			case 'createOne': return 'Create one';
			case 'loginWithCode': return 'Log in with a code instead';
			case 'sendCode': return 'Send code';
			case 'verifyAndLogin': return 'Verify & log in';
			case 'enterOtp': return 'Enter the 6-digit code';
			case 'pendingApproval': return 'Your seller profile is pending approval. You can browse the dashboard in the meantime.';
			case 'wallet': return 'Wallet';
			case 'balance': return 'Available balance';
			case 'escrow': return 'Escrow';
			case 'totalBalance': return 'Total';
			case 'withdraw': return 'Withdraw';
			case 'transactions': return 'Transaction history';
			case 'payNow': return 'Pay now';
			case 'mtnMomo': return 'MTN Mobile Money';
			case 'orangeMoney': return 'Orange Money';
			case 'giveCodeToDriver': return 'Give this code to your driver';
			case 'markDelivered': return 'Mark delivered';
			case 'confirmPickup': return 'Confirm pickup';
			case 'enterConfirmationCode': return 'Enter the delivery confirmation code';
			case 'quickActions': return 'Quick actions';
			case 'qaSearch': return 'Search products';
			case 'qaAddProduct': return 'Add product';
			case 'qaWallet': return 'My wallet';
			case 'qaOrders': return 'My orders';
			case 'qaTrackDelivery': return 'Track delivery';
			case 'qaSupport': return 'Help & support';
			case 'editProfile': return 'Edit profile';
			case 'language': return 'Language';
			case 'myOrders': return 'My orders';
			case 'myProducts': return 'My products';
			case 'wishlist': return 'Wishlist';
			case 'savedAddresses': return 'Saved addresses';
			case 'notifications': return 'Notifications';
			case 'support': return 'Help & support';
			case 'newProduct': return 'New product';
			case 'profileUpdated': return 'Profile updated';
			case 'saveFailed': return 'Could not save your profile. Try again.';
			case 'signUp': return 'Sign up';
			case 'profile': return 'Profile';
			case 'addProduct': return 'Add product';
			case 'noDeliveries': return 'No deliveries assigned';
			case 'deliveriesHint': return 'New deliveries will appear here once assigned to you.';
			case 'enRoute': return 'En route';
			case 'pickupPending': return 'Pickup pending';
			case 'deliveredStatus': return 'Delivered';
			case 'adminConsole': return 'Admin Console';
			case 'newDriver': return 'New driver';
			case 'statTotalUsers': return 'Total users';
			case 'statActiveSellers': return 'Active sellers';
			case 'statPendingSellers': return 'Pending sellers';
			case 'statGrossRevenue': return 'Gross revenue';
			case 'statCommission': return 'Commission earned';
			case 'statTotalOrders': return 'Total orders';
			case 'orderPrefix': return 'Order #';
			case 'navMore': return 'More';
			case 'addToCart': return 'Add to cart';
			case 'quantity': return 'Quantity';
			case 'addedToCart': return ({required Object name, required Object kg}) => '${name} added to cart (${kg} kg)';
			case 'errorNoConnection': return 'No internet connection. Check your connection and retry.';
			case 'errorTimeout': return 'The request timed out. Please try again.';
			case 'errorUnauthorized': return 'Your session has expired. Please sign in again.';
			case 'errorServer': return 'The server had a problem. Please try again later.';
			case 'otpSubtitle': return 'No password needed — we email you a one-time code';
			case 'enterEmailFirst': return 'Enter your email address first.';
			case 'couldNotSendCode': return 'Could not send the code. Please try again.';
			case 'codeSentCheckInbox': return 'Code sent to your email — check your inbox.';
			case 'codeExpiresIn': return ({required Object minutes}) => 'The code expires in ${minutes} minutes.';
			case 'invalidOtpCode': return 'That code is not valid. Check it and try again.';
			case 'resendCode': return 'Resend code';
			case 'resendInSeconds': return ({required Object seconds}) => 'Resend in ${seconds}s';
			case 'backToPasswordSignIn': return 'Back to password sign in';
			case 'loginFailed': return 'Login failed. Check your credentials and try again.';
			case 'verifyEmailTitle': return 'Verify your email';
			case 'verifyEmailSubtitle': return 'Almost there — one more step';
			case 'verificationLinkSentTo': return 'We sent a verification link to';
			case 'verifyToOrderHint': return 'You can browse while you wait, but you will need to verify before placing orders.';
			case 'resendEmail': return 'Resend email';
			case 'verifyEmailSent': return 'Verification email sent.';
			case 'verifyEmailResendFailed': return 'Could not resend. Please try again.';
			case 'checkVerificationStatus': return 'I\'ve verified — check status';
			case 'resetTokenLabel': return 'Reset token';
			case 'resetTokenHint': return 'Paste the link token from your email';
			case 'invalidResetLink': return 'The reset link is invalid or has expired. Please request a new one.';
			case 'deliveryCodeEmailHint': return 'Code sent to your email — check your inbox.';
			case 'confirmDeliveryTitle': return 'Confirm your delivery';
			case 'confirmDeliveryBody': return 'Enter the 6-digit code your driver shared with you to confirm the hand-off.';
			case 'confirmationCode': return 'Confirmation code';
			case 'confirmDeliveryAction': return 'Confirm delivery';
			case 'deliveryConfirmed': return 'Delivery confirmed — thank you!';
			case 'confirmFailed': return 'Could not confirm — check the code and try again.';
			case 'driverCreatedTitle': return 'Driver created';
			case 'shareTempPassword': return 'Share this temporary password with the driver — it is shown once and will be reset on their first login.';
			case 'driverCreated': return 'Driver account created';
			case 'couldNotCreateDriver': return 'Could not create the driver. Try again.';
			case 'agreeTerms': return 'I agree to the Terms of Service and Privacy Policy';
			case 'termsRequired': return 'Please accept the terms to continue.';
			case 'termsOfService': return 'Terms of Service';
			case 'privacyPolicy': return 'Privacy Policy';
			case 'identityDocsOptional': return 'These documents are optional but recommended. They are reviewed before your farm goes live and can be added later from your profile.';
			case 'nationalIdOptional': return 'National ID card (optional)';
			case 'selfieOptional': return 'Selfie of you or your market space (optional)';
			case 'signUpFailed': return 'Sign-up failed. Please try again.';
			case 'markAllRead': return 'Mark all read';
			case 'noNotifications': return 'No notifications';
			case 'allCaughtUp': return 'You are all caught up.';
			case 'sellerRejectedTitle': return 'Application rejected';
			case 'sellerRejectedBody': return 'Your farm profile was not approved. Please update your identity documents and re-submit.';
			case 'reUploadNationalId': return 'Re-upload National ID';
			case 'reUploadSelfie': return 'Re-upload selfie';
			case 'documentsUpdated': return 'Documents updated. Your profile will be reviewed again.';
			case 'uploadFailed': return 'Upload failed. Please try again.';
			case 'report': return 'Report';
			case 'chatTitle': return 'Chat';
			case 'chatThreadsTitle': return 'Chats';
			case 'chatComposerHint': return 'Message…';
			case 'chatSend': return 'Send';
			case 'chatSendFailed': return 'Could not send the message. Tap retry to try again.';
			case 'chatAttachImage': return 'Attach image';
			case 'chatRecordVoice': return 'Record voice note';
			case 'chatStopVoice': return 'Stop & send voice note';
			case 'chatVoiceWebUnavailable': return 'Voice notes are not available on the web yet.';
			case 'chatMicPermission': return 'Microphone permission is required for voice notes.';
			case 'chatRecordFailed': return 'Could not start recording.';
			case 'chatVoiceFinishFailed': return 'Could not finish the voice note.';
			case 'chatVoiceNote': return 'Voice note';
			case 'chatNoMessages': return 'No messages yet';
			case 'chatNoMessagesHint': return 'Say hello to start the conversation.';
			case 'chatNoThreads': return 'No conversations yet';
			case 'chatNoThreadsHint': return 'When you place an order, a chat thread is created with the seller.';
			case 'chatYou': return 'You';
			case 'chatImageGlyph': return 'Photo';
			case 'chatVoiceGlyph': return 'Voice note';
			case 'chatToday': return 'Today';
			case 'chatYesterday': return 'Yesterday';
			case 'chatTyping': return 'typing…';
			case 'chatOrderContext': return 'Order context';
			case 'chatNoThreadForOrder': return 'This order has no chat thread yet — new orders automatically get one at checkout.';
			case 'orderStatusPending': return 'Pending';
			case 'orderStatusConfirmed': return 'Confirmed';
			case 'orderStatusShipped': return 'On the way';
			case 'orderStatusDelivered': return 'Delivered';
			case 'orderStatusCancelled': return 'Cancelled';
			case 'orderPlaced': return 'Order placed';
			case 'orderPreparing': return 'Preparing';
			case 'arrivingAt': return ({required Object time}) => 'arriving ~${time}';
			case 'gotIt': return 'Got it';
			case 'driverArrivedTitle': return 'Your driver is here';
			case 'driverArrivedBody': return 'Confirm that you received your order.';
			case 'gotItCodeHint': return 'Enter the 6-digit code sent to your email.';
			case 'items': return 'Items';
			case 'subtotal': return 'Subtotal';
			case 'delivery': return 'Delivery';
			case 'total': return 'Total';
			case 'deliveryAddress': return 'Delivery address';
			case 'chatWithSeller': return 'Chat with seller';
			case 'orderDetails': return 'Order details';
			case 'viewReceipt': return 'View receipt';
			case 'rateSeller': return 'Rate seller';
			case 'cancelOrder': return 'Cancel order';
			case 'noOrdersYet': return 'No orders yet';
			case 'noOrdersYetHint': return 'Your orders will appear here once you check out.';
			case 'checkout': return 'Checkout';
			case 'placeOrder': return 'Place order';
			case 'nothingToCheckout': return 'Nothing to checkout';
			case 'emptyCart': return 'Your cart is empty.';
			case 'itemCount': return ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
				one: '1 item',
				other: '${count} items',
			);
			case 'sellerQueueTitle': return 'What needs you';
			case 'ordersToPrepare': return ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
				zero: 'No orders to prepare',
				one: '${count} order to prepare',
				other: '${count} orders to prepare',
			);
			case 'awaitingPickup': return ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
				one: '${count} awaiting pickup',
				other: '${count} awaiting pickup',
			);
			case 'awaitingPickupLabel': return 'Awaiting pickup';
			case 'readyToWithdraw': return ({required Object amount}) => '${amount} ready to withdraw';
			case 'toPrepare': return 'To prepare';
			case 'prepared': return 'Prepared';
			case 'noQueueHint': return 'New paid orders will appear here.';
			case 'pickUpFrom': return ({required Object seller}) => 'Pick up: ${seller}';
			case 'dropOffAt': return ({required Object address}) => 'Drop off: ${address}';
			case 'distanceKm': return ({required Object distance}) => '${distance} km';
			case 'driverTaskStart': return 'Start';
			case 'driverTaskArrived': return 'Arrived';
			case 'pickedUp': return 'Picked up';
			case 'awaitingBuyerConfirm': return 'Awaiting the buyer to confirm';
			case 'codeRequiredNote': return 'The buyer must enter a 6-digit code to complete.';
			case 'navQueue': return 'Queue';
			case 'chatWithBuyer': return 'Chat with buyer';
			case 'currentDelivery': return 'Current delivery';
			case 'dropOffUnknown': return 'Unknown address';
			case 'moreDeliveries': return ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
				one: '${count} more delivery',
				other: '${count} more deliveries',
			);
			default: return null;
		}
	}
}

extension on _StringsFr {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'appTitle': return 'Trendy Green';
			case 'tagline': return 'Produits frais, directement de la ferme à votre table';
			case 'ok': return 'OK';
			case 'cancel': return 'Annuler';
			case 'save': return 'Enregistrer';
			case 'delete': return 'Supprimer';
			case 'edit': return 'Modifier';
			case 'retry': return 'Réessayer';
			case 'search': return 'Rechercher';
			case 'loading': return 'Chargement…';
			case 'errorGeneric': return 'Une erreur est survenue. Veuillez réessayer.';
			case 'empty': return 'Rien ici pour le moment';
			case 'back': return 'Retour';
			case 'confirm': return 'Confirmer';
			case 'continueLabel': return 'Continuer';
			case 'done': return 'Terminé';
			case 'logout': return 'Se déconnecter';
			case 'navHome': return 'Accueil';
			case 'navSearch': return 'Recherche';
			case 'navCart': return 'Panier';
			case 'navOrders': return 'Commandes';
			case 'navProfile': return 'Profil';
			case 'navDashboard': return 'Tableau de bord';
			case 'navProducts': return 'Produits';
			case 'navDeliveries': return 'Livraisons';
			case 'navChat': return 'Discussions';
			case 'navAdmin': return 'Admin';
			case 'navOverview': return 'Aperçu';
			case 'navSellers': return 'Vendeurs';
			case 'navWithdrawals': return 'Retraits';
			case 'navTickets': return 'Tickets';
			case 'navReports': return 'Signalements';
			case 'navActivity': return 'Activité';
			case 'roleBuyer': return 'Acheteur';
			case 'roleSeller': return 'Vendeur';
			case 'roleAdmin': return 'Administrateur';
			case 'roleDriver': return 'Livreur';
			case 'welcomeBack': return 'Bon retour';
			case 'createAccount': return 'Créer un compte';
			case 'signIn': return 'Se connecter';
			case 'email': return 'Email';
			case 'password': return 'Mot de passe';
			case 'confirmPassword': return 'Confirmer le mot de passe';
			case 'forgotPassword': return 'Mot de passe oublié ?';
			case 'firstName': return 'Prénom';
			case 'lastName': return 'Nom';
			case 'phone': return 'Téléphone';
			case 'region': return 'Région';
			case 'farmName': return 'Nom de la ferme / entreprise';
			case 'mainCategory': return 'Catégorie principale';
			case 'businessLicense': return 'Licence commerciale (optionnel)';
			case 'farmDescription': return 'Description de la ferme';
			case 'nationalId': return 'Carte d\'identité nationale';
			case 'selfie': return 'Selfie de vous ou de votre espace de vente';
			case 'dontHaveAccount': return 'Vous n\'avez pas de compte ?';
			case 'alreadyHaveAccount': return 'Vous avez déjà un compte ?';
			case 'createOne': return 'En créer un';
			case 'loginWithCode': return 'Se connecter avec un code à la place';
			case 'sendCode': return 'Envoyer le code';
			case 'verifyAndLogin': return 'Vérifier et se connecter';
			case 'enterOtp': return 'Saisissez le code à 6 chiffres';
			case 'pendingApproval': return 'Votre profil vendeur est en attente d\'approbation. Vous pouvez consulter le tableau de bord en attendant.';
			case 'wallet': return 'Portefeuille';
			case 'balance': return 'Solde disponible';
			case 'escrow': return 'Séquestre';
			case 'totalBalance': return 'Total';
			case 'withdraw': return 'Retirer';
			case 'transactions': return 'Historique des transactions';
			case 'payNow': return 'Payer maintenant';
			case 'mtnMomo': return 'MTN Mobile Money';
			case 'orangeMoney': return 'Orange Money';
			case 'giveCodeToDriver': return 'Donnez ce code à votre livreur';
			case 'markDelivered': return 'Marquer livré';
			case 'confirmPickup': return 'Confirmer le ramassage';
			case 'enterConfirmationCode': return 'Saisissez le code de confirmation de livraison';
			case 'quickActions': return 'Actions rapides';
			case 'qaSearch': return 'Rechercher des produits';
			case 'qaAddProduct': return 'Ajouter un produit';
			case 'qaWallet': return 'Mon portefeuille';
			case 'qaOrders': return 'Mes commandes';
			case 'qaTrackDelivery': return 'Suivre une livraison';
			case 'qaSupport': return 'Aide & support';
			case 'editProfile': return 'Modifier le profil';
			case 'language': return 'Langue';
			case 'myOrders': return 'Mes commandes';
			case 'myProducts': return 'Mes produits';
			case 'wishlist': return 'Liste de souhaits';
			case 'savedAddresses': return 'Adresses enregistrées';
			case 'notifications': return 'Notifications';
			case 'support': return 'Aide & support';
			case 'newProduct': return 'Nouveau produit';
			case 'profileUpdated': return 'Profil mis à jour';
			case 'saveFailed': return 'Impossible d\'enregistrer votre profil. Réessayez.';
			case 'signUp': return 'S\'inscrire';
			case 'profile': return 'Profil';
			case 'addProduct': return 'Ajouter un produit';
			case 'noDeliveries': return 'Aucune livraison assignée';
			case 'deliveriesHint': return 'Les nouvelles livraisons apparaîtront ici une fois assignées à vous.';
			case 'enRoute': return 'En route';
			case 'pickupPending': return 'Ramassage en attente';
			case 'deliveredStatus': return 'Livrée';
			case 'adminConsole': return 'Console Admin';
			case 'newDriver': return 'Nouveau livreur';
			case 'statTotalUsers': return 'Total utilisateurs';
			case 'statActiveSellers': return 'Vendeurs actifs';
			case 'statPendingSellers': return 'Vendeurs en attente';
			case 'statGrossRevenue': return 'Revenu brut';
			case 'statCommission': return 'Commission perçue';
			case 'statTotalOrders': return 'Total commandes';
			case 'orderPrefix': return 'Commande #';
			case 'navMore': return 'Plus';
			case 'addToCart': return 'Ajouter au panier';
			case 'quantity': return 'Quantité';
			case 'addedToCart': return ({required Object name, required Object kg}) => '${name} ajouté au panier (${kg} kg)';
			case 'errorNoConnection': return 'Pas de connexion internet. Vérifiez votre connexion et réessayez.';
			case 'errorTimeout': return 'Le délai de la requête est dépassé. Veuillez réessayer.';
			case 'errorUnauthorized': return 'Votre session a expiré. Veuillez vous reconnecter.';
			case 'errorServer': return 'Le serveur a rencontré un problème. Veuillez réessayer plus tard.';
			case 'otpSubtitle': return 'Pas de mot de passe — nous vous envoyons un code unique par email';
			case 'enterEmailFirst': return 'Saisissez d\'abord votre adresse email.';
			case 'couldNotSendCode': return 'Impossible d\'envoyer le code. Veuillez réessayer.';
			case 'codeSentCheckInbox': return 'Code envoyé par email — vérifiez votre boîte de réception.';
			case 'codeExpiresIn': return ({required Object minutes}) => 'Le code expire dans ${minutes} minutes.';
			case 'invalidOtpCode': return 'Ce code n\'est pas valide. Vérifiez-le et réessayez.';
			case 'resendCode': return 'Renvoyer le code';
			case 'resendInSeconds': return ({required Object seconds}) => 'Renvoyer dans ${seconds}s';
			case 'backToPasswordSignIn': return 'Retour à la connexion par mot de passe';
			case 'loginFailed': return 'Échec de la connexion. Vérifiez vos identifiants et réessayez.';
			case 'verifyEmailTitle': return 'Vérifiez votre email';
			case 'verifyEmailSubtitle': return 'Encore une étape';
			case 'verificationLinkSentTo': return 'Nous avons envoyé un lien de vérification à';
			case 'verifyToOrderHint': return 'Vous pouvez naviguer en attendant, mais vous devrez vérifier votre email avant de passer commande.';
			case 'resendEmail': return 'Renvoyer l\'email';
			case 'verifyEmailSent': return 'Email de vérification envoyé.';
			case 'verifyEmailResendFailed': return 'Impossible de renvoyer. Veuillez réessayer.';
			case 'checkVerificationStatus': return 'J\'ai vérifié — vérifier le statut';
			case 'resetTokenLabel': return 'Jeton de réinitialisation';
			case 'resetTokenHint': return 'Collez le jeton du lien reçu par email';
			case 'invalidResetLink': return 'Le lien de réinitialisation est invalide ou a expiré. Veuillez en demander un nouveau.';
			case 'deliveryCodeEmailHint': return 'Code envoyé par email — vérifiez votre boîte de réception.';
			case 'confirmDeliveryTitle': return 'Confirmez votre livraison';
			case 'confirmDeliveryBody': return 'Saisissez le code à 6 chiffres que votre livreur vous a communiqué pour confirmer la remise.';
			case 'confirmationCode': return 'Code de confirmation';
			case 'confirmDeliveryAction': return 'Confirmer la livraison';
			case 'deliveryConfirmed': return 'Livraison confirmée — merci !';
			case 'confirmFailed': return 'Impossible de confirmer — vérifiez le code et réessayez.';
			case 'driverCreatedTitle': return 'Livreur créé';
			case 'shareTempPassword': return 'Partagez ce mot de passe temporaire avec le livreur — il n\'est affiché qu\'une fois et sera réinitialisé à sa première connexion.';
			case 'driverCreated': return 'Compte livreur créé';
			case 'couldNotCreateDriver': return 'Impossible de créer le livreur. Réessayez.';
			case 'agreeTerms': return 'J\'accepte les Conditions d\'utilisation et la Politique de confidentialité';
			case 'termsRequired': return 'Veuillez accepter les conditions pour continuer.';
			case 'termsOfService': return 'Conditions d\'utilisation';
			case 'privacyPolicy': return 'Politique de confidentialité';
			case 'identityDocsOptional': return 'Ces documents sont facultatifs mais recommandés. Ils sont examinés avant la mise en ligne de votre ferme et peuvent être ajoutés plus tard depuis votre profil.';
			case 'nationalIdOptional': return 'Carte d\'identité nationale (facultatif)';
			case 'selfieOptional': return 'Selfie de vous ou de votre espace de vente (facultatif)';
			case 'signUpFailed': return 'Échec de l\'inscription. Veuillez réessayer.';
			case 'markAllRead': return 'Tout marquer comme lu';
			case 'noNotifications': return 'Aucune notification';
			case 'allCaughtUp': return 'Vous êtes à jour.';
			case 'sellerRejectedTitle': return 'Demande rejetée';
			case 'sellerRejectedBody': return 'Votre profil de ferme n\'a pas été approuvé. Veuillez mettre à jour vos documents d\'identité et le soumettre à nouveau.';
			case 'reUploadNationalId': return 'Ré-uploader la carte d\'identité';
			case 'reUploadSelfie': return 'Ré-uploader le selfie';
			case 'documentsUpdated': return 'Documents mis à jour. Votre profil sera examiné à nouveau.';
			case 'uploadFailed': return 'Échec de l\'upload. Veuillez réessayer.';
			case 'report': return 'Signaler';
			case 'chatTitle': return 'Discussion';
			case 'chatThreadsTitle': return 'Discussions';
			case 'chatComposerHint': return 'Message…';
			case 'chatSend': return 'Envoyer';
			case 'chatSendFailed': return 'Impossible d\'envoyer le message. Appuyez sur réessayer pour relancer.';
			case 'chatAttachImage': return 'Joindre une image';
			case 'chatRecordVoice': return 'Enregistrer un message vocal';
			case 'chatStopVoice': return 'Arrêter et envoyer le message vocal';
			case 'chatVoiceWebUnavailable': return 'Les messages vocaux ne sont pas encore disponibles sur le web.';
			case 'chatMicPermission': return 'La permission du microphone est requise pour les messages vocaux.';
			case 'chatRecordFailed': return 'Impossible de démarrer l\'enregistrement.';
			case 'chatVoiceFinishFailed': return 'Impossible de terminer le message vocal.';
			case 'chatVoiceNote': return 'Message vocal';
			case 'chatNoMessages': return 'Aucun message';
			case 'chatNoMessagesHint': return 'Dites bonjour pour commencer la conversation.';
			case 'chatNoThreads': return 'Aucune conversation';
			case 'chatNoThreadsHint': return 'Quand vous passez une commande, une discussion est créée avec le vendeur.';
			case 'chatYou': return 'Vous';
			case 'chatImageGlyph': return 'Photo';
			case 'chatVoiceGlyph': return 'Message vocal';
			case 'chatToday': return 'Aujourd\'hui';
			case 'chatYesterday': return 'Hier';
			case 'chatTyping': return 'écrit…';
			case 'chatOrderContext': return 'Contexte de la commande';
			case 'chatNoThreadForOrder': return 'Cette commande n\'a pas encore de discussion — les nouvelles commandes en créent une automatiquement au paiement.';
			case 'orderStatusPending': return 'En attente';
			case 'orderStatusConfirmed': return 'Confirmée';
			case 'orderStatusShipped': return 'En route';
			case 'orderStatusDelivered': return 'Livrée';
			case 'orderStatusCancelled': return 'Annulée';
			case 'orderPlaced': return 'Commande passée';
			case 'orderPreparing': return 'En préparation';
			case 'arrivingAt': return ({required Object time}) => 'arrivée vers ${time}';
			case 'gotIt': return 'J\'ai reçu';
			case 'driverArrivedTitle': return 'Votre livreur est arrivé';
			case 'driverArrivedBody': return 'Confirmez que vous avez reçu votre commande.';
			case 'gotItCodeHint': return 'Saisissez le code à 6 chiffres envoyé par email.';
			case 'items': return 'Articles';
			case 'subtotal': return 'Sous-total';
			case 'delivery': return 'Livraison';
			case 'total': return 'Total';
			case 'deliveryAddress': return 'Adresse de livraison';
			case 'chatWithSeller': return 'Discuter avec le vendeur';
			case 'orderDetails': return 'Détails de la commande';
			case 'viewReceipt': return 'Voir le reçu';
			case 'rateSeller': return 'Évaluer le vendeur';
			case 'cancelOrder': return 'Annuler la commande';
			case 'noOrdersYet': return 'Aucune commande';
			case 'noOrdersYetHint': return 'Vos commandes apparaîtront ici après votre passage en caisse.';
			case 'checkout': return 'Validation';
			case 'placeOrder': return 'Passer la commande';
			case 'nothingToCheckout': return 'Rien à régler';
			case 'emptyCart': return 'Votre panier est vide.';
			case 'itemCount': return ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
				one: '1 article',
				other: '${count} articles',
			);
			case 'sellerQueueTitle': return 'Ce qui vous attend';
			case 'ordersToPrepare': return ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
				zero: 'Aucune commande à préparer',
				one: '${count} commande à préparer',
				other: '${count} commandes à préparer',
			);
			case 'awaitingPickup': return ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
				one: '${count} en attente de ramassage',
				other: '${count} en attente de ramassage',
			);
			case 'awaitingPickupLabel': return 'En attente de ramassage';
			case 'readyToWithdraw': return ({required Object amount}) => '${amount} prêt à retirer';
			case 'toPrepare': return 'À préparer';
			case 'prepared': return 'Préparé';
			case 'noQueueHint': return 'Les nouvelles commandes payées apparaîtront ici.';
			case 'pickUpFrom': return ({required Object seller}) => 'Ramassage : ${seller}';
			case 'dropOffAt': return ({required Object address}) => 'Dépôt : ${address}';
			case 'distanceKm': return ({required Object distance}) => '${distance} km';
			case 'driverTaskStart': return 'Commencer';
			case 'driverTaskArrived': return 'Arrivé';
			case 'pickedUp': return 'Ramassé';
			case 'awaitingBuyerConfirm': return 'En attente de confirmation de l\'acheteur';
			case 'codeRequiredNote': return 'L\'acheteur doit saisir un code à 6 chiffres pour terminer.';
			case 'navQueue': return 'File';
			case 'chatWithBuyer': return 'Discuter avec l\'acheteur';
			case 'currentDelivery': return 'Livraison en cours';
			case 'dropOffUnknown': return 'Adresse inconnue';
			case 'moreDeliveries': return ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
				one: '${count} autre livraison',
				other: '${count} autres livraisons',
			);
			default: return null;
		}
	}
}
