import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:green/core/storage/token_storage.dart';
import 'package:green/data/models/auth.dart';
import 'package:green/data/models/enums.dart';
import 'package:green/data/models/user.dart';
import 'package:green/data/repositories/auth_repository.dart';
import 'package:green/data/repositories/providers.dart';
import 'package:green/features/auth/controllers/auth_controller.dart';

import '../helpers/test_token_storage.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const demoUser = User(
    id: 'u-1',
    firstName: 'Marie',
    lastName: 'Ngon',
    email: 'buyer@greenish.cm',
    role: UserRole.buyer,
    emailVerified: true,
  );
  const demoSession = AuthSession(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    user: demoUser,
  );

  late MockAuthRepository repo;
  late InMemoryTokenStorage storage;
  late ProviderContainer container;

  ProviderContainer makeContainer() {
    repo = MockAuthRepository();
    storage = InMemoryTokenStorage();
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('starts unauthenticated when no token is stored', () async {
    container = makeContainer();
    final state = await container.read(authControllerProvider.future);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.user, isNull);
  });

  test('login persists the session and authenticates', () async {
    container = makeContainer();
    when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => demoSession);

    await container.read(authControllerProvider.notifier).login(email: ' buyer@greenish.cm ', password: 'x');

    final state = container.read(authControllerProvider).requireValue;
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.email, 'buyer@greenish.cm');
    expect(await storage.readAccessToken(), 'access-token');
    expect(await storage.readRefreshToken(), 'refresh-token');
  });

  test('restoreSession rehydrates a persisted session', () async {
    container = makeContainer();
    await storage.saveSession(demoSession);
    when(() => repo.restoreSession(any())).thenAnswer((_) async => demoSession);

    final state = await container.read(authControllerProvider.future);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.fullName, 'Marie Ngon');
  });

  test('logout clears local session and returns to unauthenticated', () async {
    container = makeContainer();
    await storage.saveSession(demoSession);
    when(() => repo.restoreSession(any())).thenAnswer((_) async => demoSession);
    when(() => repo.logout(any())).thenAnswer((_) async {});

    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(authControllerProvider).requireValue.status, AuthStatus.unauthenticated);
    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });

  test('login failure surfaces to the caller and keeps state', () async {
    container = makeContainer();
    when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenThrow(Exception('bad credentials'));

    // Let the initial session-restore build settle before acting on the state.
    await container.read(authControllerProvider.future);
    await expectLater(
      container.read(authControllerProvider.notifier).login(email: 'x', password: 'y'),
      throwsA(isA<Exception>()),
    );
    expect(container.read(authControllerProvider).requireValue.status, AuthStatus.unauthenticated);
  });
}
