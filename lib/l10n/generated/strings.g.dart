/// Generated file. Do not edit.
///
/// Original: lib/l10n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 228 (114 per locale)
///
/// Built on 2026-08-08 at 13:59 UTC

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
			default: return null;
		}
	}
}
